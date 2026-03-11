#!/bin/bash
# reproduce-crash.sh: Reproduce a crash found during fuzzing
#
# Given a crash input file (from AFL++ crashes/ directory), this script:
#   1. Confirms the crash reproduces reliably
#   2. Captures the full sanitiser stack trace
#   3. Classifies the fault type (ASan/UBSan/signal)
#   4. Saves a structured report alongside the input
#
# Designed to be simple and repeatable; can be run many times
# against the same input while applying patches or debugging.
#
# Usage:
#   ./campaign/reproduce-crash.sh <crash_input_file> [--output DIR] [--poly PATH]
#
# Example:
#   ./campaign/reproduce-crash.sh results/phase1-xxx/fuzzer01/crashes/id:000001,sig:06,...
#
# Options:
#   --output DIR    Write report to DIR/ (default: alongside the input file)
#   --poly PATH     Path to poly binary (default: build/polyml-instrumented/install/bin/poly)
#   --attempts N    Number of reproduction attempts (default: 3)
#   --timeout N     Seconds per attempt (default: 15)
#
# Exit codes:
#   0  Crash reproduced
#   1  Usage error
#   2  Crash did NOT reproduce (flaky or fixed)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colours
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Defaults
POLY_BIN="${PROJECT_ROOT}/build/polyml-instrumented/install/bin/poly"
OUTPUT_DIR=""
ATTEMPTS=3
TIMEOUT=15

# Argument parsing
CRASH_INPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)   OUTPUT_DIR="$2"; shift 2 ;;
        --poly)     POLY_BIN="$2";   shift 2 ;;
        --attempts) ATTEMPTS="$2";   shift 2 ;;
        --timeout)  TIMEOUT="$2";    shift 2 ;;
        -h|--help)
            sed -n '2,25p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        -*)
            echo -e "${RED}[!] Unknown option: $1${NC}"; exit 1 ;;
        *)
            CRASH_INPUT="$1"; shift ;;
    esac
done

if [[ -z "$CRASH_INPUT" ]]; then
    echo -e "${RED}[!] Usage: $0 <crash_input_file> [options]${NC}"
    echo -e "    Example: $0 results/phase1-xxx/fuzzer01/crashes/id:000001,sig:06,..."
    exit 1
fi

if [[ ! -f "$CRASH_INPUT" ]]; then
    echo -e "${RED}[!] Crash input not found: $CRASH_INPUT${NC}"; exit 1
fi

if [[ ! -f "$POLY_BIN" ]]; then
    echo -e "${RED}[!] Poly/ML binary not found: $POLY_BIN${NC}"
    echo -e "${YELLOW}    Specify with: --poly <path>${NC}"; exit 1
fi

# Output directory
CRASH_NAME=$(basename "$CRASH_INPUT")
if [[ -z "$OUTPUT_DIR" ]]; then
    OUTPUT_DIR="$(dirname "$CRASH_INPUT")/reproduced-${CRASH_NAME}"
fi
mkdir -p "$OUTPUT_DIR"

REPORT_FILE="${OUTPUT_DIR}/report.txt"
FULL_LOG="${OUTPUT_DIR}/sanitiser.log"
REPRO_COPY="${OUTPUT_DIR}/input.sml"

# Copy input for easy manual reproduction
cp "$CRASH_INPUT" "$REPRO_COPY"

# Print input summary
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Poly/ML Crash Reproduction (UC2)          |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${BLUE}Input file:${NC} $CRASH_INPUT"
echo -e "${BLUE}Input size:${NC} $(wc -c < "$CRASH_INPUT") bytes, $(wc -l < "$CRASH_INPUT") lines"
echo -e "${BLUE}Poly binary:${NC} $POLY_BIN"
echo -e "${BLUE}Output dir:${NC} $OUTPUT_DIR"
echo -e "${BLUE}Attempts:${NC}   $ATTEMPTS"
echo ""
echo -e "${BLUE}--- Input contents ---${NC}"
head -20 "$CRASH_INPUT" | cat -v  # cat -v shows non-printable chars
echo ""

# Run reproduction attempts
echo -e "${GREEN}[*] Attempting reproduction ($ATTEMPTS tries)...${NC}"

REPRODUCED=false
LAST_EXIT=0
LAST_LOG=""

for attempt in $(seq 1 "$ATTEMPTS"); do
    ATTEMPT_LOG="${OUTPUT_DIR}/attempt-${attempt}.log"

    timeout "$TIMEOUT" "$POLY_BIN" \
        < "$CRASH_INPUT" \
        > /dev/null \
        2> "$ATTEMPT_LOG"  || LAST_EXIT=$?

    if [[ "$LAST_EXIT" -ne 0 ]]; then
        REPRODUCED=true
        LAST_LOG="$ATTEMPT_LOG"
        echo -e "  Attempt $attempt: ${RED}CRASH (exit ${LAST_EXIT})${NC}"
    else
        echo -e "  Attempt $attempt: ${YELLOW}no crash (exit 0)${NC}"
    fi
done

echo ""

# Classify fault type
classify_fault() {
    local log="$1"
    local exit_code="$2"

    if grep -q "heap-buffer-overflow" "$log" 2>/dev/null; then
        echo "ASan: HeapBufferOverflow"
    elif grep -q "stack-buffer-overflow" "$log" 2>/dev/null; then
        echo "ASan: StackBufferOverflow"
    elif grep -q "use-after-free" "$log" 2>/dev/null; then
        echo "ASan: UseAfterFree"
    elif grep -q "heap-use-after-free" "$log" 2>/dev/null; then
        echo "ASan: HeapUseAfterFree"
    elif grep -q "double-free" "$log" 2>/dev/null; then
        echo "ASan: DoubleFree"
    elif grep -q "runtime error" "$log" 2>/dev/null; then
        # Extract specific UBSan error
        local ubsan_detail
        ubsan_detail=$(grep "runtime error" "$log" | head -1 | sed 's/.*runtime error: //')
        echo "UBSan: ${ubsan_detail:-UnknownUB}"
    elif [[ "$exit_code" -eq 124 ]]; then
        echo "Timeout"
    elif [[ "$exit_code" -gt 128 ]]; then
        local sig=$(( exit_code - 128 ))
        case "$sig" in
            6)  echo "Signal: SIGABRT (abort; likely sanitiser)" ;;
            11) echo "Signal: SIGSEGV (segmentation fault)" ;;
            4)  echo "Signal: SIGILL (illegal instruction)" ;;
            8)  echo "Signal: SIGFPE (floating point exception)" ;;
            *)  echo "Signal: SIG${sig}" ;;
        esac
    else
        echo "Unknown (exit code ${exit_code})"
    fi
}

# Extract stack trace
extract_stack_trace() {
    local log="$1"
    # Look for ASan/UBSan stack trace patterns
    if grep -q "#0 " "$log" 2>/dev/null; then
        grep -A 30 "ERROR:\|runtime error:\|SUMMARY:" "$log" | head -40
    else
        head -30 "$log"
    fi
}

# Generate report
FAULT_TYPE="Not reproduced"
if [[ "$REPRODUCED" == "true" && -n "$LAST_LOG" ]]; then
    FAULT_TYPE=$(classify_fault "$LAST_LOG" "$LAST_EXIT")
    cat "$LAST_LOG" > "$FULL_LOG"
fi

{
    echo "=== Poly/ML Crash Reproduction Report ==="
    echo "Generated: $(date)"
    echo ""
    echo "--- Input ---"
    echo "File:        $CRASH_INPUT"
    echo "Name:        $CRASH_NAME"
    echo "Size:        $(wc -c < "$CRASH_INPUT") bytes"
    echo ""
    echo "--- Reproduction ---"
    echo "Reproduced:  $REPRODUCED"
    echo "Attempts:    $ATTEMPTS"
    echo "Exit code:   $LAST_EXIT"
    echo "Fault type:  $FAULT_TYPE"
    echo ""
    echo "--- Reproduction Command ---"
    echo "  $POLY_BIN < $REPRO_COPY"
    echo "  # Or with explicit sanitiser options:"
    echo "  ASAN_OPTIONS=halt_on_error=1:abort_on_error=1 UBSAN_OPTIONS=print_stacktrace=1 \\"
    echo "    $POLY_BIN < $REPRO_COPY"
    echo ""
    echo "--- Input Contents ---"
    cat "$CRASH_INPUT"
    echo ""
    echo "--- Sanitiser Output ---"
    if [[ -n "$LAST_LOG" ]]; then
        extract_stack_trace "$LAST_LOG"
    else
        echo "(no crash output; not reproduced)"
    fi
} > "$REPORT_FILE"

# Print result
if [[ "$REPRODUCED" == "true" ]]; then
    echo -e "${RED}+============================================+${NC}"
    echo -e "${RED}|  [FAIL] CRASH REPRODUCED                        |${NC}"
    echo -e "${RED}+============================================+${NC}"
    echo ""
    echo -e "${BLUE}Fault type:${NC} $FAULT_TYPE"
    echo ""
    echo -e "${BLUE}--- Sanitiser Output ---${NC}"
    extract_stack_trace "$FULL_LOG" | head -30
    echo ""
    echo -e "${BLUE}--- Reproduction Command ---${NC}"
    echo -e "  ${GREEN}$POLY_BIN < $REPRO_COPY${NC}"
    echo ""
    echo -e "${BLUE}Full report: $REPORT_FILE${NC}"
    exit 0
else
    echo -e "${YELLOW}+============================================+${NC}"
    echo -e "${YELLOW}|  [ok] Crash did NOT reproduce                 |${NC}"
    echo -e "${YELLOW}+============================================+${NC}"
    echo ""
    echo -e "This may mean the bug has been fixed, or the crash is environment-dependent."
    echo -e "Try with a different build: --poly <path-to-other-poly-binary>"
    echo ""
    echo -e "${BLUE}Report saved: $REPORT_FILE${NC}"
    exit 2
fi
