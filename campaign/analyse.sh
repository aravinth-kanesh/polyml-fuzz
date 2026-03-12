#!/bin/bash
# analyse.sh: Post-campaign analysis pipeline
#
# Runs the full post-campaign workflow in sequence:
#   1. collect-crashes.sh  - gather and deduplicate crash inputs from all fuzzers
#   2. triage.sh           - reproduce and classify each crash
#   3. report.sh           - generate Markdown campaign summary
#
# Usage:
#   ./campaign/analyse.sh <campaign-name>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="${PROJECT_ROOT}/results"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

CAMPAIGN_NAME="${1:-}"

if [[ -z "$CAMPAIGN_NAME" ]]; then
    echo -e "${RED}Usage: $0 <campaign-name>${NC}"
    echo ""
    echo -e "${YELLOW}Recent campaigns:${NC}"
    ls -t "$RESULTS_DIR" 2>/dev/null | grep -v "early-findings\|coverage" | head -10 || echo "  (none)"
    exit 1
fi

CAMPAIGN_DIR="${RESULTS_DIR}/${CAMPAIGN_NAME}"
if [[ ! -d "$CAMPAIGN_DIR" ]]; then
    echo -e "${RED}[!] Campaign not found: $CAMPAIGN_NAME${NC}"; exit 1
fi

echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Post-Campaign Analysis                    |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${BLUE}Campaign:${NC} $CAMPAIGN_NAME"
echo ""

echo -e "${BLUE}[1/3] Collecting and deduplicating crashes...${NC}"
"${SCRIPT_DIR}/collect-crashes.sh" "$CAMPAIGN_NAME"
echo ""

echo -e "${BLUE}[2/3] Triaging crashes...${NC}"
"${SCRIPT_DIR}/triage.sh" "$CAMPAIGN_NAME"
echo ""

echo -e "${BLUE}[3/3] Generating campaign report...${NC}"
"${SCRIPT_DIR}/report.sh" "$CAMPAIGN_NAME"
echo ""

echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  [ok] Analysis complete                    |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${BLUE}Results:${NC} $CAMPAIGN_DIR"
echo ""
echo -e "${YELLOW}Optional: generate per-file coverage report against evolved corpus:${NC}"
echo -e "  ./scripts/coverage-report.sh --evolved ${CAMPAIGN_DIR}/fuzzer01/queue"
