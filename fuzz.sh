#!/bin/bash
# fuzz.sh: Interactive wizard for launching a Poly/ML fuzzing campaign
#
# Guides you through phase, duration, instance count, and evolved seed
# configuration, then calls campaign/start.sh to launch everything in tmux.
#
# Usage:
#   ./fuzz.sh               # interactive prompts
#   ./fuzz.sh --defaults    # accept all defaults without prompting (Phase 1, 3 days, 2 instances)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

USE_DEFAULTS=0
[[ "${1:-}" == "--defaults" ]] && USE_DEFAULTS=1

ask() {
    local msg="$1" default="$2"
    if [[ "$USE_DEFAULTS" -eq 1 ]]; then echo "$default"; return; fi
    echo -en "${BLUE}${msg}${NC} [default: ${default}]: " >&2
    read -r value
    echo "${value:-$default}"
}

confirm() {
    local msg="$1"
    if [[ "$USE_DEFAULTS" -eq 1 ]]; then return 0; fi
    echo -en "${YELLOW}${msg} [y/N]: ${NC}" >&2
    read -r ans
    [[ "${ans,,}" == "y" ]]
}

echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Poly/ML Fuzzing Framework                 |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""

# Phase selection
echo -e "${BLUE}Select phase:${NC}"
echo -e "  1) Phase 1: Lexer  (basic, operators, edge-cases, regression)"
echo -e "  2) Phase 2: Parser (stress, modules, datatypes)"
echo ""

if [[ "$USE_DEFAULTS" -eq 1 ]]; then
    PHASE="1"
else
    read -rp "Phase [1/2, default 1]: " PHASE_INPUT
    PHASE="${PHASE_INPUT:-1}"
fi

if [[ "$PHASE" != "1" && "$PHASE" != "2" ]]; then
    echo -e "${RED}[!] Invalid phase. Must be 1 or 2.${NC}"; exit 1
fi

# Duration
echo ""
echo -e "${BLUE}Campaign duration:${NC}"
echo -e "  Smoke test : 1800 seconds (30 min)"
echo -e "  Short      : 86400 seconds (1 day)"
echo -e "  Full       : 259200 seconds (3 days)"
echo ""
DURATION=$(ask "Duration in seconds" "259200")

# Instance count
echo ""
INSTANCES=$(ask "Number of fuzzer instances" "2")

# Evolved seeds (Phase 2 only)
EVOLVED_ARG=""
if [[ "$PHASE" == "2" ]]; then
    echo ""
    echo -e "${BLUE}Evolved seeds from Phase 1 (recommended for Phase 2):${NC}"
    echo -e "  Recent Phase 1 campaigns:"
    ls -t "${SCRIPT_DIR}/results/" 2>/dev/null | grep "phase1" | head -5 | sed 's/^/    /' || echo "    (none found)"
    echo ""
    if [[ "$USE_DEFAULTS" -eq 0 ]]; then
        read -rp "Phase 1 campaign name [blank to skip]: " EVOLVED_INPUT
        if [[ -n "${EVOLVED_INPUT:-}" ]]; then
            EVOLVED_ARG="--evolved ${EVOLVED_INPUT}"
        fi
    fi
fi

# Summary
echo ""
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}  Campaign configuration                      ${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo -e "  Phase:     $PHASE"
echo -e "  Duration:  $DURATION seconds ($(( DURATION / 3600 )) hours $(( (DURATION % 3600) / 60 )) min)"
echo -e "  Instances: $INSTANCES"
[[ -n "$EVOLVED_ARG" ]] && echo -e "  Evolved:   $EVOLVED_ARG"
echo ""

if ! confirm "Launch campaign?"; then
    echo -e "${YELLOW}Aborted.${NC}"; exit 0
fi

echo ""

# shellcheck disable=SC2086
exec "${SCRIPT_DIR}/campaign/start.sh" \
    --phase "$PHASE" \
    --duration "$DURATION" \
    --instances "$INSTANCES" \
    $EVOLVED_ARG
