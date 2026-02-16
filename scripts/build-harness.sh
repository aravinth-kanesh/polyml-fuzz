#!/bin/bash
# Build AFL++ fuzzing harness for Poly/ML

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HARNESS_DIR="${PROJECT_ROOT}/harness"
BUILD_DIR="${PROJECT_ROOT}/build/polyml-instrumented"
POLY_BIN="$BUILD_DIR/install/bin/poly"

# Add LLVM and local AFLplusplus to PATH
# LLVM is required for afl-clang-fast to find clang
if [ -d "/opt/homebrew/opt/llvm/bin" ]; then
    export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
elif [ -d "/usr/local/opt/llvm/bin" ]; then
    export PATH="/usr/local/opt/llvm/bin:$PATH"
fi

if [ -d "${PROJECT_ROOT}/AFLplusplus" ]; then
    export PATH="${PROJECT_ROOT}/AFLplusplus:$PATH"
fi

# Colours
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[*] Building AFL++ fuzzing harness${NC}"

# Check if Poly/ML is built
if [ ! -f "$POLY_BIN" ]; then
    echo -e "${RED}[!] Poly/ML not found. Build it first with: ./scripts/build-polyml.sh${NC}"
    exit 1
fi

# Check if AFL++ is available
AFL_CC=""
if [ -f "${PROJECT_ROOT}/AFLplusplus/afl-clang-fast" ]; then
    AFL_CC="${PROJECT_ROOT}/AFLplusplus/afl-clang-fast"
elif command -v afl-clang-fast &> /dev/null; then
    AFL_CC="afl-clang-fast"
else
    echo -e "${RED}[!] AFL++ not found${NC}"
    exit 1
fi
echo -e "${GREEN}[*] Using: $AFL_CC${NC}"

# Build the harness
cd "$HARNESS_DIR"
echo -e "${GREEN}[*] Compiling harness with AFL++ instrumentation...${NC}"

$AFL_CC -Wall -Wextra -O2 -g \
    -fsanitize=address,undefined \
    -fno-omit-frame-pointer \
    -o harness_afl main.c \
    || { echo -e "${RED}[!] Harness compilation failed${NC}"; exit 1; }

echo -e "${GREEN}[ok] Harness built successfully: ${HARNESS_DIR}/harness_afl${NC}"
echo ""
echo -e "${YELLOW}[*] Testing harness with a simple seed...${NC}"

# Quick smoke test
TEST_SEED="$PROJECT_ROOT/seeds/basic/seed_arithmetic.sml"
if [ -f "$TEST_SEED" ]; then
    echo -e "${GREEN}[*] Running: ./harness_afl < seeds/basic/seed_arithmetic.sml${NC}"
    timeout 5 ./harness_afl < "$TEST_SEED" || true
    echo -e "${GREEN}[ok] Harness smoke test complete${NC}"
else
    echo -e "${YELLOW}[!] No test seed found, skipping smoke test${NC}"
fi

echo ""
echo -e "${GREEN}[ok] Build complete! Next step: ./scripts/verify-build.sh${NC}"
