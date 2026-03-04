#!/bin/bash
# launch.sh -- Launch a structured Poly/ML fuzzing campaign
#
# Usage:
#   ./campaign/launch.sh --phase 1 [--duration SECONDS] [--instances N] [--name NAME]
#   ./campaign/launch.sh --phase 2 [--duration SECONDS] [--instances N] [--name NAME]
#
# Phase 1 uses Subset A corpus: basic/, operators/, edge-cases/, regression/
#   Focus: lexer tokens -- identifiers, operators, literals, comments, boundary values
#
# Phase 2 uses Subset B corpus: stress/, modules/, datatypes/
#   Focus: parser structures -- deep nesting, module system, complex type expressions
#
# Duration:
#   Default 259200 seconds (3 days). Recommended: 3-4 days per phase.
#   Set to 0 to run indefinitely (manual stop with: pkill afl-fuzz).
#
# Mutators (AFL++ default havoc + splice):
#   - Bit/byte flips on raw SML bytes
#   - Arithmetic mutations on integer literals
#   - Splice: recombine two corpus entries
#   - Havoc: random stacked mutations
#   These are appropriate for structured text (SML source) without a grammar mutator.
#
# Example:
#   ./campaign/launch.sh --phase 1 --duration 259200 --instances 4

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SEEDS_DIR="${PROJECT_ROOT}/seeds"
HARNESS="${PROJECT_ROOT}/harness/harness_afl"
RESULTS_DIR="${PROJECT_ROOT}/results"
LOG_DIR="${PROJECT_ROOT}/logs"
POLY_BIN="${PROJECT_ROOT}/build/polyml-instrumented/install/bin"

# Ensure poly is findable when the harness calls system("poly < input.sml")
export PATH="${POLY_BIN}:${PATH}"

# Colours
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Defaults
PHASE=""
DURATION=259200          # 3 days in seconds
INSTANCES=4              # Matches AWS c7g.xlarge (4 vCPU)
CAMPAIGN_NAME=""

# Argument parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        --phase)     PHASE="$2";         shift 2 ;;
        --duration)  DURATION="$2";      shift 2 ;;
        --instances) INSTANCES="$2";     shift 2 ;;
        --name)      CAMPAIGN_NAME="$2"; shift 2 ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *)
            echo -e "${RED}[!] Unknown argument: $1${NC}"; exit 1 ;;
    esac
done

if [[ -z "$PHASE" ]]; then
    echo -e "${RED}[!] --phase is required (1 or 2)${NC}"
    echo -e "    Usage: $0 --phase 1 [--duration 259200] [--instances 4]"
    exit 1
fi

if [[ "$PHASE" != "1" && "$PHASE" != "2" ]]; then
    echo -e "${RED}[!] --phase must be 1 or 2${NC}"; exit 1
fi

# Corpus subset selection
# Subset A (Phase 1): lexer-focused -- simple tokens, operators, edge cases
SUBSET_A_DIRS=("basic" "operators" "edge-cases" "regression")
# Subset B (Phase 2): parser-focused -- nested structures, modules, complex types
SUBSET_B_DIRS=("stress" "modules" "datatypes")

if [[ "$PHASE" == "1" ]]; then
    CORPUS_DIRS=("${SUBSET_A_DIRS[@]}")
    PHASE_DESC="Phase 1 -- Subset A (lexer: basic, operators, edge-cases, regression)"
else
    CORPUS_DIRS=("${SUBSET_B_DIRS[@]}")
    PHASE_DESC="Phase 2 -- Subset B (parser: stress, modules, datatypes)"
fi

# Campaign naming
if [[ -z "$CAMPAIGN_NAME" ]]; then
    CAMPAIGN_NAME="phase${PHASE}-$(date +%Y%m%d-%H%M%S)"
fi
OUTPUT_DIR="${RESULTS_DIR}/${CAMPAIGN_NAME}"
CORPUS_DIR="${OUTPUT_DIR}/corpus"  # Assembled subset corpus

mkdir -p "$LOG_DIR"
LAUNCH_LOG="${LOG_DIR}/${CAMPAIGN_NAME}-launch.log"

# Pre-flight checks
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Poly/ML Fuzzer -- Campaign Launcher       |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${BLUE}Phase:${NC}     $PHASE_DESC"
echo -e "${BLUE}Campaign:${NC}  $CAMPAIGN_NAME"
echo -e "${BLUE}Output:${NC}    $OUTPUT_DIR"
echo -e "${BLUE}Instances:${NC} $INSTANCES"
if [[ "$DURATION" -gt 0 ]]; then
    echo -e "${BLUE}Duration:${NC}  $DURATION seconds ($(( DURATION / 3600 )) hours)"
else
    echo -e "${BLUE}Duration:${NC}  indefinite (stop with: pkill afl-fuzz)"
fi
echo ""

if [[ ! -f "$HARNESS" ]]; then
    echo -e "${RED}[!] Harness not found: $HARNESS${NC}"
    echo -e "${YELLOW}    Build it first: ./scripts/build-harness.sh${NC}"
    exit 1
fi

# Assemble corpus subset
echo -e "${GREEN}[*] Assembling corpus subset...${NC}"
mkdir -p "$CORPUS_DIR"

SEED_COUNT=0
for dir in "${CORPUS_DIRS[@]}"; do
    SRC="${SEEDS_DIR}/${dir}"
    if [[ -d "$SRC" ]]; then
        COUNT=$(find "$SRC" -maxdepth 1 -type f \( -name "*.sml" -o -name "*.ML" \) | wc -l | tr -d ' ')
        find "$SRC" -maxdepth 1 -type f \( -name "*.sml" -o -name "*.ML" \) \
            -exec cp {} "$CORPUS_DIR/" \;
        echo -e "  ${GREEN}[ok]${NC} ${dir}/ (${COUNT} seeds)"
        SEED_COUNT=$(( SEED_COUNT + COUNT ))
    else
        echo -e "  ${YELLOW}[!]${NC} ${dir}/ not found, skipping"
    fi
done

if [[ "$SEED_COUNT" -eq 0 ]]; then
    echo -e "${RED}[!] No seeds found for Phase $PHASE corpus${NC}"; exit 1
fi
echo -e "${GREEN}[*] Total corpus: $SEED_COUNT seeds${NC}"
echo ""

# AFL++ environment
# Safety and performance knobs for Linux (AWS EC2 Graviton)
unset AFL_AUTORESUME  # Fresh run, not resuming

export AFL_SKIP_CPUFREQ=1                    # EC2 instances can't set CPU governor
export AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1
export AFL_TRY_AFFINITY=1                    # Best-effort CPU pinning
export AFL_NO_AFFINITY=0

# Sanitiser integration: tell AFL++ to enable ASan/UBSan at launch
# Poly/ML was built without compile-time sanitisers (to avoid bootstrap issues)
# but we can layer them on at runtime via AFL_USE_ASAN
export AFL_USE_ASAN=1
export AFL_USE_UBSAN=1

# Input timeout: 10 seconds per test case (Poly/ML can be slow on complex inputs)
TIMEOUT="10000"

# Record campaign start
START_TIME=$(date +%s)
START_DATE=$(date)
{
    echo "campaign=$CAMPAIGN_NAME"
    echo "phase=$PHASE"
    echo "start_time=$START_TIME"
    echo "start_date=$START_DATE"
    echo "duration=$DURATION"
    echo "instances=$INSTANCES"
    echo "seed_count=$SEED_COUNT"
    echo "corpus_dirs=${CORPUS_DIRS[*]}"
    echo "harness=$HARNESS"
} > "${OUTPUT_DIR}/campaign.meta"

# Pre-launch sanity check
echo -e "${GREEN}[*] Pre-launch sanity check...${NC}"
if ! timeout 15 "$HARNESS" < "${CORPUS_DIR}/$(ls "$CORPUS_DIR" | head -1)" > /dev/null 2>&1; then
    echo -e "${YELLOW}[!] Harness smoke test failed -- proceeding anyway (may be normal)${NC}"
else
    echo -e "${GREEN}[ok] Harness responds to input${NC}"
fi
echo ""

# Launch fuzzers
echo -e "${GREEN}[*] Launching $INSTANCES fuzzer instance(s)...${NC}"

declare -a FUZZER_PIDS=()

launch_fuzzer() {
    local name="$1"
    local role_flag="$2"  # "-M" for main, "-S" for secondary
    local run_log="${LOG_DIR}/${CAMPAIGN_NAME}-${name}.log"

    local afl_cmd=(
        afl-fuzz
            -i "$CORPUS_DIR"
            -o "$OUTPUT_DIR"
            "$role_flag" "$name"
            -t "$TIMEOUT"
            -m none
            -- "$HARNESS"
    )
    # Note: no @@ -- harness reads from stdin (AFL++ persistent mode)

    if [[ "$DURATION" -gt 0 ]]; then
        timeout --signal=SIGTERM "$DURATION" "${afl_cmd[@]}" \
            > "$run_log" 2>&1 &
    else
        "${afl_cmd[@]}" > "$run_log" 2>&1 &
    fi

    FUZZER_PIDS+=($!)
    echo -e "  ${GREEN}[ok]${NC} $name (PID ${FUZZER_PIDS[-1]}) -> $run_log"
}

# Main fuzzer (synchronises corpus across all instances)
launch_fuzzer "fuzzer01" "-M"
sleep 3  # Let main fuzzer initialise before secondaries connect

# Secondary fuzzers (read from main's queue)
for i in $(seq 2 "$INSTANCES"); do
    launch_fuzzer "$(printf "fuzzer%02d" "$i")" "-S"
    sleep 1
done

echo ""
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  [ok] Campaign running                     |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${YELLOW}Monitor coverage saturation:${NC}"
echo -e "  # Run in a separate terminal -- logs edges/hour:"
echo -e "  ./campaign/analytics.sh $CAMPAIGN_NAME"
echo ""
echo -e "${YELLOW}Live status dashboard:${NC}"
echo -e "  watch -n 30 ./campaign/monitor.sh $CAMPAIGN_NAME"
echo ""
echo -e "${YELLOW}After campaign completes:${NC}"
echo -e "  ./campaign/collect-crashes.sh $CAMPAIGN_NAME"
echo -e "  ./campaign/report.sh $CAMPAIGN_NAME"
echo ""
if [[ "$DURATION" -gt 0 ]]; then
    FINISH=$(date -d "@$(( START_TIME + DURATION ))" 2>/dev/null \
             || date -r "$(( START_TIME + DURATION ))" 2>/dev/null \
             || echo "in $(( DURATION / 3600 )) hours")
    echo -e "${BLUE}Scheduled to finish: $FINISH${NC}"
fi
echo ""

# Wait for all fuzzers
wait
END_TIME=$(date +%s)
echo "end_time=$END_TIME" >> "${OUTPUT_DIR}/campaign.meta"
echo -e "${GREEN}[ok] All fuzzers finished at $(date)${NC}"
echo -e "${GREEN}[ok] Run ./campaign/report.sh $CAMPAIGN_NAME for summary${NC}"
