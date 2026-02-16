#!/bin/bash
# analytics.sh -- Track coverage saturation during a fuzzing campaign
#
# Reads AFL++ plot_data files every hour and logs:
#   - Edges discovered (bitmap coverage)
#   - Delta edges per hour (saturation indicator)
#   - Total executions and execution speed
#   - Unique crashes found
#
# Saturation heuristic: if new edges per hour drops below SATURATION_THRESHOLD
# for SATURATION_WINDOW consecutive hours, the campaign is considered saturated.
#
# Usage:
#   ./campaign/analytics.sh <campaign-name> [--interval SECONDS]
#
# Output files (in results/<campaign>/analytics/):
#   edges_over_time.csv   -- timestamped edge counts (for plotting)
#   saturation.log        -- saturation detection events
#   summary.txt           -- latest snapshot of all metrics

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="${PROJECT_ROOT}/results"

# Colours
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Configuration
SATURATION_THRESHOLD=10   # Edges/hour below this -> saturated
SATURATION_WINDOW=3       # Consecutive periods below threshold -> declare saturation
INTERVAL=3600             # Default: sample every 1 hour (3600 seconds)

# Argument parsing
CAMPAIGN_NAME="${1:-}"
shift || true

while [[ $# -gt 0 ]]; do
    case "$1" in
        --interval) INTERVAL="$2"; shift 2 ;;
        *) echo -e "${RED}[!] Unknown argument: $1${NC}"; exit 1 ;;
    esac
done

if [[ -z "$CAMPAIGN_NAME" ]]; then
    echo -e "${RED}Usage: $0 <campaign-name> [--interval SECONDS]${NC}"
    echo -e "  Default interval: 3600 seconds (1 hour)"
    exit 1
fi

CAMPAIGN_DIR="${RESULTS_DIR}/${CAMPAIGN_NAME}"
ANALYTICS_DIR="${CAMPAIGN_DIR}/analytics"

if [[ ! -d "$CAMPAIGN_DIR" ]]; then
    echo -e "${RED}[!] Campaign not found: $CAMPAIGN_DIR${NC}"; exit 1
fi

mkdir -p "$ANALYTICS_DIR"

# Output files
EDGES_CSV="${ANALYTICS_DIR}/edges_over_time.csv"
SATURATION_LOG="${ANALYTICS_DIR}/saturation.log"
SUMMARY_FILE="${ANALYTICS_DIR}/summary.txt"

# Write CSV header if new file
if [[ ! -f "$EDGES_CSV" ]]; then
    echo "timestamp,unix_time,edges_found,delta_edges,total_execs,execs_per_sec,unique_crashes,unique_hangs" \
        > "$EDGES_CSV"
fi

# Helper: parse plot_data for a single fuzzer
# AFL++ plot_data format (columns may vary by version):
#   unix_time, cycles_done, cur_item, corpus_count, pending_total, pending_favs,
#   map_size, saved_crashes, saved_hangs, max_depth, execs_per_sec[, total_execs, edges_found]
#
# We identify columns by header comment. Fall back to positional if no header.
parse_plot_data() {
    local plot_file="$1"
    [[ ! -f "$plot_file" ]] && echo "0 0 0 0 0" && return

    # Read last non-empty line
    local last_line
    last_line=$(grep -v '^#' "$plot_file" | grep -v '^$' | tail -1)
    [[ -z "$last_line" ]] && echo "0 0 0 0 0" && return

    # Count columns to determine format
    local ncols
    ncols=$(echo "$last_line" | awk -F',' '{print NF}')

    # Extract fields (1-indexed): unix_time=1, map_size=7, saved_crashes=8, execs_per_sec=11
    # Newer AFL++ (>=4.x) adds total_execs=12 and edges_found=13
    local unix_time map_size saved_crashes execs_per_sec edges_found

    unix_time=$(    echo "$last_line" | cut -d',' -f1  | tr -d ' ')
    map_size=$(     echo "$last_line" | cut -d',' -f7  | tr -d ' ')
    saved_crashes=$(echo "$last_line" | cut -d',' -f8  | tr -d ' ')
    execs_per_sec=$(echo "$last_line" | cut -d',' -f11 | tr -d ' ')

    if [[ "$ncols" -ge 13 ]]; then
        edges_found=$(echo "$last_line" | cut -d',' -f13 | tr -d ' ')
    else
        # Older AFL++: map_size is the edges covered (as percentage * total_map)
        # Use map_size field as edges approximation
        edges_found="$map_size"
    fi

    echo "${unix_time:-0} ${edges_found:-0} ${saved_crashes:-0} ${execs_per_sec:-0} ${map_size:-0}"
}

# Helper: aggregate across all fuzzers
aggregate_metrics() {
    local total_edges=0 total_crashes=0 total_execs_per_sec=0 fuzzer_count=0

    for fuzzer_dir in "${CAMPAIGN_DIR}"/fuzzer*/; do
        [[ ! -d "$fuzzer_dir" ]] && continue
        local plot_file="${fuzzer_dir}plot_data"
        read -r _ edges crashes execs_ps _ <<< "$(parse_plot_data "$plot_file")"

        # Use the maximum edge count across fuzzers (AFL++ syncs corpus, not bitmaps)
        [[ "${edges:-0}" -gt "$total_edges" ]] && total_edges="${edges:-0}"
        total_crashes=$(( total_crashes + ${crashes:-0} ))
        total_execs_per_sec=$(( total_execs_per_sec + ${execs_ps:-0} ))
        (( fuzzer_count++ )) || true
    done

    echo "$total_edges $total_crashes $total_execs_per_sec $fuzzer_count"
}

# Saturation state tracking
PREV_EDGES=0
SATURATED_COUNT=0
SATURATED=false

# Load previous state if resuming
STATE_FILE="${ANALYTICS_DIR}/.state"
if [[ -f "$STATE_FILE" ]]; then
    source "$STATE_FILE"
fi

# Main sampling loop
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Poly/ML Campaign Analytics                |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo -e "${BLUE}Campaign:${NC}   $CAMPAIGN_NAME"
echo -e "${BLUE}Interval:${NC}   every $(( INTERVAL / 60 )) minutes"
echo -e "${BLUE}Saturates at:${NC} <${SATURATION_THRESHOLD} new edges/hour for ${SATURATION_WINDOW}h"
echo -e "${BLUE}Output:${NC}     $ANALYTICS_DIR"
echo ""
echo -e "Logging to: ${EDGES_CSV}"
echo -e "Press Ctrl+C to stop analytics (campaign continues)"
echo ""

SAMPLE=0
while true; do
    (( SAMPLE++ )) || true
    NOW=$(date +%s)
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

    # Check if any fuzzers are still running
    RUNNING=$(pgrep -f "afl-fuzz.*${CAMPAIGN_NAME}" 2>/dev/null | wc -l | tr -d ' ' || echo 0)

    # Aggregate current metrics
    read -r EDGES CRASHES EXECS_PS FUZZERS <<< "$(aggregate_metrics)"

    # Calculate delta
    DELTA=$(( EDGES - PREV_EDGES ))
    PREV_EDGES=$EDGES

    # Append to CSV
    # Columns: timestamp, unix_time, edges_found, delta_edges, total_execs (N/A),
    #          execs_per_sec, unique_crashes, unique_hangs (N/A)
    printf "%s,%d,%d,%d,0,%d,%d,0\n" \
        "$TIMESTAMP" "$NOW" "$EDGES" "$DELTA" "$EXECS_PS" "$CRASHES" \
        >> "$EDGES_CSV"

    # Display snapshot
    echo -e "${BLUE}[$(printf '%3d' $SAMPLE)] ${TIMESTAMP}${NC}"
    echo -e "  Edges found:     ${GREEN}${EDGES}${NC}"
    echo -e "  New this period: $(
        if [[ "$DELTA" -ge "$SATURATION_THRESHOLD" ]]; then
            echo -e "${GREEN}+${DELTA}${NC}"
        else
            echo -e "${YELLOW}+${DELTA} (low -- possible saturation)${NC}"
        fi
    )"
    echo -e "  Unique crashes:  ${CRASHES}"
    echo -e "  Exec speed:      ~${EXECS_PS} exec/s (${FUZZERS} fuzzers)"
    echo -e "  Active fuzzers:  ${RUNNING}"

    # Saturation detection (normalise delta to edges/hour when interval != 3600)
    EDGES_PER_HOUR="$DELTA"
    if [[ "$INTERVAL" -ne 3600 && "$INTERVAL" -gt 0 ]]; then
        EDGES_PER_HOUR=$(( DELTA * 3600 / INTERVAL ))
    fi

    if [[ "$SAMPLE" -gt 1 ]]; then
        if [[ "$EDGES_PER_HOUR" -lt "$SATURATION_THRESHOLD" ]]; then
            (( SATURATED_COUNT++ )) || true
            echo -e "  ${YELLOW}[!] Below saturation threshold ($SATURATED_COUNT/$SATURATION_WINDOW)${NC}"

            if [[ "$SATURATED_COUNT" -ge "$SATURATION_WINDOW" ]] && [[ "$SATURATED" == "false" ]]; then
                SATURATED=true
                SAT_MSG="[SATURATED] $(date '+%Y-%m-%d %H:%M:%S') edges/hour=${EDGES_PER_HOUR}, total_edges=${EDGES}"
                echo "$SAT_MSG" >> "$SATURATION_LOG"
                echo -e "  ${RED}[!] COVERAGE SATURATION DETECTED${NC}"
                echo -e "  ${RED}  Campaign may be stopped. Edges/hour: ${EDGES_PER_HOUR}${NC}"
            fi
        else
            SATURATED_COUNT=0
            SATURATED=false
        fi
    fi

    echo ""

    # Write summary file (overwrite each sample)
    {
        echo "=== Poly/ML Fuzzing Analytics Summary ==="
        echo "Campaign:        $CAMPAIGN_NAME"
        echo "Last updated:    $TIMESTAMP"
        echo "Sample #:        $SAMPLE"
        echo ""
        echo "=== Coverage ==="
        echo "Edges found:     $EDGES"
        echo "Last delta:      $DELTA"
        echo "Saturated:       $SATURATED (${SATURATED_COUNT}/${SATURATION_WINDOW} below threshold)"
        echo ""
        echo "=== Performance ==="
        echo "Exec speed:      ~${EXECS_PS} exec/s"
        echo "Active fuzzers:  $RUNNING"
        echo ""
        echo "=== Findings ==="
        echo "Unique crashes:  $CRASHES"
    } > "$SUMMARY_FILE"

    # Save state for resume
    {
        echo "PREV_EDGES=$PREV_EDGES"
        echo "SATURATED_COUNT=$SATURATED_COUNT"
        echo "SATURATED=$SATURATED"
    } > "$STATE_FILE"

    # Stop if no fuzzers running and not first sample
    if [[ "$RUNNING" -eq 0 && "$SAMPLE" -gt 1 ]]; then
        echo -e "${YELLOW}[*] No active fuzzers -- analytics loop ending${NC}"
        break
    fi

    sleep "$INTERVAL"
done

echo -e "${GREEN}[ok] Analytics complete. Data in: $ANALYTICS_DIR${NC}"
echo -e "${GREEN}[ok] Run ./campaign/report.sh $CAMPAIGN_NAME for full summary${NC}"
