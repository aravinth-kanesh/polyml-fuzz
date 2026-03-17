#!/bin/bash
# fuzz.sh: Interactive wizard for launching a Poly/ML fuzzing campaign
#
# Guides you through phase, duration, instance count, and evolved seed
# configuration, then calls campaign/start.sh to launch everything in tmux.
#
# Usage:
#   ./fuzz.sh               # interactive prompts
#   ./fuzz.sh --defaults    # accept all defaults without prompting (Phase 1, 3 days, 4 instances)

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
echo -e "${BLUE}Fuzzer instances:${NC}"
CPU_COUNT=$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo "?")
echo -e "  CPU cores available: ${CPU_COUNT} (recommended: 1 instance per core)"
INSTANCES=$(ask "Number of instances" "4")

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

PHASE_LABEL=$([[ "$PHASE" == "1" ]] && echo "Lexer: basic, operators, edge-cases, regression" || echo "Parser: stress, modules, datatypes")

# Summary
echo ""
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}  Campaign configuration                      ${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo -e "  Phase:     $PHASE ($PHASE_LABEL)"
echo -e "  Duration:  $DURATION seconds ($(( DURATION / 3600 )) hours $(( (DURATION % 3600) / 60 )) min)"
echo -e "  Instances: $INSTANCES"
[[ -n "$EVOLVED_ARG" ]] && echo -e "  Evolved:   ${EVOLVED_ARG#--evolved }"
echo ""

if ! confirm "Launch campaign?"; then
    echo -e "${YELLOW}Aborted.${NC}"; exit 0
fi

echo ""

# Run the campaign (blocks until the tmux session ends and analysis completes)
# shellcheck disable=SC2086
"${SCRIPT_DIR}/campaign/start.sh" \
    --phase "$PHASE" \
    --duration "$DURATION" \
    --instances "$INSTANCES" \
    $EVOLVED_ARG

# Phase 1 -> Phase 2 handoff
if [[ "$PHASE" == "1" ]]; then
    PHASE1_CAMPAIGN=""
    if [[ -f "${SCRIPT_DIR}/results/.last-campaign" ]]; then
        PHASE1_CAMPAIGN=$(cat "${SCRIPT_DIR}/results/.last-campaign")
    fi

    if [[ -n "$PHASE1_CAMPAIGN" ]]; then
        echo ""
        echo -e "${GREEN}+============================================+${NC}"
        echo -e "${GREEN}  Phase 1 complete                            ${NC}"
        echo -e "${GREEN}+============================================+${NC}"
        echo -e "  Campaign: ${BLUE}${PHASE1_CAMPAIGN}${NC}"
        echo ""
        if confirm "Launch Phase 2 (parser corpus) with evolved seeds from Phase 1?"; then
            echo ""

            # Optional: minimise evolved corpus with afl-cmin before Phase 2
            EVOLVED_DIR="${SCRIPT_DIR}/seeds/evolved"
            POLY="${SCRIPT_DIR}/build/polyml-instrumented/install/bin/poly"
            if confirm "Run afl-cmin to minimise evolved corpus before Phase 2? (recommended; improves throughput)"; then
                CMIN_OUT="${SCRIPT_DIR}/seeds/evolved-cmin"
                echo -e "${BLUE}[*] Running afl-cmin on evolved corpus...${NC}"
                mkdir -p "$CMIN_OUT"
                if afl-cmin -i "$EVOLVED_DIR" -o "$CMIN_OUT" -- "$POLY" > /dev/null 2>&1; then
                    BEFORE=$(find "$EVOLVED_DIR" -maxdepth 1 -type f | wc -l | tr -d ' ')
                    AFTER=$(find "$CMIN_OUT" -maxdepth 1 -type f | wc -l | tr -d ' ')
                    echo -e "${GREEN}[ok] Corpus minimised: ${BEFORE} -> ${AFTER} seeds${NC}"
                    # Swap in the minimised corpus
                    mv "$EVOLVED_DIR" "${EVOLVED_DIR}-pre-cmin"
                    mv "$CMIN_OUT" "$EVOLVED_DIR"
                else
                    echo -e "${YELLOW}[!] afl-cmin failed; using original evolved corpus${NC}"
                    rm -rf "$CMIN_OUT"
                fi
                echo ""
            fi

            DURATION2=$(ask "Phase 2 duration in seconds" "$DURATION")
            echo ""
            # shellcheck disable=SC2086
            exec "${SCRIPT_DIR}/campaign/start.sh" \
                --phase 2 \
                --duration "$DURATION2" \
                --instances "$INSTANCES" \
                --evolved "$PHASE1_CAMPAIGN"
        else
            echo -e "${YELLOW}Phase 2 skipped. To run later:${NC}"
            echo -e "  ./fuzz.sh  (select Phase 2, use evolved: ${PHASE1_CAMPAIGN})"
        fi
    fi
fi

echo -e "${GREEN}Done.${NC}"
