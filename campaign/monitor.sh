#!/bin/bash
# monitor.sh -- Live status dashboard for a Poly/ML fuzzing campaign
#
# Usage:
#   ./campaign/monitor.sh <campaign-name>
#   watch -n 30 ./campaign/monitor.sh <campaign-name>   # auto-refresh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="${PROJECT_ROOT}/results"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

CAMPAIGN_NAME="${1:-}"

if [[ -z "$CAMPAIGN_NAME" ]]; then
    echo -e "${YELLOW}Available campaigns:${NC}"
    ls -1 "$RESULTS_DIR" | grep -v "early-findings" || echo "  (none)"
    echo ""
    echo -e "${YELLOW}Usage: $0 <campaign-name>${NC}"
    exit 1
fi

CAMPAIGN_DIR="${RESULTS_DIR}/${CAMPAIGN_NAME}"
if [[ ! -d "$CAMPAIGN_DIR" ]]; then
    echo -e "${RED}[!] Campaign not found: $CAMPAIGN_NAME${NC}"; exit 1
fi

# Running status
RUNNING_FUZZERS=$(pgrep -f "afl-fuzz.*${CAMPAIGN_NAME}" 2>/dev/null | wc -l | tr -d ' ' || echo 0)

echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Poly/ML Fuzzing Campaign Monitor          |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${BLUE}Campaign:${NC} $CAMPAIGN_NAME"
echo -n "Status:   "
if [[ "$RUNNING_FUZZERS" -gt 0 ]]; then
    echo -e "${GREEN}${RUNNING_FUZZERS} fuzzer(s) running${NC}"
else
    echo -e "${YELLOW}Stopped (no active fuzzers)${NC}"
fi

# Show elapsed time from metadata
META_FILE="${CAMPAIGN_DIR}/campaign.meta"
if [[ -f "$META_FILE" ]]; then
    source "$META_FILE"
    if [[ -n "${start_time:-}" ]]; then
        ELAPSED=$(( $(date +%s) - start_time ))
        echo -e "Elapsed:  $(( ELAPSED / 3600 ))h $(( (ELAPSED % 3600) / 60 ))m"
        if [[ -n "${duration:-}" && "${duration:-0}" -gt 0 ]]; then
            REMAINING=$(( duration - ELAPSED ))
            if [[ "$REMAINING" -gt 0 ]]; then
                echo -e "Remaining: $(( REMAINING / 3600 ))h $(( (REMAINING % 3600) / 60 ))m"
            else
                echo -e "Remaining: ${YELLOW}duration exceeded${NC}"
            fi
        fi
    fi
fi
echo ""

# AFL++ whatsup (detailed stats)
if command -v afl-whatsup &> /dev/null; then
    echo -e "${BLUE}=== AFL++ Status ===${NC}"
    afl-whatsup -s "$CAMPAIGN_DIR" 2>/dev/null || true
    echo ""
fi

# Coverage / edges
echo -e "${BLUE}=== Coverage ===${NC}"

MAX_EDGES=0
for fuzzer_dir in "${CAMPAIGN_DIR}"/fuzzer*/; do
    [[ ! -d "$fuzzer_dir" ]] && continue
    plot_file="${fuzzer_dir}plot_data"
    if [[ -f "$plot_file" ]]; then
        last=$(grep -v '^#' "$plot_file" | grep -v '^$' | tail -1)
        if [[ -n "$last" ]]; then
            ncols=$(echo "$last" | awk -F',' '{print NF}')
            if [[ "$ncols" -ge 13 ]]; then
                edges=$(echo "$last" | cut -d',' -f13 | tr -d ' ')
            else
                # Older AFL++: use map_size (column 7) as approximation
                edges=$(echo "$last" | cut -d',' -f7 | tr -d ' ')
            fi
            [[ "${edges:-0}" -gt "$MAX_EDGES" ]] && MAX_EDGES="${edges:-0}"
        fi
    fi
done

echo -e "Edges found: ${GREEN}${MAX_EDGES}${NC}"

# Show edges/hour from analytics CSV if available
EDGES_CSV="${CAMPAIGN_DIR}/analytics/edges_over_time.csv"
if [[ -f "$EDGES_CSV" ]] && [[ $(wc -l < "$EDGES_CSV") -gt 2 ]]; then
    # Get last two rows and compute delta
    PREV_EDGES=$(tail -n 2 "$EDGES_CSV" | head -1 | cut -d',' -f3 | tr -d ' ')
    LAST_EDGES=$(tail -1 "$EDGES_CSV" | cut -d',' -f3 | tr -d ' ')
    DELTA=$(( ${LAST_EDGES:-0} - ${PREV_EDGES:-0} ))

    if [[ "$DELTA" -ge 10 ]]; then
        echo -e "Last delta:  ${GREEN}+${DELTA} edges${NC}"
    elif [[ "$DELTA" -gt 0 ]]; then
        echo -e "Last delta:  ${YELLOW}+${DELTA} edges (low -- possible saturation)${NC}"
    else
        echo -e "Last delta:  ${RED}+0 edges (saturated?)${NC}"
    fi

    # Check saturation log
    SAT_LOG="${CAMPAIGN_DIR}/analytics/saturation.log"
    if [[ -f "$SAT_LOG" ]] && [[ -s "$SAT_LOG" ]]; then
        echo -e "Saturation:  ${RED}DETECTED -- see analytics/saturation.log${NC}"
    else
        echo -e "Saturation:  ${GREEN}Not yet detected${NC}"
    fi
fi
echo ""

# Findings
echo -e "${BLUE}=== Findings ===${NC}"
CRASH_COUNT=0; HANG_COUNT=0
for fuzzer_dir in "${CAMPAIGN_DIR}"/fuzzer*/; do
    crashes="${fuzzer_dir}crashes"
    hangs="${fuzzer_dir}hangs"
    [[ -d "$crashes" ]] && CRASH_COUNT=$(( CRASH_COUNT + $(find "$crashes" -type f ! -name "README.txt" | wc -l | tr -d ' ') ))
    [[ -d "$hangs" ]]   && HANG_COUNT=$((  HANG_COUNT  + $(find "$hangs"   -type f ! -name "README.txt" | wc -l | tr -d ' ') ))
done

if [[ "$CRASH_COUNT" -gt 0 ]]; then
    echo -e "Crashes: ${RED}${CRASH_COUNT}${NC}"
else
    echo -e "Crashes: 0"
fi
if [[ "$HANG_COUNT" -gt 0 ]]; then
    echo -e "Hangs:   ${YELLOW}${HANG_COUNT}${NC}"
else
    echo -e "Hangs:   0"
fi
echo ""

# Health check
echo -e "${BLUE}=== Fuzzer Health ===${NC}"
STALLED=0
for fuzzer_dir in "${CAMPAIGN_DIR}"/fuzzer*/; do
    [[ ! -d "$fuzzer_dir" ]] && continue
    FUZZER_NAME=$(basename "$fuzzer_dir")
    PLOT_DATA="${fuzzer_dir}plot_data"

    if [[ -f "$PLOT_DATA" ]]; then
        LAST_UPDATE=$(stat -f %m "$PLOT_DATA" 2>/dev/null || stat -c %Y "$PLOT_DATA" 2>/dev/null || echo 0)
        AGE=$(( $(date +%s) - LAST_UPDATE ))

        if [[ "$AGE" -gt 600 ]]; then
            echo -e "${YELLOW}[!] $FUZZER_NAME: No activity for $(( AGE / 60 )) minutes${NC}"
            (( STALLED++ )) || true
        else
            echo -e "${GREEN}[ok] $FUZZER_NAME: Active (last update $(( AGE / 60 ))m ago)${NC}"
        fi
    fi
done
[[ "$STALLED" -eq 0 && "$RUNNING_FUZZERS" -gt 0 ]] && echo -e "${GREEN}All fuzzers active${NC}"
echo ""

# Quick actions
echo -e "${BLUE}=== Quick Actions ===${NC}"
echo -e "  Track saturation:  ./campaign/analytics.sh $CAMPAIGN_NAME"
echo -e "  Collect crashes:   ./campaign/collect-crashes.sh $CAMPAIGN_NAME"
echo -e "  Triage crashes:    ./campaign/triage.sh $CAMPAIGN_NAME"
echo -e "  Full report:       ./campaign/report.sh $CAMPAIGN_NAME"
echo -e "  Stop campaign:     pkill afl-fuzz"
