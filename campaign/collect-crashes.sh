#!/bin/bash
# Collect and deduplicate crashes from fuzzing campaign

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="${PROJECT_ROOT}/results"

# Colours
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CAMPAIGN_NAME="${1:-}"

if [ -z "$CAMPAIGN_NAME" ]; then
    echo -e "${RED}Usage: $0 <campaign-name>${NC}"
    exit 1
fi

CAMPAIGN_DIR="$RESULTS_DIR/$CAMPAIGN_NAME"
CRASHES_OUTPUT="$CAMPAIGN_DIR/collected-crashes"

if [ ! -d "$CAMPAIGN_DIR" ]; then
    echo -e "${RED}[!] Campaign not found: $CAMPAIGN_NAME${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Collecting crashes from campaign: $CAMPAIGN_NAME${NC}"

# Create output directory
mkdir -p "$CRASHES_OUTPUT"

# Collect all crashes, deduplicating by SHA-256 content hash.
# Two fuzzers may independently find the same crashing input; keeping one
# copy avoids inflated crash counts and minimisation collisions.
TOTAL_CRASHES=0
TOTAL_DUPES=0
declare -A SEEN_HASHES

for fuzzer_dir in "$CAMPAIGN_DIR"/fuzzer*/crashes; do
    if [ -d "$fuzzer_dir" ]; then
        FUZZER_NAME=$(basename "$(dirname "$fuzzer_dir")")

        for crash_file in "$fuzzer_dir"/*; do
            if [ -f "$crash_file" ] && [ "$(basename "$crash_file")" != "README.txt" ]; then
                HASH=$(sha256sum "$crash_file" | cut -d' ' -f1)
                if [ -n "${SEEN_HASHES[$HASH]+x}" ]; then
                    TOTAL_DUPES=$((TOTAL_DUPES + 1))
                else
                    SEEN_HASHES[$HASH]=1
                    CRASH_NAME=$(basename "$crash_file")
                    cp "$crash_file" "$CRASHES_OUTPUT/${FUZZER_NAME}_${CRASH_NAME}"
                    TOTAL_CRASHES=$((TOTAL_CRASHES + 1))
                fi
            fi
        done
    fi
done

echo -e "${GREEN}[*] Collected $TOTAL_CRASHES unique crash files (${TOTAL_DUPES} duplicates removed)${NC}"

# Minimise crashes using AFL++ tmin
if command -v afl-tmin &> /dev/null; then
    echo -e "${GREEN}[*] Minimising crashes...${NC}"

    MINIMISED_DIR="$CRASHES_OUTPUT/minimised"
    mkdir -p "$MINIMISED_DIR"

    # afl-tmin must use the same target that was fuzzed: poly directly (stdin-based)
    POLY="${PROJECT_ROOT}/build/polyml-instrumented/install/bin/poly"

    for crash_file in "$CRASHES_OUTPUT"/*; do
        if [ -f "$crash_file" ] && [[ ! "$crash_file" =~ /minimised/ ]]; then
            CRASH_NAME=$(basename "$crash_file")
            echo -e "${BLUE}  Minimising: $CRASH_NAME${NC}"

            timeout 60 afl-tmin \
                -i "$crash_file" \
                -o "$MINIMISED_DIR/$CRASH_NAME" \
                -- "$POLY" 2>/dev/null || {
                    echo -e "${YELLOW}    (minimisation failed or timed out, keeping original)${NC}"
                    cp "$crash_file" "$MINIMISED_DIR/$CRASH_NAME"
                }
        fi
    done

    echo -e "${GREEN}[[ok]] Minimised crashes saved to: $MINIMISED_DIR${NC}"
else
    echo -e "${YELLOW}[!] afl-tmin not found, skipping minimisation${NC}"
fi

echo ""
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  [ok] Crash collection complete               |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${BLUE}Output:${NC} $CRASHES_OUTPUT"
echo -e "${BLUE}Total:${NC}  $TOTAL_CRASHES crashes"
echo ""
echo -e "${YELLOW}Next step: ./campaign/triage.sh $CAMPAIGN_NAME${NC}"
