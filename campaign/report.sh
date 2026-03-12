#!/bin/bash
# report.sh: Generate a post-campaign summary report
#
# Reads AFL++ output directories and analytics/ data to produce a structured
# summary of: total coverage, saturation time, crashes found, and performance.
#
# Usage:
#   ./campaign/report.sh <campaign-name>
#
# Output:
#   results/<campaign>/REPORT.md   Markdown report (for dissertation appendix)
#   results/<campaign>/REPORT.txt  Plain text version

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="${PROJECT_ROOT}/results"

# Colours
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

CAMPAIGN_NAME="${1:-}"
QUIET=0
for arg in "$@"; do [[ "$arg" == "--quiet" ]] && QUIET=1; done

if [[ -z "$CAMPAIGN_NAME" ]]; then
    echo -e "${RED}Usage: $0 <campaign-name>${NC}"; exit 1
fi

CAMPAIGN_DIR="${RESULTS_DIR}/${CAMPAIGN_NAME}"
ANALYTICS_DIR="${CAMPAIGN_DIR}/analytics"
META_FILE="${CAMPAIGN_DIR}/campaign.meta"

if [[ ! -d "$CAMPAIGN_DIR" ]]; then
    echo -e "${RED}[!] Campaign not found: $CAMPAIGN_DIR${NC}"; exit 1
fi

[[ $QUIET -eq 0 ]] && echo -e "${GREEN}[*] Generating report for campaign: $CAMPAIGN_NAME${NC}"

# Read campaign metadata (parsed safely; do not source as values may contain spaces)
phase=""; START_TIME=""; start_date=""; END_TIME=""; duration=""
instances=""; seed_count=""; corpus_dirs=""

if [[ -f "$META_FILE" ]]; then
    phase=$(grep '^phase='       "$META_FILE" | cut -d= -f2-)
    START_TIME=$(grep '^start_time=' "$META_FILE" | cut -d= -f2-)
    start_date=$(grep '^start_date=' "$META_FILE" | cut -d= -f2-)
    END_TIME=$(grep '^end_time='    "$META_FILE" | cut -d= -f2-)
    duration=$(grep '^duration='   "$META_FILE" | cut -d= -f2-)
    instances=$(grep '^instances='  "$META_FILE" | cut -d= -f2-)
    seed_count=$(grep '^seed_count=' "$META_FILE" | cut -d= -f2-)
    corpus_dirs=$(grep '^corpus_dirs=' "$META_FILE" | cut -d= -f2-)
fi

# Compute elapsed time
if [[ -n "$START_TIME" && -n "$END_TIME" ]]; then
    ELAPSED=$(( END_TIME - START_TIME ))
    ELAPSED_H=$(( ELAPSED / 3600 ))
    ELAPSED_M=$(( (ELAPSED % 3600) / 60 ))
    ELAPSED_STR="${ELAPSED_H}h ${ELAPSED_M}m"
elif [[ -n "$START_TIME" ]]; then
    ELAPSED=$(( $(date +%s) - START_TIME ))
    ELAPSED_H=$(( ELAPSED / 3600 ))
    ELAPSED_STR="${ELAPSED_H}h (still running?)"
else
    ELAPSED_STR="unknown"
fi

# Count crashes and hangs
TOTAL_CRASHES=0; TOTAL_HANGS=0; FUZZER_COUNT=0
TOTAL_EXECS=0; CORPUS_SIZE=0
MAX_EDGES=0

for fuzzer_dir in "${CAMPAIGN_DIR}"/fuzzer*/; do
    [[ ! -d "$fuzzer_dir" ]] && continue
    (( FUZZER_COUNT++ )) || true

    # Crashes
    crashes_dir="${fuzzer_dir}crashes"
    if [[ -d "$crashes_dir" ]]; then
        c=$(find "$crashes_dir" -type f ! -name "README.txt" | wc -l | tr -d ' ')
        TOTAL_CRASHES=$(( TOTAL_CRASHES + c ))
    fi

    # Hangs
    hangs_dir="${fuzzer_dir}hangs"
    if [[ -d "$hangs_dir" ]]; then
        h=$(find "$hangs_dir" -type f ! -name "README.txt" | wc -l | tr -d ' ')
        TOTAL_HANGS=$(( TOTAL_HANGS + h ))
    fi

    # Queue size (evolved corpus)
    queue_dir="${fuzzer_dir}queue"
    if [[ -d "$queue_dir" ]]; then
        q=$(find "$queue_dir" -type f ! -name ".state" | wc -l | tr -d ' ')
        CORPUS_SIZE=$(( CORPUS_SIZE + q ))
    fi

    # Parse plot_data for final stats
    plot_file="${fuzzer_dir}plot_data"
    if [[ -f "$plot_file" ]]; then
        last=$(grep -v '^#' "$plot_file" | grep -v '^$' | tail -1)
        if [[ -n "$last" ]]; then
            ncols=$(echo "$last" | awk -F',' '{print NF}')
            # edges_found is column 13 in newer AFL++
            if [[ "$ncols" -ge 13 ]]; then
                edges=$(echo "$last" | cut -d',' -f13 | tr -d ' ')
                [[ "${edges:-0}" -gt "$MAX_EDGES" ]] && MAX_EDGES="${edges:-0}"
            fi
            # execs from map_size / total_execs
            if [[ "$ncols" -ge 12 ]]; then
                execs=$(echo "$last" | cut -d',' -f12 | tr -d ' ')
                TOTAL_EXECS=$(( TOTAL_EXECS + ${execs:-0} ))
            fi
        fi
    fi
done

# Read analytics data
SATURATION_TIME="Not detected"
SATURATION_EDGES=0
EDGES_CSV_LINES=0

if [[ -f "${ANALYTICS_DIR}/saturation.log" ]]; then
    FIRST_SAT=$(head -1 "${ANALYTICS_DIR}/saturation.log")
    if [[ -n "$FIRST_SAT" ]]; then
        SATURATION_TIME=$(echo "$FIRST_SAT" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9:]*' | head -1)
    fi
fi

if [[ -f "${ANALYTICS_DIR}/edges_over_time.csv" ]]; then
    EDGES_CSV_LINES=$(( $(wc -l < "${ANALYTICS_DIR}/edges_over_time.csv") - 1 ))
    # Get peak edges from CSV
    PEAK=$(tail -n +2 "${ANALYTICS_DIR}/edges_over_time.csv" | cut -d',' -f3 | sort -n | tail -1)
    [[ "${PEAK:-0}" -gt "$MAX_EDGES" ]] && MAX_EDGES="${PEAK:-0}"
fi

# Source coverage summary (populated by coverage-report.sh if run via analyse.sh)
COVERAGE_DIR="${CAMPAIGN_DIR}/coverage"
COVERAGE_TOTAL=""
COVERAGE_ARM64=""
if [[ -f "${COVERAGE_DIR}/coverage_report.txt" ]]; then
    COVERAGE_TOTAL=$(grep "^TOTAL" "${COVERAGE_DIR}/coverage_report.txt" | awk '{print $NF}' | head -1)
    COVERAGE_ARM64=$(grep "arm64.cpp" "${COVERAGE_DIR}/coverage_report.txt" | awk '{print $NF}' | head -1)
fi

# Triage summary
TRIAGE_DIR="${CAMPAIGN_DIR}/triaged"
UBSAN_COUNT=0; ASAN_COUNT=0; SIGNAL_COUNT=0

if [[ -d "$TRIAGE_DIR" ]]; then
    for summary in "${TRIAGE_DIR}"/*.summary; do
        [[ ! -f "$summary" ]] && continue
        fault=$(grep "^Type:" "$summary" | cut -d' ' -f2-)
        case "$fault" in
            UndefinedBehavior*) (( UBSAN_COUNT++ ))  || true ;;
            Heap*|Stack*|Use*)  (( ASAN_COUNT++ ))   || true ;;
            Signal*)            (( SIGNAL_COUNT++ )) || true ;;
        esac
    done
fi

# Write Markdown report
REPORT_MD="${CAMPAIGN_DIR}/REPORT.md"

cat > "$REPORT_MD" << MDEOF
# Campaign Report: ${CAMPAIGN_NAME}

Generated: $(date)

## Campaign Parameters

| Parameter       | Value                     |
|-----------------|---------------------------|
| Phase           | ${phase:-N/A}             |
| Start date      | ${start_date:-unknown}    |
| Elapsed time    | ${ELAPSED_STR}            |
| Duration target | ${duration:-N/A} seconds  |
| Fuzzer instances| ${instances:-$FUZZER_COUNT}|
| Seed corpus     | ${seed_count:-N/A} seeds  |
| Corpus subsets  | ${corpus_dirs:-all}       |

## Coverage Results

| Metric                 | Value        |
|------------------------|--------------|
| Edges found (total)    | ${MAX_EDGES} |
| Analytics samples      | ${EDGES_CSV_LINES} |
| Coverage saturation at | ${SATURATION_TIME} |

## Findings

| Category        | Count        |
|-----------------|--------------|
| Unique crashes  | ${TOTAL_CRASHES} |
| Hangs           | ${TOTAL_HANGS}   |
| UBSan bugs      | ${UBSAN_COUNT}   |
| ASan bugs       | ${ASAN_COUNT}    |
| Signal crashes  | ${SIGNAL_COUNT}  |

## Corpus Evolution

| Metric              | Value            |
|---------------------|------------------|
| Initial seed count  | ${seed_count:-N/A} |
| Evolved corpus size | ${CORPUS_SIZE}   |
| Total executions    | ${TOTAL_EXECS}   |

## Source Coverage (LLVM)

| Metric                        | Value            |
|-------------------------------|------------------|
| Total libpolyml/ region cov.  | ${COVERAGE_TOTAL:-not generated} |
| arm64.cpp region coverage     | ${COVERAGE_ARM64:-not generated} |
| Full report                   | \`results/${CAMPAIGN_NAME}/coverage/coverage_report.txt\` |

## Fuzzer Configuration

- **Fuzzer:** AFL++ with persistent mode (\`__AFL_LOOP(1000)\`)
- **Mutators:** Default havoc + splice (bit/byte flips, arithmetic, splicing)
- **Instrumentation:** afl-clang-fast (LLVM edge coverage)
- **Target binary:** Poly/ML \`poly\` with AFL++ edge-coverage instrumentation
- **Input timeout:** 10,000 ms per test case
- **Sanitisers:** ASan + UBSan enabled at launch via \`AFL_USE_ASAN=1\` / \`AFL_USE_UBSAN=1\`

## Reproduction

To reproduce any crash:
\`\`\`bash
./campaign/reproduce-crash.sh results/${CAMPAIGN_NAME}/fuzzer01/crashes/<crash-id>
\`\`\`

## File Locations

| Output                | Path                                          |
|-----------------------|-----------------------------------------------|
| AFL++ output          | \`results/${CAMPAIGN_NAME}/fuzzer*/\`           |
| Collected crashes     | \`results/${CAMPAIGN_NAME}/collected-crashes/\` |
| Triaged summaries     | \`results/${CAMPAIGN_NAME}/triaged/\`           |
| Analytics CSV         | \`results/${CAMPAIGN_NAME}/analytics/edges_over_time.csv\` |
| Saturation log        | \`results/${CAMPAIGN_NAME}/analytics/saturation.log\` |
MDEOF

# Print summary to terminal
if [[ $QUIET -eq 1 ]]; then
    echo -e "${GREEN}  [ok] Report: edges=${MAX_EDGES}, crashes=${TOTAL_CRASHES}${NC}"
    [[ -n "$COVERAGE_TOTAL" ]] && echo -e "${GREEN}       Coverage: ${COVERAGE_TOTAL} total, arm64.cpp: ${COVERAGE_ARM64:-n/a}${NC}"
    echo -e "${GREEN}       ${REPORT_MD}${NC}"
else
    echo ""
    echo -e "${GREEN}+============================================+${NC}"
    echo -e "${GREEN}|  Campaign Report Summary                   |${NC}"
    echo -e "${GREEN}+============================================+${NC}"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "Campaign:"    "$CAMPAIGN_NAME"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "Elapsed:"     "$ELAPSED_STR"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "Edges found:" "$MAX_EDGES"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "Saturation:"  "$SATURATION_TIME"
    echo -e "${GREEN}+============================================+${NC}"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "Unique crashes:" "$TOTAL_CRASHES"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "  UBSan:"  "$UBSAN_COUNT"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "  ASan:"   "$ASAN_COUNT"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "  Signal:" "$SIGNAL_COUNT"
    echo -e "${GREEN}+============================================+${NC}"
    if [[ -n "$COVERAGE_TOTAL" ]]; then
        printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "Source coverage:" "$COVERAGE_TOTAL"
        printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "  arm64.cpp:" "${COVERAGE_ARM64:-n/a}"
        echo -e "${GREEN}+============================================+${NC}"
    fi
    echo ""
    echo -e "${BLUE}Report written to: $REPORT_MD${NC}"
    echo ""
    echo -e "${YELLOW}To view coverage over time:${NC}"
    echo -e "  cat ${CAMPAIGN_DIR}/analytics/edges_over_time.csv"
fi
