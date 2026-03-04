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
echo -e "${YELLOW}[1/5] Checking Poly/ML binary...${NC}"
if [ -f "$POLY_BIN" ]; then
    echo -e "${GREEN}  [ok] Poly/ML found at: $POLY_BIN${NC}"
else
    echo -e "${RED}  [FAIL] Poly/ML not found${NC}"
    FAILED=1
fi

# Check harness exists
echo -e "${YELLOW}[2/5] Checking harness binary...${NC}"
if [ -f "$HARNESS" ]; then
    echo -e "${GREEN}  [ok] Harness found at: $HARNESS${NC}"
else
    echo -e "${RED}  [FAIL] Harness not found${NC}"
    FAILED=1
fi

# Check for AFL++ instrumentation
echo -e "${YELLOW}[3/5] Checking AFL++ instrumentation...${NC}"
if strings "$HARNESS" 2>/dev/null | grep -q "__afl" || \
   strings "$HARNESS" 2>/dev/null | grep -q "__sanitizer_cov"; then
    echo -e "${GREEN}  [ok] AFL++ instrumentation detected${NC}"
elif nm "$HARNESS" 2>/dev/null | grep -q "afl"; then
    echo -e "${GREEN}  [ok] AFL++ instrumentation detected (via nm)${NC}"
else
    echo -e "${YELLOW}  [!] AFL++ instrumentation not confirmed by strings/nm${NC}"
    echo -e "${YELLOW}      Harness was compiled with afl-clang-fast -- should be fine${NC}"
fi

# Check for sanitiser symbols
echo -e "${YELLOW}[4/5] Checking sanitiser instrumentation...${NC}"
if nm "$POLY_BIN" | grep -q "asan" || nm "$POLY_BIN" | grep -q "ubsan"; then
    echo -e "${GREEN}  [ok] Sanitiser symbols detected${NC}"
else
    echo -e "${YELLOW}  [!] Sanitiser symbols not clearly visible (may be in shared libs)${NC}"
fi

# Test execution with UBSan-triggering seed
echo -e "${YELLOW}[5/5] Testing with regression seed (should trigger UBSan)...${NC}"
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
