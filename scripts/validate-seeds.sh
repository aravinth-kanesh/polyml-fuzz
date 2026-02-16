#!/bin/bash
# Validate all seed files parse without crashing Poly/ML

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SEEDS_DIR="${PROJECT_ROOT}/seeds"
POLY_BIN="${PROJECT_ROOT}/build/polyml-instrumented/install/bin/poly"

# Colours
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if Poly/ML exists
if [ ! -f "$POLY_BIN" ]; then
    echo -e "${RED}[!] Poly/ML not found. Build it first: ./scripts/build-polyml.sh${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Validating seed corpus${NC}"
echo ""

TOTAL=0
PASSED=0
FAILED=0
CRASHED=0

# Find all .sml and .ML files in seeds/
while IFS= read -r -d '' seed_file; do
    ((TOTAL++))

    # Get relative path for display
    rel_path="${seed_file#$PROJECT_ROOT/}"

    # Run Poly/ML with timeout
    if timeout 5 "$POLY_BIN" < "$seed_file" > /dev/null 2>&1; then
        echo -e "${GREEN}  [ok] $rel_path${NC}"
        ((PASSED++))
    else
        EXIT_CODE=$?
        if [ $EXIT_CODE -eq 124 ]; then
            # Timeout
            echo -e "${YELLOW}  [timeout] $rel_path (timeout)${NC}"
            ((FAILED++))
        elif [ $EXIT_CODE -gt 128 ]; then
            # Crash (signal)
            echo -e "${RED}  [FAIL] $rel_path (crashed with signal $((EXIT_CODE - 128)))${NC}"
            ((CRASHED++))
        else
            # Normal error (parse error is OK for some seeds)
            echo -e "${YELLOW}  ~ $rel_path (parse error - may be intentional)${NC}"
            ((PASSED++))
        fi
    fi

done < <(find "$SEEDS_DIR" -type f \( -name "*.sml" -o -name "*.ML" \) -print0)

echo ""
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Validation Summary                        |${NC}"
echo -e "${GREEN}+============================================+${NC}"
printf "${GREEN}|${NC}  Total seeds:     %-24s ${GREEN}|${NC}\n" "$TOTAL"
printf "${GREEN}|${NC}  Passed/Errors:   %-24s ${GREEN}|${NC}\n" "$PASSED"
printf "${GREEN}|${NC}  Timeouts:        %-24s ${GREEN}|${NC}\n" "$FAILED"
printf "${GREEN}|${NC}  Crashes:         %-24s ${GREEN}|${NC}\n" "$CRASHED"
echo -e "${GREEN}+============================================+${NC}"
echo ""

if [ $CRASHED -gt 0 ]; then
    echo -e "${RED}[!] Warning: Some seeds crashed Poly/ML${NC}"
    echo -e "${YELLOW}    This may indicate baseline bugs (good for fuzzing!)${NC}"
    echo -e "${YELLOW}    or genuinely invalid seeds (review manually)${NC}"
fi

if [ $TOTAL -lt 20 ]; then
    echo -e "${YELLOW}[!] Note: Only $TOTAL seeds found${NC}"
    echo -e "${YELLOW}    Consider adding more seeds for better coverage${NC}"
    echo -e "${YELLOW}    Target: 50+ seeds across different categories${NC}"
fi

echo ""
echo -e "${GREEN}[ok] Validation complete!${NC}"
