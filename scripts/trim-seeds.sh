#!/bin/bash
# trim-seeds.sh -- Minimise large seed files using afl-tmin
#
# AFL++ works best with small inputs. This script runs afl-tmin on seeds
# larger than a size threshold, reducing them while preserving the same
# AFL++ coverage bitmap. Originals are backed up to seeds/originals/.
#
# Run this on the AWS instance (not macOS/Docker) where AFL++ is fully available
# and the instrumented poly binary is at native ARM64 speed.
#
# Usage:
#   ./scripts/trim-seeds.sh [--threshold BYTES] [--phase 1|2|all]
#
# Options:
#   --threshold BYTES   Only trim seeds larger than this (default: 1500 bytes)
#   --phase 1|2|all     Which subset to trim (default: all)
#
# Example:
#   ./scripts/trim-seeds.sh --threshold 1500 --phase all
#
# After trimming, run validate-seeds.sh to confirm no seeds are broken.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SEEDS_DIR="${PROJECT_ROOT}/seeds"
POLY="${PROJECT_ROOT}/build/polyml-instrumented/install/bin/poly"
ORIGINALS_DIR="${SEEDS_DIR}/originals"

# Add AFL++ to PATH if not already there
if [[ -d "${PROJECT_ROOT}/AFLplusplus" ]]; then
    export PATH="${PROJECT_ROOT}/AFLplusplus:${PATH}"
fi

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Defaults
THRESHOLD=1500
PHASE="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --threshold) THRESHOLD="$2"; shift 2 ;;
        --phase)     PHASE="$2";     shift 2 ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# \?//'
            exit 0 ;;
        *)
            echo -e "${RED}[!] Unknown argument: $1${NC}"; exit 1 ;;
    esac
done

# Select which seed subdirectories to process
case "$PHASE" in
    1)   DIRS=("basic" "operators" "edge-cases" "regression") ;;
    2)   DIRS=("stress" "modules" "datatypes") ;;
    all) DIRS=("basic" "operators" "edge-cases" "regression" "stress" "modules" "datatypes") ;;
    *)   echo -e "${RED}[!] --phase must be 1, 2, or all${NC}"; exit 1 ;;
esac

if [[ ! -f "$POLY" ]]; then
    echo -e "${RED}[!] Poly/ML binary not found: $POLY${NC}"
    echo -e "${YELLOW}    Build it first: ./scripts/build-polyml.sh${NC}"
    exit 1
fi

if ! command -v afl-tmin &>/dev/null; then
    echo -e "${RED}[!] afl-tmin not found in PATH${NC}"
    echo -e "${YELLOW}    Run this script on the AWS instance where AFL++ is installed${NC}"
    exit 1
fi

echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Seed Trimmer (afl-tmin)                   |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${BLUE}Threshold:${NC}  $THRESHOLD bytes"
echo -e "${BLUE}Phase:${NC}      $PHASE"
echo -e "${BLUE}Originals:${NC}  $ORIGINALS_DIR"
echo ""

# Back up originals before trimming
mkdir -p "$ORIGINALS_DIR"

TRIMMED=0
SKIPPED=0
FAILED=0

for dir in "${DIRS[@]}"; do
    SRC="${SEEDS_DIR}/${dir}"
    [[ -d "$SRC" ]] || continue

    while IFS= read -r -d '' seed; do
        SIZE=$(wc -c < "$seed")
        BASENAME="$(basename "$seed")"

        if [[ "$SIZE" -le "$THRESHOLD" ]]; then
            SKIPPED=$(( SKIPPED + 1 ))
            continue
        fi

        echo -e "${BLUE}Trimming:${NC} ${dir}/${BASENAME} (${SIZE} bytes)"

        # Back up original (skip if already backed up from a previous run)
        BACKUP="${ORIGINALS_DIR}/${dir}_${BASENAME}"
        [[ -f "$BACKUP" ]] || cp "$seed" "$BACKUP"

        # Run afl-tmin: preserve coverage bitmap while minimising file size
        # -t 15000: allow 15s per test (poly can be slow on complex inputs)
        TRIMMED_OUT="${seed}.trimmed"
        if afl-tmin -i "$seed" -o "$TRIMMED_OUT" -t 15000 -m none -- "$POLY" \
            > /dev/null 2>&1; then
            NEW_SIZE=$(wc -c < "$TRIMMED_OUT")
            SAVING=$(( SIZE - NEW_SIZE ))
            mv "$TRIMMED_OUT" "$seed"
            echo -e "  ${GREEN}[ok]${NC} ${SIZE} -> ${NEW_SIZE} bytes (saved ${SAVING} bytes)"
            TRIMMED=$(( TRIMMED + 1 ))
        else
            rm -f "$TRIMMED_OUT"
            echo -e "  ${YELLOW}[!]${NC} afl-tmin failed (keeping original)"
            FAILED=$(( FAILED + 1 ))
        fi

    done < <(find "$SRC" -maxdepth 1 -type f -name "*.sml" -print0)
done

echo ""
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Trim Summary                              |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|${NC}  Trimmed:  $TRIMMED seeds"
echo -e "${GREEN}|${NC}  Skipped:  $SKIPPED seeds (below threshold)"
echo -e "${GREEN}|${NC}  Failed:   $FAILED seeds (kept original)"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${YELLOW}Originals backed up to:${NC} $ORIGINALS_DIR"
echo -e "${YELLOW}Verify seeds still work:${NC} ./scripts/validate-seeds.sh"
