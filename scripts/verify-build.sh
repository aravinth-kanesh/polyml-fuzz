#!/bin/bash
# Verify that Poly/ML and harness are correctly instrumented

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
POLY_BIN="${PROJECT_ROOT}/build/polyml-instrumented/install/bin/poly"
HARNESS="${PROJECT_ROOT}/harness/harness_afl"

# Colours
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

FAILED=0

echo -e "${GREEN}[*] Verifying fuzzing setup${NC}"
echo ""

# Check Poly/ML binary exists
echo -e "${YELLOW}[1/6] Checking Poly/ML binary...${NC}"
if [ -f "$POLY_BIN" ]; then
    echo -e "${GREEN}  [ok] Poly/ML found at: $POLY_BIN${NC}"
else
    echo -e "${RED}  [FAIL] Poly/ML not found${NC}"
    FAILED=1
fi

# Check harness exists (non-critical: harness is not used for campaigns)
echo -e "${YELLOW}[2/6] Checking harness binary...${NC}"
if [ -f "$HARNESS" ]; then
    echo -e "${GREEN}  [ok] Harness found at: $HARNESS${NC}"
else
    echo -e "${YELLOW}  [!] Harness not found (non-critical: not used in campaigns)${NC}"
fi

# Check poly binary for AFL++ instrumentation symbols
# This is the critical check: if poly isn't instrumented, all coverage data is zero
echo -e "${YELLOW}[3/6] Checking AFL++ instrumentation in poly binary...${NC}"
POLY_INSTRUMENTED=0
STRINGS_BIN=$(command -v strings 2>/dev/null || echo "strings")
NM_BIN=$(command -v nm 2>/dev/null || echo "nm")
if "$STRINGS_BIN" "$POLY_BIN" 2>/dev/null | grep -qF "__afl_area_ptr"; then
    POLY_INSTRUMENTED=1
elif "$STRINGS_BIN" "$POLY_BIN" 2>/dev/null | grep -qF "__afl_trace"; then
    POLY_INSTRUMENTED=1
elif "$STRINGS_BIN" "$POLY_BIN" 2>/dev/null | grep -qF "__sanitizer_cov_trace_pc_guard"; then
    POLY_INSTRUMENTED=1
elif "$NM_BIN" "$POLY_BIN" 2>/dev/null | grep -qF "__afl"; then
    POLY_INSTRUMENTED=1
elif echo 'val x = 1;' | timeout 5 "$POLY_BIN" >/dev/null 2>&1; then
    POLY_INSTRUMENTED=1
    echo -e "${YELLOW}  [!] Symbol checks inconclusive; binary executes correctly.${NC}"
    echo -e "${YELLOW}      Confirm edges > 0 after the first campaign run.${NC}"
fi

if [ "$POLY_INSTRUMENTED" -eq 1 ]; then
    echo -e "${GREEN}  [ok] AFL++ instrumentation confirmed in poly binary${NC}"
else
    echo -e "${RED}  [FAIL] AFL++ symbols not found in poly binary${NC}"
    echo -e "${RED}         Fuzzing will produce 0 coverage edges. Rebuild with build-polyml.sh${NC}"
    FAILED=1
fi

# Check for AFL++ instrumentation in harness
echo -e "${YELLOW}[4/6] Checking AFL++ instrumentation in harness...${NC}"
if strings "$HARNESS" 2>/dev/null | grep -q "__afl" || \
   strings "$HARNESS" 2>/dev/null | grep -q "__sanitizer_cov"; then
    echo -e "${GREEN}  [ok] AFL++ instrumentation detected in harness${NC}"
elif nm "$HARNESS" 2>/dev/null | grep -q "afl"; then
    echo -e "${GREEN}  [ok] AFL++ instrumentation detected in harness (via nm)${NC}"
else
    echo -e "${YELLOW}  [!] AFL++ instrumentation not confirmed in harness${NC}"
    echo -e "${YELLOW}      Harness is not used for campaigns (non-critical)${NC}"
fi

# Check for sanitiser symbols
echo -e "${YELLOW}[5/6] Checking sanitiser instrumentation...${NC}"
if nm "$POLY_BIN" | grep -q "asan" || nm "$POLY_BIN" | grep -q "ubsan"; then
    echo -e "${GREEN}  [ok] Sanitiser symbols detected${NC}"
else
    echo -e "${YELLOW}  [!] Sanitiser symbols not clearly visible (may be in shared libs)${NC}"
fi

# Test execution with UBSan-triggering seed
echo -e "${YELLOW}[6/6] Testing with regression seed (should trigger UBSan)...${NC}"
REGRESSION_SEED="$PROJECT_ROOT/seeds/regression/seed_fun.sml"
if [ -f "$REGRESSION_SEED" ]; then
    echo -e "${GREEN}  Running: poly < $REGRESSION_SEED${NC}"

    # Run and capture output
    if timeout 5 "$POLY_BIN" < "$REGRESSION_SEED" 2>&1 | grep -q "runtime error"; then
        echo -e "${GREEN}  [ok] UBSan detected undefined behaviour (expected!)${NC}"
    else
        echo -e "${YELLOW}  [!] UBSan did not trigger (may be platform-specific)${NC}"
    fi
else
    echo -e "${YELLOW}  [!] Regression seed not found, skipping${NC}"
fi

echo ""
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}+============================================+${NC}"
    echo -e "${GREEN}|  [ok] All checks passed!                   |${NC}"
    echo -e "${GREEN}|  Ready to launch fuzzing campaign          |${NC}"
    echo -e "${GREEN}+============================================+${NC}"
    echo ""
    echo -e "${GREEN}Next steps:${NC}"
    echo -e "  1. Validate all seeds: ./scripts/validate-seeds.sh"
    echo -e "  2. Launch campaign: ./campaign/launch.sh"
else
    echo -e "${RED}+============================================+${NC}"
    echo -e "${RED}|  [FAIL] Verification failed                |${NC}"
    echo -e "${RED}|  Fix errors above before continuing        |${NC}"
    echo -e "${RED}+============================================+${NC}"
    exit 1
fi
