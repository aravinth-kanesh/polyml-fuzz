#!/bin/bash
# Setup script for AWS EC2 Graviton instance (ARM64)

set -euo pipefail

# Colours
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Poly/ML Fuzzing - EC2 Setup (ARM64)       |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""

# Check architecture
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    echo -e "${RED}[!] This script is for ARM64 architecture${NC}"
    echo -e "${RED}    Current architecture: $ARCH${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Detected ARM64 architecture: $ARCH${NC}"
echo ""

# Update system
echo -e "${BLUE}[1/6] Updating system packages...${NC}"
sudo apt-get update
sudo apt-get upgrade -y

# Install build dependencies
echo -e "${BLUE}[2/6] Installing build tools...${NC}"
sudo apt-get install -y \
    build-essential \
    clang-15 \
    llvm-15 \
    git \
    wget \
    autoconf \
    automake \
    libtool \
    libgmp-dev \
    tmux \
    htop

# Install AFL++
echo -e "${BLUE}[3/6] Installing AFL++...${NC}"
if [ ! -d "AFLplusplus" ]; then
    git clone https://github.com/AFLplusplus/AFLplusplus
    cd AFLplusplus
    make -j$(nproc)
    sudo make install
    cd ..
else
    echo -e "${YELLOW}    AFL++ directory already exists, skipping${NC}"
fi

# Clone Poly/ML if needed
echo -e "${BLUE}[4/6] Checking for Poly/ML source...${NC}"
if [ ! -d "polyml-src" ]; then
    echo -e "${GREEN}    Cloning Poly/ML repository...${NC}"
    git clone https://github.com/polyml/polyml.git polyml-src
else
    echo -e "${YELLOW}    Poly/ML source already exists${NC}"
fi

# Disable CPU frequency scaling (important for fuzzing performance)
echo -e "${BLUE}[5/6] Configuring CPU for fuzzing...${NC}"
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor || {
    echo -e "${YELLOW}    Could not set CPU governor (may not be available on this instance)${NC}"
}

# Increase file descriptor limits
echo -e "${BLUE}[6/6] Increasing file descriptor limits...${NC}"
sudo tee -a /etc/security/limits.conf > /dev/null << EOF
* soft nofile 65536
* hard nofile 65536
EOF

echo ""
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  [ok] EC2 setup complete!                  |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. ${BLUE}Build Poly/ML:${NC}"
echo -e "     ./scripts/build-polyml.sh"
echo ""
echo -e "  2. ${BLUE}Build harness:${NC}"
echo -e "     ./scripts/build-harness.sh"
echo ""
echo -e "  3. ${BLUE}Verify setup:${NC}"
echo -e "     ./scripts/verify-build.sh"
echo ""
echo -e "  4. ${BLUE}Validate seeds:${NC}"
echo -e "     ./scripts/validate-seeds.sh"
echo ""
echo -e "  5. ${BLUE}Launch campaign:${NC}"
echo -e "     ./campaign/launch.sh --phase 1 --duration 259200 --instances 4"
echo ""
echo -e "${YELLOW}Consider running in tmux for long campaigns:${NC}"
echo -e "  tmux new -s fuzzing"
echo -e "  ./campaign/launch.sh --phase 1 --duration 259200 --instances 4"
echo -e "  # Detach with: Ctrl+B, then D"
