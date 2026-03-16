#!/bin/bash
# triage-hangs.sh: Collect, deduplicate, and classify AFL++ hang inputs
#
# Gathers hang inputs from all fuzzer instances, deduplicates by SHA-256,
# then reproduces each under a 15-second timeout. Each hang is classified as:
#   ConfirmedHang  - consistently times out (genuine infinite loop or very slow path)
#   HangThenCrash  - hang input triggers a crash on reproduction (interesting!)
#   NotReproduced  - completes within timeout on re-run (transient / environment noise)
#
# A summary file is written for each hang to results/<campaign>/triaged-hangs/.
#
# Usage:
#   ./campaign/triage-hangs.sh <campaign-name> [--quiet]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="${PROJECT_ROOT}/results"
POLY_BIN="${PROJECT_ROOT}/build/polyml-instrumented/install/bin/poly"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

CAMPAIGN_NAME="${1:-}"
QUIET=0
for arg in "$@"; do [[ "$arg" == "--quiet" ]] && QUIET=1; done

if [[ -z "$CAMPAIGN_NAME" ]]; then
    echo -e "${RED}Usage: $0 <campaign-name> [--quiet]${NC}"
    exit 1
fi

CAMPAIGN_DIR="$RESULTS_DIR/$CAMPAIGN_NAME"
HANG_COLLECT_DIR="$CAMPAIGN_DIR/collected-hangs"
HANG_TRIAGE_DIR="$CAMPAIGN_DIR/triaged-hangs"

if [[ ! -d "$CAMPAIGN_DIR" ]]; then
    echo -e "${RED}[!] Campaign not found: $CAMPAIGN_NAME${NC}"; exit 1
fi

if [[ ! -f "$POLY_BIN" ]]; then
    echo -e "${RED}[!] Poly/ML binary not found: $POLY_BIN${NC}"; exit 1
fi

# ------------------------------------------------------------------
# Step 1: Collect and deduplicate hang inputs from all fuzzer instances
# ------------------------------------------------------------------
mkdir -p "$HANG_COLLECT_DIR"

TOTAL_FOUND=0
TOTAL_UNIQUE=0
declare -A SEEN_HASHES

for fuzzer_dir in "$CAMPAIGN_DIR"/fuzzer*/; do
    [[ ! -d "$fuzzer_dir" ]] && continue
    hang_dir="${fuzzer_dir}hangs"
    [[ ! -d "$hang_dir" ]] && continue
    for hang_file in "$hang_dir"/id:*; do
        [[ ! -f "$hang_file" ]] && continue
        TOTAL_FOUND=$(( TOTAL_FOUND + 1 ))
        HASH=$(sha256sum "$hang_file" | cut -d' ' -f1)
        if [[ -z "${SEEN_HASHES[$HASH]:-}" ]]; then
            SEEN_HASHES[$HASH]=1
            cp "$hang_file" "$HANG_COLLECT_DIR/hang-${HASH:0:16}"
            TOTAL_UNIQUE=$(( TOTAL_UNIQUE + 1 ))
        fi
    done
done

if [[ $TOTAL_UNIQUE -eq 0 ]]; then
    if [[ $QUIET -eq 1 ]]; then
        echo -e "${GREEN}  [ok] Hang triage: 0 hangs${NC}"
    else
        echo -e "${GREEN}[ok] No hang inputs found in $CAMPAIGN_NAME${NC}"
    fi
    exit 0
fi

[[ $QUIET -eq 0 ]] && echo -e "${GREEN}[*] Found $TOTAL_UNIQUE unique hang(s) ($TOTAL_FOUND total across fuzzers)${NC}"

# ------------------------------------------------------------------
# Step 2: Reproduce and classify each unique hang
# ------------------------------------------------------------------
mkdir -p "$HANG_TRIAGE_DIR"

CONFIRMED=0
HANG_THEN_CRASH=0
NOT_REPRODUCED=0
HANG_COUNT=0

for hang_file in "$HANG_COLLECT_DIR"/hang-*; do
    [[ ! -f "$hang_file" ]] && continue
    HANG_COUNT=$(( HANG_COUNT + 1 ))
    HANG_NAME=$(basename "$hang_file")

    [[ $QUIET -eq 0 ]] && echo -e "${BLUE}[$HANG_COUNT] Reproducing: $HANG_NAME${NC}"

    LOG_FILE="$HANG_TRIAGE_DIR/${HANG_NAME}.log"

    # Run with 15s timeout; send SIGABRT on expiry so sanitisers print a stack trace
    set +e
    timeout --signal=ABRT 15 \
        env ASAN_OPTIONS=halt_on_error=1:abort_on_error=1 \
            UBSAN_OPTIONS=print_stacktrace=1 \
        "$POLY_BIN" < "$hang_file" > /dev/null 2> "$LOG_FILE"
    EXIT_CODE=$?
    set -e

    LOCATION="unknown"

    if [[ $EXIT_CODE -eq 0 ]]; then
        # Completed within timeout - not a genuine hang
        NOT_REPRODUCED=$(( NOT_REPRODUCED + 1 ))
        HANG_TYPE="NotReproduced"
        [[ $QUIET -eq 0 ]] && echo -e "${YELLOW}    -> Completed within timeout (transient / not reproduced)${NC}"
    elif [[ $EXIT_CODE -eq 134 ]] || [[ $EXIT_CODE -eq 124 ]]; then
        # 134 = SIGABRT (our timeout signal), 124 = plain timeout
        # Check if the abort was from a sanitiser rather than our kill
        if grep -q "runtime error\|heap-buffer-overflow\|use-after-free\|stack-buffer-overflow" "$LOG_FILE" 2>/dev/null; then
            HANG_THEN_CRASH=$(( HANG_THEN_CRASH + 1 ))
            HANG_TYPE="HangThenCrash"
            [[ $QUIET -eq 0 ]] && echo -e "${RED}    -> Hang input triggered sanitiser error on reproduction${NC}"
        else
            CONFIRMED=$(( CONFIRMED + 1 ))
            HANG_TYPE="ConfirmedHang"
            [[ $QUIET -eq 0 ]] && echo -e "${RED}    -> Confirmed hang: consistently times out${NC}"
        fi
        LOCATION=$(grep -m 1 "#0" "$LOG_FILE" 2>/dev/null | sed 's/.*in //' | sed 's/ .*//' || echo "unknown")
        [[ $QUIET -eq 0 ]] && echo -e "${BLUE}    Location: $LOCATION${NC}"
    else
        # Unexpected non-zero exit (crash without sanitiser output)
        HANG_THEN_CRASH=$(( HANG_THEN_CRASH + 1 ))
        HANG_TYPE="HangThenCrash"
        [[ $QUIET -eq 0 ]] && echo -e "${RED}    -> Hang input crashed on reproduction (exit $EXIT_CODE)${NC}"
        LOCATION=$(grep -m 1 "#0" "$LOG_FILE" 2>/dev/null | sed 's/.*in //' | sed 's/ .*//' || echo "unknown")
        [[ $QUIET -eq 0 ]] && echo -e "${BLUE}    Location: $LOCATION${NC}"
    fi

    # Write per-hang summary
    {
        echo "Hang:       $HANG_NAME"
        echo "Type:       $HANG_TYPE"
        echo "Input size: $(wc -c < "$hang_file") bytes"
        [[ "$HANG_TYPE" != "NotReproduced" ]] && echo "Location:   $LOCATION"
        echo ""
        echo "=== Input (first 200 bytes) ==="
        head -c 200 "$hang_file" || true
        echo ""
        echo ""
        echo "=== Sanitiser / Stack Output ==="
        head -40 "$LOG_FILE" 2>/dev/null || echo "(none)"
    } > "$HANG_TRIAGE_DIR/${HANG_NAME}.summary"

    [[ $QUIET -eq 0 ]] && echo ""
done

# ------------------------------------------------------------------
# Summary output
# ------------------------------------------------------------------
if [[ $QUIET -eq 1 ]]; then
    echo -e "${GREEN}  [ok] Hang triage: ${HANG_COUNT} unique (${CONFIRMED} confirmed, ${HANG_THEN_CRASH} crash-on-repro, ${NOT_REPRODUCED} not reproduced)${NC}"
    echo -e "${GREEN}       $HANG_TRIAGE_DIR${NC}"
else
    echo -e "${GREEN}+============================================+${NC}"
    echo -e "${GREEN}|  Hang Triage Summary                       |${NC}"
    echo -e "${GREEN}+============================================+${NC}"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "Total unique hangs:"  "$HANG_COUNT"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "Confirmed hangs:"     "$CONFIRMED"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "Crash on repro:"      "$HANG_THEN_CRASH"
    printf "${GREEN}|${NC}  %-22s %-18s ${GREEN}|${NC}\n" "Not reproduced:"      "$NOT_REPRODUCED"
    echo -e "${GREEN}+============================================+${NC}"
    echo ""
    echo -e "${BLUE}Summaries: $HANG_TRIAGE_DIR${NC}"
    echo ""
    echo -e "${YELLOW}Review hang summaries:${NC}"
    echo "  ls $HANG_TRIAGE_DIR/*.summary"
fi
