#!/bin/bash
# launch.sh: Launch a structured Poly/ML fuzzing campaign
#
# Usage:
#   ./campaign/launch.sh --phase 1 [--duration SECONDS] [--instances N] [--name NAME] [--use-evolved]
#   ./campaign/launch.sh --phase 2 [--duration SECONDS] [--instances N] [--name NAME] [--use-evolved]
#
# Phase 1 uses Subset A corpus: basic/, operators/, edge-cases/, regression/
#   Focus: lexer tokens (identifiers, operators, literals, comments, boundary values)
#
# Phase 2 uses Subset B corpus: stress/, modules/, datatypes/
#   Focus: parser structures (deep nesting, module system, complex type expressions)
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
# Flags:
#   --use-evolved      Supplement seeds with evolved corpus from seeds/evolved/
#                      Populated by scripts/prepare-evolved-seeds.sh after a trial campaign.
#                      Gives the real campaign a head start on interesting mutations.
#   --grammar-mutator  Enable the SML structure-aware Python custom mutator on fuzzer03+04.
#                      Requires scripts/sml_mutator.py and Python 3.
#                      fuzzer01+02 continue with default AFL++ mutations for comparison.
#                      Use for retry campaigns when byte-level mutation has saturated.
#
# Example:
#   ./campaign/launch.sh --phase 1 --duration 259200 --instances 4 --use-evolved

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SEEDS_DIR="${PROJECT_ROOT}/seeds"
POLY="${PROJECT_ROOT}/build/polyml-instrumented/install/bin/poly"
DICT_FILE="${PROJECT_ROOT}/seeds/sml.dict"
EVOLVED_SEEDS_DIR="${PROJECT_ROOT}/seeds/evolved"

# Add AFL++ to PATH if not already there (needed in fresh Docker containers)
if [[ -d "${PROJECT_ROOT}/AFLplusplus" ]]; then
    export PATH="${PROJECT_ROOT}/AFLplusplus:${PATH}"
fi
RESULTS_DIR="${PROJECT_ROOT}/results"
LOG_DIR="${PROJECT_ROOT}/logs"

# Colours
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Defaults
PHASE=""
DURATION=259200          # 3 days in seconds
INSTANCES=4              # 4 instances for ARM64 production campaigns
CAMPAIGN_NAME=""
USE_EVOLVED=0
GRAMMAR_MUTATOR=0

# Argument parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        --phase)            PHASE="$2";         shift 2 ;;
        --duration)         DURATION="$2";      shift 2 ;;
        --instances)        INSTANCES="$2";     shift 2 ;;
        --name)             CAMPAIGN_NAME="$2"; shift 2 ;;
        --use-evolved)      USE_EVOLVED=1;      shift   ;;
        --grammar-mutator)  GRAMMAR_MUTATOR=1;  shift   ;;
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
# Subset A (Phase 1): lexer-focused seeds (simple tokens, operators, edge cases)
SUBSET_A_DIRS=("basic" "operators" "edge-cases" "regression")
# Subset B (Phase 2): parser-focused seeds (nested structures, modules, complex types)
# seeds/isabelle/ is included if present (populated by scripts/fetch-isabelle-seeds.sh)
SUBSET_B_DIRS=("stress" "modules" "datatypes")
if [[ -d "${SEEDS_DIR}/isabelle" ]] && [[ -n "$(ls -A "${SEEDS_DIR}/isabelle" 2>/dev/null)" ]]; then
    SUBSET_B_DIRS+=("isabelle")
fi

if [[ "$PHASE" == "1" ]]; then
    CORPUS_DIRS=("${SUBSET_A_DIRS[@]}")
    PHASE_DESC="Phase 1: Subset A (lexer: basic, operators, edge-cases, regression)"
    PHASE_LABEL="lexer"
else
    CORPUS_DIRS=("${SUBSET_B_DIRS[@]}")
    PHASE_DESC="Phase 2: Subset B (parser: stress, modules, datatypes)"
    PHASE_LABEL="parser"
fi

# Campaign naming: phase1-lexer-YYYYMMDD-HHMMSS / phase2-parser-YYYYMMDD-HHMMSS
if [[ -z "$CAMPAIGN_NAME" ]]; then
    CAMPAIGN_NAME="phase${PHASE}-${PHASE_LABEL}-$(date +%Y%m%d-%H%M%S)"
fi
OUTPUT_DIR="${RESULTS_DIR}/${CAMPAIGN_NAME}"
CORPUS_DIR="${OUTPUT_DIR}/corpus"  # Assembled subset corpus

mkdir -p "$LOG_DIR"
LAUNCH_LOG="${LOG_DIR}/${CAMPAIGN_NAME}-launch.log"

# Pre-flight checks
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Poly/ML Fuzzer: Campaign Launcher         |${NC}"
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

if [[ ! -f "$POLY" ]]; then
    echo -e "${RED}[!] Poly/ML binary not found: $POLY${NC}"
    echo -e "${YELLOW}    Build it first: ./scripts/build-polyml.sh${NC}"
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

# Optionally supplement with evolved corpus from prior trial campaigns
if [[ "$USE_EVOLVED" -eq 1 ]]; then
    if [[ -d "$EVOLVED_SEEDS_DIR" ]] && [[ -n "$(ls -A "$EVOLVED_SEEDS_DIR" 2>/dev/null)" ]]; then
        EVOLVED_COUNT=$(find "$EVOLVED_SEEDS_DIR" -maxdepth 1 -type f | wc -l | tr -d ' ')
        cp "$EVOLVED_SEEDS_DIR"/* "$CORPUS_DIR/"
        echo -e "  ${GREEN}[ok]${NC} evolved/ (${EVOLVED_COUNT} evolved seeds from prior campaigns)"
        SEED_COUNT=$(( SEED_COUNT + EVOLVED_COUNT ))
    else
        echo -e "  ${YELLOW}[!]${NC} --use-evolved set but seeds/evolved/ is empty or missing"
        echo -e "       Run: ./scripts/prepare-evolved-seeds.sh <campaign-name>"
    fi
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

# Disable leak detection: we care about crashes/hangs, not memory leaks;
# leak checking adds overhead that reduces throughput without improving bug discovery
export ASAN_OPTIONS="detect_leaks=0:abort_on_error=1:halt_on_error=1"

# Input timeout: 5 seconds per test case (reduced from 10s to improve throughput;
# legitimate inputs complete well within 5s; hangs are still caught at this limit)
TIMEOUT="5000"

# Record campaign start
START_TIME=$(date +%s)
START_DATE=$(date)
{
    echo "campaign=$CAMPAIGN_NAME"
    echo "phase=$PHASE"
    echo "start_time=$START_TIME"
    echo "start_date='$START_DATE'"
    echo "duration=$DURATION"
    echo "instances=$INSTANCES"
    echo "seed_count=$SEED_COUNT"
    echo "corpus_dirs='${CORPUS_DIRS[*]}'"
    echo "poly=$POLY"
} > "${OUTPUT_DIR}/campaign.meta"

# Pre-launch sanity check
echo -e "${GREEN}[*] Pre-launch sanity check...${NC}"
if ! timeout 15 "$POLY" < "${CORPUS_DIR}/$(ls "$CORPUS_DIR" | head -1)" > /dev/null 2>&1; then
    echo -e "${YELLOW}[!] Poly/ML smoke test failed; proceeding anyway (may be normal)${NC}"
else
    echo -e "${GREEN}[ok] Poly/ML responds to input${NC}"
fi
echo ""

# Launch fuzzers
echo -e "${GREEN}[*] Launching $INSTANCES fuzzer instance(s)...${NC}"

declare -a FUZZER_PIDS=()

launch_fuzzer() {
    local name="$1"
    local role_flag="$2"      # "-M" for main, "-S" for secondary
    local schedule="$3"       # power schedule: "explore" for main, "fast"/"rare" for secondaries
    local cmplog="${4:-0}"    # 1 = enable CMPLOG on this instance
    local use_grammar="${5:-0}" # 1 = enable SML structure-aware Python custom mutator
    local run_log="${LOG_DIR}/${CAMPAIGN_NAME}-${name}.log"

    local afl_cmd=(
        afl-fuzz
            -i "$CORPUS_DIR"
            -o "$OUTPUT_DIR"
            "$role_flag" "$name"
            -p "$schedule"
            -t "$TIMEOUT"
            -m none
            -a text        # SML source is ASCII text; prevents binary byte insertion
    )

    # CMPLOG: log comparison operands and mutate inputs to match them;
    # helps AFL++ solve magic-byte checks and integer comparisons in the parser
    if [[ "$cmplog" -eq 1 ]]; then
        afl_cmd+=(-c 0)
    fi

    # SML token dictionary: helps AFL++ produce syntactically meaningful mutations
    if [[ -f "$DICT_FILE" ]]; then
        afl_cmd+=(-x "$DICT_FILE")
    fi

    afl_cmd+=(-- "$POLY")
    # Direct fuzzing: poly reads SML from stdin; AFL++ tracks coverage inside poly

    # Grammar mutator: structure-aware Python custom mutator runs alongside AFL++
    # default mutations (AFL_CUSTOM_MUTATOR_ONLY=0). Targets numeric literal edge
    # cases, long identifiers, nested expressions, and comment delimiter corruption.
    local extra_env=()
    if [[ "$use_grammar" -eq 1 ]] && [[ -f "${PROJECT_ROOT}/scripts/sml_mutator.py" ]]; then
        extra_env+=(
            "AFL_PYTHON_MODULE=sml_mutator"
            "AFL_CUSTOM_MUTATOR_ONLY=0"
            "PYTHONPATH=${PROJECT_ROOT}/scripts"
        )
    fi

    if [[ "$DURATION" -gt 0 ]]; then
        env "${extra_env[@]}" timeout --signal=SIGTERM "$DURATION" "${afl_cmd[@]}" \
            > "$run_log" 2>&1 &
    else
        env "${extra_env[@]}" "${afl_cmd[@]}" > "$run_log" 2>&1 &
    fi

    FUZZER_PIDS+=($!)
    echo -e "  ${GREEN}[ok]${NC} $name (PID ${FUZZER_PIDS[-1]}) -> $run_log"
}

# Main fuzzer: explore schedule maximises coverage breadth; CMPLOG enabled
launch_fuzzer "fuzzer01" "-M" "explore" 1 0
sleep 3  # Let main fuzzer initialise before secondaries connect

# Secondary fuzzers:
#   fuzzer02: fast schedule + CMPLOG for comparison-guided mutation
#   fuzzer03: rare schedule focuses on rarely-hit edges; grammar mutator if enabled
#   fuzzer04+: fast schedule; grammar mutator if enabled (retry campaigns only)
for i in $(seq 2 "$INSTANCES"); do
    name="$(printf "fuzzer%02d" "$i")"
    if [[ "$i" -eq 2 ]]; then
        launch_fuzzer "$name" "-S" "fast" 1 0   # CMPLOG secondary, no grammar mutator
    elif [[ "$i" -eq 3 ]]; then
        launch_fuzzer "$name" "-S" "rare" 0 "$GRAMMAR_MUTATOR"   # rare + optional grammar
    else
        launch_fuzzer "$name" "-S" "fast" 0 "$GRAMMAR_MUTATOR"   # fast + optional grammar
    fi
    sleep 1
done

echo ""
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  [ok] Campaign running                     |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${YELLOW}Monitor coverage saturation:${NC}"
echo -e "  # Run in a separate terminal (logs edges/hour):"
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
