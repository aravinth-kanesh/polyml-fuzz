#!/bin/bash
# Build Poly/ML with AFL++ instrumentation and sanitisers

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
POLYML_SRC="${PROJECT_ROOT}/polyml-src"
BUILD_DIR="${PROJECT_ROOT}/build/polyml-instrumented"

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

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No colour

echo -e "${GREEN}[*] Building instrumented Poly/ML for fuzzing${NC}"

# Check if Poly/ML source exists
if [ ! -d "$POLYML_SRC" ]; then
    echo -e "${RED}[!] Poly/ML source not found at: $POLYML_SRC${NC}"
    echo -e "${YELLOW}[!] Clone with: git clone https://github.com/polyml/polyml.git polyml-src${NC}"
    exit 1
fi

# Check if AFL++ compilers are available
AFL_CC=""
AFL_CXX=""

# Try afl-clang-lto first (best), then afl-clang-fast (works on macOS)
if command -v afl-clang-lto &> /dev/null; then
    AFL_CC="afl-clang-lto"
    AFL_CXX="afl-clang-lto++"
    echo -e "${GREEN}[*] Using afl-clang-lto (LTO mode)${NC}"
elif [ -f "${PROJECT_ROOT}/AFLplusplus/afl-clang-fast" ]; then
    AFL_CC="${PROJECT_ROOT}/AFLplusplus/afl-clang-fast"
    AFL_CXX="${PROJECT_ROOT}/AFLplusplus/afl-clang-fast++"
    echo -e "${GREEN}[*] Using afl-clang-fast from local AFLplusplus/${NC}"
elif command -v afl-clang-fast &> /dev/null; then
    AFL_CC="afl-clang-fast"
    AFL_CXX="afl-clang-fast++"
    echo -e "${GREEN}[*] Using afl-clang-fast${NC}"
else
    echo -e "${RED}[!] No AFL++ compiler found.${NC}"
    echo -e "${YELLOW}[!] Build AFL++ first: cd AFLplusplus && make${NC}"
    exit 1
fi

# Clean and prepare build directory
echo -e "${GREEN}[*] Preparing build directory: $BUILD_DIR${NC}"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Configure Poly/ML with AFL++ instrumentation
cd "$POLYML_SRC"
echo -e "${GREEN}[*] Running autoreconf...${NC}"
autoreconf -fi || { echo -e "${RED}[!] autoreconf failed${NC}"; exit 1; }

cd "$BUILD_DIR"
echo -e "${GREEN}[*] Configuring Poly/ML with AFL++ and sanitisers...${NC}"

# AFL++ flags (sanitisers added at runtime via AFL_USE_ASAN)
export CC="$AFL_CC"
export CXX="$AFL_CXX"

# Build with just AFL++ instrumentation (no compile-time sanitisers)
# This avoids bootstrap issues where sanitisers trigger during polyimport
# Sanitizers can be enabled at runtime with AFL_PRELOAD or ASAN_OPTIONS
export CFLAGS="-O2 -g -fno-omit-frame-pointer"
export CXXFLAGS="-O2 -g -fno-omit-frame-pointer"
export LDFLAGS=""

echo -e "${YELLOW}[*] Note: Building without compile-time sanitisers to avoid bootstrap issues${NC}"
echo -e "${YELLOW}[*] For sanitiser support, use the existing polyml-asan build or enable at runtime${NC}"

"$POLYML_SRC/configure" \
    --prefix="$BUILD_DIR/install" \
    --disable-shared \
    --enable-static \
    || { echo -e "${RED}[!] Configure failed${NC}"; exit 1; }

# Build Poly/ML
echo -e "${GREEN}[*] Building Poly/ML (this may take several minutes)...${NC}"
# Use nproc on Linux, sysctl on macOS
if command -v nproc &> /dev/null; then
    NPROC=$(nproc)
else
    NPROC=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
fi
make -j$NPROC || { echo -e "${RED}[!] Build failed${NC}"; exit 1; }

# Install to build directory
echo -e "${GREEN}[*] Installing Poly/ML...${NC}"
make install || { echo -e "${RED}[!] Install failed${NC}"; exit 1; }

# Verify the build
POLY_BIN="$BUILD_DIR/install/bin/poly"
if [ ! -f "$POLY_BIN" ]; then
    echo -e "${RED}[!] Poly/ML binary not found after build${NC}"
    exit 1
fi

echo -e "${GREEN}[ok] Poly/ML built successfully!${NC}"
echo -e "${GREEN}[ok] Binary location: $POLY_BIN${NC}"
echo ""
echo -e "${YELLOW}[*] Verifying instrumentation...${NC}"

# Quick smoke test
echo 'val _ = print "Hello from instrumented Poly/ML\n";' | "$POLY_BIN" 2>&1 | head -5

echo ""
echo -e "${GREEN}[ok] Build complete! Next steps:${NC}"
echo -e "    1. Build harness: ./scripts/build-harness.sh"
echo -e "    2. Verify setup: ./scripts/verify-build.sh"
echo -e "    3. Validate seeds: ./scripts/validate-seeds.sh"
