#!/bin/bash
# setup.sh: One-command setup from a fresh clone to ready-to-fuzz
#
# Installs system dependencies (Linux ARM64), builds AFL++, clones Poly/ML
# source, builds the instrumented poly binary, then verifies and validates.
# Safe to re-run: each step is skipped if already complete.
#
# Usage:
#   ./setup.sh           # full setup
#   ./setup.sh --verify  # verify an existing setup only (no builds)
#
# After setup completes, run:
#   ./fuzz.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

POLY_BIN="${SCRIPT_DIR}/build/polyml-instrumented/install/bin/poly"
AFL_BIN="${SCRIPT_DIR}/AFLplusplus/afl-fuzz"
POLYML_SRC="${SCRIPT_DIR}/polyml-src"

echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Poly/ML Fuzzing Framework Setup           |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""

# --verify: just run verify-build.sh and exit
if [[ "${1:-}" == "--verify" ]]; then
    exec "${SCRIPT_DIR}/scripts/verify-build.sh"
fi

OS=$(uname -s)
ARCH=$(uname -m)

# -------------------------------------------------------
# Step 1: System dependencies, AFL++, and Poly/ML source
# -------------------------------------------------------
echo -e "${BLUE}[1/4] System dependencies and tools${NC}"

if [[ "$OS" == "Linux" ]]; then
    if [[ "$ARCH" != "aarch64" && "$ARCH" != "arm64" ]]; then
        echo -e "${RED}[!] This framework targets ARM64. Detected: ${ARCH}${NC}"
        exit 1
    fi

    # Skip if clang-15, AFL++, and polyml-src are already present
    if command -v clang-15 &>/dev/null && [[ -f "$AFL_BIN" ]] && [[ -d "$POLYML_SRC" ]]; then
        echo -e "${YELLOW}  [skip] clang-15, AFL++, and Poly/ML source already present${NC}"
    else
        echo "  Running ec2-setup.sh (installs packages, AFL++, Poly/ML source)..."
        echo ""
        "${SCRIPT_DIR}/scripts/ec2-setup.sh"
    fi

elif [[ "$OS" == "Darwin" ]]; then
    # macOS: AFL++ and polyml-src must already exist (set up manually or via Homebrew)
    echo -e "${YELLOW}  [skip] macOS detected - system packages not managed by this script${NC}"

    if [[ ! -f "$AFL_BIN" ]] && ! command -v afl-fuzz &>/dev/null; then
        echo -e "${RED}  [!] AFL++ not found.${NC}"
        echo -e "      Clone and build: git clone https://github.com/AFLplusplus/AFLplusplus AFLplusplus && make -C AFLplusplus"
        exit 1
    fi

    if [[ ! -d "$POLYML_SRC" ]]; then
        echo -e "${RED}  [!] Poly/ML source not found.${NC}"
        echo -e "      Clone it: git clone https://github.com/polyml/polyml.git polyml-src"
        exit 1
    fi

    echo -e "${GREEN}  [ok] AFL++ and Poly/ML source found${NC}"
else
    echo -e "${RED}[!] Unsupported platform: ${OS} ${ARCH}${NC}"
    exit 1
fi

# -------------------------------------------------------
# Step 2: Build instrumented Poly/ML binary
# -------------------------------------------------------
echo ""
echo -e "${BLUE}[2/4] Instrumented Poly/ML binary${NC}"

if [[ -f "$POLY_BIN" ]]; then
    echo -e "${YELLOW}  [skip] poly binary already present at build/polyml-instrumented/${NC}"
else
    echo "  Building instrumented Poly/ML (this takes several minutes)..."
    echo ""
    "${SCRIPT_DIR}/scripts/build-polyml.sh"
fi

# -------------------------------------------------------
# Step 3: Verify build
# -------------------------------------------------------
echo ""
echo -e "${BLUE}[3/4] Verifying build${NC}"
echo ""
"${SCRIPT_DIR}/scripts/verify-build.sh"

# -------------------------------------------------------
# Step 4: Validate seed corpus
# -------------------------------------------------------
echo ""
echo -e "${BLUE}[4/4] Validating seed corpus${NC}"
echo ""
"${SCRIPT_DIR}/scripts/validate-seeds.sh"

echo ""
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Setup complete. Ready to fuzz.            |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "  Run: ${BLUE}./fuzz.sh${NC}"
echo ""
