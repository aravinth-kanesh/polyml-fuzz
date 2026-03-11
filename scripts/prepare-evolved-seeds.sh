#!/bin/bash
# prepare-evolved-seeds.sh: Extract interesting evolved inputs from a trial campaign
#
# After a trial campaign, AFL++ has evolved the seed corpus into hundreds of
# interesting inputs. This script copies the best ones into seeds/evolved/ so
# the real campaign can use them as additional starting seeds via --use-evolved.
#
# Only the main fuzzer's queue is used (fuzzer01) to avoid duplicates.
# Files are renamed to avoid collisions with the original seeds.
#
# Usage:
#   ./scripts/prepare-evolved-seeds.sh <campaign-name>
#   ./scripts/prepare-evolved-seeds.sh phase1-lexer-trial-2
#
# After running, launch the real campaign with:
#   ./campaign/launch.sh --phase 1 --duration 259200 --instances 2 --use-evolved
#
# To clear the evolved seeds dir and start fresh:
#   rm -rf seeds/evolved/ && mkdir seeds/evolved/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

if [[ $# -lt 1 ]]; then
    echo -e "${RED}[!] Usage: $0 <campaign-name>${NC}"
    echo -e "    Example: $0 phase1-lexer-trial-2"
    exit 1
fi

CAMPAIGN_NAME="$1"
CAMPAIGN_DIR="${PROJECT_ROOT}/results/${CAMPAIGN_NAME}"
QUEUE_DIR="${CAMPAIGN_DIR}/fuzzer01/queue"
EVOLVED_DIR="${PROJECT_ROOT}/seeds/evolved"

if [[ ! -d "$CAMPAIGN_DIR" ]]; then
    echo -e "${RED}[!] Campaign directory not found: $CAMPAIGN_DIR${NC}"
    exit 1
fi

if [[ ! -d "$QUEUE_DIR" ]]; then
    echo -e "${RED}[!] Queue directory not found: $QUEUE_DIR${NC}"
    echo -e "    Has the campaign run and completed?"
    exit 1
fi

# Count available queue entries (excluding the .state/ directory)
QUEUE_COUNT=$(find "$QUEUE_DIR" -maxdepth 1 -type f | wc -l | tr -d ' ')

echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Prepare Evolved Seeds                     |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${BLUE}Campaign:${NC}    $CAMPAIGN_NAME"
echo -e "${BLUE}Queue dir:${NC}   $QUEUE_DIR"
echo -e "${BLUE}Queue size:${NC}  $QUEUE_COUNT entries"
echo -e "${BLUE}Output:${NC}      $EVOLVED_DIR"
echo ""

mkdir -p "$EVOLVED_DIR"

# Copy queue entries, prefixed with campaign name to avoid collisions
COPIED=0
while IFS= read -r -d '' f; do
    BASENAME="$(basename "$f")"
    DEST="${EVOLVED_DIR}/${CAMPAIGN_NAME}_${BASENAME}"
    cp "$f" "$DEST"
    COPIED=$(( COPIED + 1 ))
done < <(find "$QUEUE_DIR" -maxdepth 1 -type f -print0)

echo -e "${GREEN}[ok]${NC} Copied $COPIED evolved inputs -> seeds/evolved/"
echo ""
echo -e "${YELLOW}To use in the real campaign:${NC}"
echo -e "  ./campaign/launch.sh --phase 1 --duration 259200 --instances 2 --use-evolved"
echo ""
echo -e "${YELLOW}To clear evolved seeds and start fresh:${NC}"
echo -e "  rm -rf seeds/evolved/ && mkdir seeds/evolved/"
