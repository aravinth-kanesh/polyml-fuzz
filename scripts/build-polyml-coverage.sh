#!/bin/bash
# Build Poly/ML with LLVM source coverage instrumentation
#
# Produces a separate poly binary at build/polyml-coverage/install/bin/poly
# instrumented with -fprofile-instr-generate -fcoverage-mapping.
# This build is NOT used for fuzzing. It exists solely to generate
# per-file coverage reports via coverage-report.sh.
#
# Usage:
#   ./scripts/build-polyml-coverage.sh
#
# Output:
#   build/polyml-coverage/install/bin/poly

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
POLYML_SRC="${PROJECT_ROOT}/polyml-src"
BUILD_DIR="${PROJECT_ROOT}/build/polyml-coverage"

# Add Homebrew LLVM to PATH on macOS (provides llvm-cov, llvm-profdata, clang)
if [ -d "/opt/homebrew/opt/llvm/bin" ]; then
    export PATH="/opt/homebrew/opt/llvm/bin:$PATH"
elif [ -d "/usr/local/opt/llvm/bin" ]; then
    export PATH="/usr/local/opt/llvm/bin:$PATH"
fi

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[*] Building coverage-instrumented Poly/ML${NC}"
echo -e "${YELLOW}    This build is for coverage analysis only, not fuzzing${NC}"
echo ""

# Check Poly/ML source exists
if [ ! -d "$POLYML_SRC" ]; then
    echo -e "${RED}[!] Poly/ML source not found at: $POLYML_SRC${NC}"
    echo -e "${YELLOW}    Clone with: git clone https://github.com/polyml/polyml.git polyml-src${NC}"
    exit 1
fi

# Find a suitable clang and matching llvm tools
# Try versioned clang first (matches what ec2-setup.sh installs), then unversioned
CC_BIN=""
CXX_BIN=""
LLVM_PROFDATA_BIN=""
LLVM_COV_BIN=""

for ver in "-15" "-14" "-13" ""; do
    if command -v "clang${ver}" &>/dev/null; then
        CC_BIN="clang${ver}"
        CXX_BIN="clang++${ver}"
        LLVM_PROFDATA_BIN="llvm-profdata${ver}"
        LLVM_COV_BIN="llvm-cov${ver}"
        break
    fi
done

if [ -z "$CC_BIN" ]; then
    echo -e "${RED}[!] No clang found. Install clang (Ubuntu: sudo apt install clang-15 llvm-15)${NC}"
    exit 1
fi

if ! command -v "$LLVM_PROFDATA_BIN" &>/dev/null; then
    echo -e "${RED}[!] $LLVM_PROFDATA_BIN not found. Install llvm tools alongside clang.${NC}"
    exit 1
fi

if ! command -v "$LLVM_COV_BIN" &>/dev/null; then
    echo -e "${RED}[!] $LLVM_COV_BIN not found. Install llvm tools alongside clang.${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Compiler:     $CC_BIN ($(${CC_BIN} --version | head -1))${NC}"
echo -e "${GREEN}[*] llvm-profdata: $LLVM_PROFDATA_BIN${NC}"
echo -e "${GREEN}[*] llvm-cov:      $LLVM_COV_BIN${NC}"
echo ""

# Clean and prepare build directory
echo -e "${GREEN}[*] Preparing build directory: $BUILD_DIR${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Run autoreconf on Poly/ML source
cd "$POLYML_SRC"
echo -e "${GREEN}[*] Running autoreconf...${NC}"
autoreconf -fi || { echo -e "${RED}[!] autoreconf failed${NC}"; exit 1; }

# Configure with coverage flags
# -O1 rather than -O2: reduces inlining so coverage data maps more cleanly to source lines
# No sanitisers: same reason as instrumented build (bootstrap issues)
cd "$BUILD_DIR"
echo -e "${GREEN}[*] Configuring with coverage instrumentation...${NC}"

export CC="$CC_BIN"
export CXX="$CXX_BIN"
export CFLAGS="-O1 -g -fprofile-instr-generate -fcoverage-mapping -fno-omit-frame-pointer"
export CXXFLAGS="-O1 -g -fprofile-instr-generate -fcoverage-mapping -fno-omit-frame-pointer"
export LDFLAGS="-fprofile-instr-generate"

"$POLYML_SRC/configure" \
    --prefix="$BUILD_DIR/install" \
    --disable-shared \
    --enable-static \
    || { echo -e "${RED}[!] Configure failed${NC}"; exit 1; }

# Build
echo -e "${GREEN}[*] Building Poly/ML (this may take several minutes)...${NC}"
if command -v nproc &>/dev/null; then
    NPROC=$(nproc)
else
    NPROC=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
fi
make -j"$NPROC" || { echo -e "${RED}[!] Build failed${NC}"; exit 1; }
make install    || { echo -e "${RED}[!] Install failed${NC}"; exit 1; }

POLY_BIN="$BUILD_DIR/install/bin/poly"
if [ ! -f "$POLY_BIN" ]; then
    echo -e "${RED}[!] poly binary not found after build${NC}"
    exit 1
fi

# Sanity check: confirm the binary emits profraw data when run
echo -e "${GREEN}[*] Sanity check: confirming coverage data is emitted...${NC}"
SANITY_PROFRAW=$(mktemp /tmp/sanity_XXXXXX.profraw)
echo 'val _ = 1;' | LLVM_PROFILE_FILE="$SANITY_PROFRAW" "$POLY_BIN" >/dev/null 2>&1 || true
if [ ! -s "$SANITY_PROFRAW" ]; then
    echo -e "${RED}[!] Coverage profraw not generated. Instrumentation may not be working.${NC}"
    rm -f "$SANITY_PROFRAW"
    exit 1
fi
rm -f "$SANITY_PROFRAW"
echo -e "${GREEN}[ok] Coverage instrumentation confirmed active${NC}"

echo ""
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  [ok] Coverage build complete              |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${YELLOW}Binary:${NC} $POLY_BIN"
echo ""
echo -e "${YELLOW}Next step: generate coverage report${NC}"
echo -e "  ./scripts/coverage-report.sh"
echo -e "  ./scripts/coverage-report.sh --evolved results/<campaign>/fuzzer01/queue"
