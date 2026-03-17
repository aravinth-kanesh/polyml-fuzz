#!/bin/bash
# fetch-isabelle-seeds.sh: Download real-world SML seeds from the Isabelle/HOL source tree
#
# Performs a shallow sparse clone of the Isabelle GitHub mirror and extracts
# .ML files (Standard ML source) into seeds/isabelle/ for use in Phase 2.
#
# These seeds provide real-world SML programs that exercise code paths
# hand-crafted seeds cannot reach, particularly in the module system and
# complex type expressions.
#
# Usage:
#   ./scripts/fetch-isabelle-seeds.sh [--count N] [--output DIR]
#
# Options:
#   --count N      Number of .ML files to extract (default: 50)
#   --output DIR   Output directory (default: seeds/isabelle)
#
# Requires: git
#
# Example:
#   ./scripts/fetch-isabelle-seeds.sh --count 50

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

TARGET_COUNT=50
OUTPUT_DIR="${PROJECT_ROOT}/seeds/isabelle"
ISABELLE_REPO="https://github.com/isabelle-mirror/isabelle"
CLONE_DIR="${PROJECT_ROOT}/build/isabelle-src"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --count)  TARGET_COUNT="$2"; shift 2 ;;
        --output) OUTPUT_DIR="$2";   shift 2 ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)
            echo -e "${RED}[!] Unknown argument: $1${NC}"; exit 1 ;;
    esac
done

echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Fetching Isabelle/HOL SML Seeds           |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""

# Check git is available
if ! command -v git &>/dev/null; then
    echo -e "${RED}[!] git not found${NC}"; exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Shallow sparse clone to avoid downloading the full Isabelle history (~1 GB)
if [[ ! -d "$CLONE_DIR/.git" ]]; then
    echo -e "${BLUE}[*] Cloning Isabelle source (shallow, src/ only)...${NC}"
    mkdir -p "$CLONE_DIR"
    git clone \
        --depth 1 \
        --filter=blob:none \
        --sparse \
        "$ISABELLE_REPO" \
        "$CLONE_DIR"
    (cd "$CLONE_DIR" && git sparse-checkout set src/Pure src/HOL src/Tools)
    echo -e "${GREEN}[ok] Clone complete${NC}"
else
    echo -e "${BLUE}[*] Isabelle source already cloned; skipping download${NC}"
fi

echo ""
echo -e "${BLUE}[*] Extracting up to ${TARGET_COUNT} .ML files...${NC}"

EXTRACTED=0
while IFS= read -r ml_file; do
    [[ $EXTRACTED -ge $TARGET_COUNT ]] && break

    base=$(basename "$ml_file")
    dest="${OUTPUT_DIR}/${base}"
    counter=1

    # Avoid name collisions
    while [[ -f "$dest" ]]; do
        dest="${OUTPUT_DIR}/${base%.ML}_${counter}.ML"
        counter=$(( counter + 1 ))
    done

    # Skip very large files (>20 KB) -- likely to timeout
    size=$(stat -c %s "$ml_file" 2>/dev/null || stat -f %z "$ml_file" 2>/dev/null || echo 0)
    if [[ "$size" -gt 20480 ]]; then
        continue
    fi

    cp "$ml_file" "$dest"
    EXTRACTED=$(( EXTRACTED + 1 ))
done < <(find "$CLONE_DIR" -name "*.ML" -type f | sort)

echo -e "${GREEN}[ok] Extracted ${EXTRACTED} Isabelle seeds -> ${OUTPUT_DIR}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Validate seeds: ./scripts/validate-seeds.sh"
echo -e "  2. Seeds/isabelle/ will be included automatically in Phase 2"
