#!/bin/bash
# Generate per-file LLVM source coverage report for Poly/ML
#
# Runs the seed corpus (and optionally an evolved AFL++ corpus) through the
# coverage-instrumented poly binary, merges the profile data, and produces:
#   - A text summary table (per source file: lines, functions, regions covered)
#   - An HTML report with line-by-line highlighting
#
# Usage:
#   ./scripts/coverage-report.sh
#   ./scripts/coverage-report.sh --evolved results/<campaign>/fuzzer01/queue
#   ./scripts/coverage-report.sh --phase 1        # seeds/basic, operators, edge-cases, regression only
#   ./scripts/coverage-report.sh --phase 2        # seeds/stress, modules, datatypes only
#
# Output: results/coverage/<timestamp>/
#   coverage_report.txt  per-file text summary
#   html/index.html      interactive HTML with line-level highlighting
#   merged.profdata      merged profile (can be reused with llvm-cov manually)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
POLYML_SRC="${PROJECT_ROOT}/polyml-src"
BUILD_DIR="${PROJECT_ROOT}/build/polyml-coverage"
POLY_BIN="$BUILD_DIR/install/bin/poly"
SEEDS_DIR="${PROJECT_ROOT}/seeds"
REPORT_BASE="${PROJECT_ROOT}/results/coverage"

# Add Homebrew LLVM to PATH on macOS
if [ -d "/opt/homebrew/opt/llvm/bin" ]; then
    export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
elif [ -d "/usr/local/opt/llvm/bin" ]; then
    export PATH="/usr/local/opt/llvm/bin:$PATH"
fi

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Defaults
EVOLVED_DIR=""
PHASE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --evolved)
            EVOLVED_DIR="$2"
            shift 2
            ;;
        --phase)
            PHASE="$2"
            shift 2
            ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            echo -e "${RED}[!] Unknown argument: $1${NC}"
            echo "Usage: $0 [--evolved <corpus-dir>] [--phase 1|2]"
            exit 1
            ;;
    esac
done

echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Poly/ML Per-File Coverage Report          |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""

# Check coverage binary exists
if [ ! -f "$POLY_BIN" ]; then
    echo -e "${RED}[!] Coverage-instrumented poly not found at: $POLY_BIN${NC}"
    echo -e "${YELLOW}    Build it first: ./scripts/build-polyml-coverage.sh${NC}"
    exit 1
fi

# Check Poly/ML source exists (needed for llvm-cov to map to source lines)
if [ ! -d "$POLYML_SRC" ]; then
    echo -e "${RED}[!] Poly/ML source not found at: $POLYML_SRC${NC}"
    echo -e "${YELLOW}    llvm-cov needs source files to generate the HTML report${NC}"
    exit 1
fi

# Find llvm tools (match version to what was used to build)
LLVM_PROFDATA_BIN=""
LLVM_COV_BIN=""

for ver in "-15" "-14" "-13" ""; do
    if command -v "llvm-profdata${ver}" &>/dev/null; then
        LLVM_PROFDATA_BIN="llvm-profdata${ver}"
        LLVM_COV_BIN="llvm-cov${ver}"
        break
    fi
done

if [ -z "$LLVM_PROFDATA_BIN" ]; then
    echo -e "${RED}[!] llvm-profdata not found. Install llvm tools.${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Coverage poly:  $POLY_BIN${NC}"
echo -e "${GREEN}[*] llvm-profdata:  $LLVM_PROFDATA_BIN${NC}"
echo -e "${GREEN}[*] llvm-cov:       $LLVM_COV_BIN${NC}"
echo ""

# Collect seed files to run
# Filter by phase if requested
SEED_SUBDIRS=()
if [ "$PHASE" = "1" ]; then
    SEED_SUBDIRS=("basic" "operators" "edge-cases" "regression")
    echo -e "${GREEN}[*] Phase 1 seeds: basic, operators, edge-cases, regression${NC}"
elif [ "$PHASE" = "2" ]; then
    SEED_SUBDIRS=("stress" "modules" "datatypes")
    echo -e "${GREEN}[*] Phase 2 seeds: stress, modules, datatypes${NC}"
else
    SEED_SUBDIRS=("basic" "operators" "edge-cases" "regression" "stress" "modules" "datatypes")
    echo -e "${GREEN}[*] All seeds (both phases)${NC}"
fi

INPUTS=()
for subdir in "${SEED_SUBDIRS[@]}"; do
    seed_path="${SEEDS_DIR}/${subdir}"
    if [ -d "$seed_path" ]; then
        while IFS= read -r -d '' f; do
            INPUTS+=("$f")
        done < <(find "$seed_path" -name "*.sml" -print0)
    fi
done

# Add evolved corpus entries if provided
if [ -n "$EVOLVED_DIR" ]; then
    if [ ! -d "$EVOLVED_DIR" ]; then
        echo -e "${RED}[!] Evolved corpus directory not found: $EVOLVED_DIR${NC}"
        exit 1
    fi
    while IFS= read -r -d '' f; do
        INPUTS+=("$f")
    done < <(find "$EVOLVED_DIR" -maxdepth 1 -type f -print0)
    echo -e "${GREEN}[*] Evolved corpus: $EVOLVED_DIR ($(find "$EVOLVED_DIR" -maxdepth 1 -type f | wc -l) entries)${NC}"
fi

echo -e "${GREEN}[*] Total inputs:  ${#INPUTS[@]}${NC}"
echo ""

# Create output directory
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUT_DIR="${REPORT_BASE}/${TIMESTAMP}"
PROFRAW_DIR="${OUT_DIR}/profraw"
mkdir -p "$PROFRAW_DIR"
echo -e "${GREEN}[*] Output directory: $OUT_DIR${NC}"
echo ""

# Run each input through coverage poly
# LLVM_PROFILE_FILE controls where the profraw data is written
# timeout 15s: match campaign timeout to avoid hangs skewing coverage
echo -e "${GREEN}[*] Running inputs through coverage poly...${NC}"
COUNT=0
FAILED=0
for input in "${INPUTS[@]}"; do
    COUNT=$((COUNT + 1))
    PROFRAW_FILE="${PROFRAW_DIR}/input_$(printf '%06d' $COUNT).profraw"
    LLVM_PROFILE_FILE="$PROFRAW_FILE" \
        timeout 15 "$POLY_BIN" < "$input" >/dev/null 2>&1 \
        || FAILED=$((FAILED + 1))
    # Print progress every 50 inputs
    if (( COUNT % 50 == 0 )); then
        echo -e "    ${COUNT}/${#INPUTS[@]} done..."
    fi
done
echo -e "${GREEN}[ok] Ran $COUNT inputs ($FAILED timed out or errored; expected for malformed inputs)${NC}"
echo ""

# Check at least some profraw files were generated
PROFRAW_COUNT=$(find "$PROFRAW_DIR" -name "*.profraw" -size +0 | wc -l)
if [ "$PROFRAW_COUNT" -eq 0 ]; then
    echo -e "${RED}[!] No profraw files generated. Coverage instrumentation may not be working.${NC}"
    exit 1
fi
echo -e "${GREEN}[*] Profile files generated: $PROFRAW_COUNT${NC}"

# Merge all profraw files into a single profdata file
echo -e "${GREEN}[*] Merging profile data...${NC}"
PROFDATA_FILE="${OUT_DIR}/merged.profdata"
"$LLVM_PROFDATA_BIN" merge -sparse \
    "${PROFRAW_DIR}"/input_*.profraw \
    -o "$PROFDATA_FILE"
echo -e "${GREEN}[ok] Merged profile: $PROFDATA_FILE${NC}"
echo ""

# Generate text summary (per-file table)
# Filter to libpolyml/ source files; exclude system headers and basis library
echo -e "${GREEN}[*] Generating per-file text summary...${NC}"
TEXT_REPORT="${OUT_DIR}/coverage_report.txt"
"$LLVM_COV_BIN" report "$POLY_BIN" \
    -instr-profile="$PROFDATA_FILE" \
    -ignore-filename-regex="(/usr/|basis/|/include/|Tests/)" \
    > "$TEXT_REPORT" 2>&1 || {
    echo -e "${YELLOW}[!] llvm-cov report returned non-zero; partial output may still be useful${NC}"
}
echo -e "${GREEN}[ok] Text report: $TEXT_REPORT${NC}"

# Generate HTML report with line-level highlighting
echo -e "${GREEN}[*] Generating HTML report...${NC}"
HTML_DIR="${OUT_DIR}/html"
"$LLVM_COV_BIN" show "$POLY_BIN" \
    -instr-profile="$PROFDATA_FILE" \
    -format=html \
    -output-dir="$HTML_DIR" \
    -show-line-counts \
    -show-regions \
    -ignore-filename-regex="(/usr/|basis/|/include/|Tests/)" \
    >/dev/null 2>&1 || {
    echo -e "${YELLOW}[!] HTML generation returned non-zero; check $HTML_DIR${NC}"
}
echo -e "${GREEN}[ok] HTML report: $HTML_DIR/index.html${NC}"
echo ""

# Print the relevant portion of the text report to terminal
# Focus on libpolyml/ source files
echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  Coverage Summary: libpolyml/ source files                     ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""

# Print header line then matching rows
head -3 "$TEXT_REPORT" || true
echo ""
grep "libpolyml" "$TEXT_REPORT" | sort -t'%' -k1 -rn || {
    echo -e "${YELLOW}    (no libpolyml lines found in report; check $TEXT_REPORT)${NC}"
}
echo ""
grep "^TOTAL" "$TEXT_REPORT" || true

echo ""
echo -e "${BLUE}================================================================${NC}"
echo -e "${GREEN}[ok] Key files to examine:${NC}"
echo -e "  scanner.cpp        (lexer)"
echo -e "  parse_dec.cpp      (top-level declaration parser)"
echo -e "  parse_type.cpp     (type expression parser)"
echo -e "  parse_expr.cpp     (expression parser, if present)"
echo -e "  arm64.cpp          (ARM64 code generator; ub1 location)"
echo ""
echo -e "${YELLOW}Full results:${NC}"
echo -e "  Text summary:  $TEXT_REPORT"
echo -e "  HTML report:   $HTML_DIR/index.html"
echo ""
echo -e "${YELLOW}To rerun llvm-cov manually against the merged profile:${NC}"
echo -e "  $LLVM_COV_BIN report $POLY_BIN -instr-profile=$PROFDATA_FILE"
