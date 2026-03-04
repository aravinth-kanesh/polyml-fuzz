#!/bin/bash
# Triage crashes: reproduce with sanitisers and classify by root cause

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
RESULTS_DIR="${PROJECT_ROOT}/results"
POLY_BIN="${PROJECT_ROOT}/build/polyml-instrumented/install/bin/poly"

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
CRASHES_DIR="$CAMPAIGN_DIR/collected-crashes/minimised"
TRIAGE_DIR="$CAMPAIGN_DIR/triaged"

if [ ! -d "$CRASHES_DIR" ]; then
    echo -e "${RED}[!] Crashes not found. Run collect-crashes.sh first${NC}"
    exit 1
fi

echo -e "${GREEN}[*] Triaging crashes from: $CAMPAIGN_NAME${NC}"

# Create triage output directory
mkdir -p "$TRIAGE_DIR"

# Reproduce each crash with sanitisers enabled
CRASH_COUNT=0
declare -A CRASH_TYPES

for crash_file in "$CRASHES_DIR"/*; do
    if [ ! -f "$crash_file" ]; then
        continue
    fi

    CRASH_COUNT=$((CRASH_COUNT + 1))
    CRASH_NAME=$(basename "$crash_file")

    echo -e "${BLUE}[$CRASH_COUNT] Reproducing: $CRASH_NAME${NC}"

    # Run with full sanitiser output
    LOG_FILE="$TRIAGE_DIR/${CRASH_NAME}.log"

    timeout 10 "$POLY_BIN" < "$crash_file" > /dev/null 2> "$LOG_FILE" || {
        EXIT_CODE=$?

        # Classify crash
        if grep -q "runtime error" "$LOG_FILE"; then
            FAULT_TYPE="UndefinedBehavior"
            echo -e "${YELLOW}    -> UBSan: Undefined behaviour detected${NC}"
        elif grep -q "heap-buffer-overflow" "$LOG_FILE"; then
            FAULT_TYPE="HeapBufferOverflow"
            echo -e "${RED}    -> ASan: Heap buffer overflow${NC}"
        elif grep -q "stack-buffer-overflow" "$LOG_FILE"; then
            FAULT_TYPE="StackBufferOverflow"
            echo -e "${RED}    -> ASan: Stack buffer overflow${NC}"
        elif grep -q "use-after-free" "$LOG_FILE"; then
            FAULT_TYPE="UseAfterFree"
            echo -e "${RED}    -> ASan: Use-after-free${NC}"
        elif [ $EXIT_CODE -eq 124 ]; then
            FAULT_TYPE="Timeout"
            echo -e "${YELLOW}    -> Timeout (possible hang)${NC}"
        elif [ $EXIT_CODE -gt 128 ]; then
            SIGNAL=$((EXIT_CODE - 128))
            FAULT_TYPE="Signal${SIGNAL}"
            echo -e "${RED}    -> Crash: signal $SIGNAL${NC}"
        else
            FAULT_TYPE="Unknown"
            echo -e "${YELLOW}    -> Unknown error (exit code $EXIT_CODE)${NC}"
        fi

        # Track by fault type
        CRASH_TYPES[$FAULT_TYPE]=$((${CRASH_TYPES[$FAULT_TYPE]:-0} + 1))

        # Extract stack trace location
        LOCATION=$(grep -m 1 "#0" "$LOG_FILE" | sed 's/.*in //' | sed 's/ .*//' || echo "unknown")
        echo -e "${BLUE}    Location: $LOCATION${NC}"

        # Create summary file
        echo "Crash: $CRASH_NAME" > "$TRIAGE_DIR/${CRASH_NAME}.summary"
        echo "Type: $FAULT_TYPE" >> "$TRIAGE_DIR/${CRASH_NAME}.summary"
        echo "Location: $LOCATION" >> "$TRIAGE_DIR/${CRASH_NAME}.summary"
        echo "" >> "$TRIAGE_DIR/${CRASH_NAME}.summary"
        echo "=== Sanitiser Output ===" >> "$TRIAGE_DIR/${CRASH_NAME}.summary"
        head -30 "$LOG_FILE" >> "$TRIAGE_DIR/${CRASH_NAME}.summary"
    }

    echo ""
done

# Print summary
echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Triage Summary                            |${NC}"
echo -e "${GREEN}+============================================+${NC}"
printf "${GREEN}|${NC}  Total crashes: %-27s ${GREEN}|${NC}\n" "$CRASH_COUNT"
echo -e "${GREEN}+============================================+${NC}"

for fault_type in "${!CRASH_TYPES[@]}"; do
    COUNT=${CRASH_TYPES[$fault_type]}
    printf "${GREEN}|${NC}  %-20s %-18s ${GREEN}|${NC}\n" "$fault_type:" "$COUNT"
done

echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${BLUE}Detailed logs: $TRIAGE_DIR${NC}"
echo ""
echo -e "${YELLOW}Review summaries:${NC}"
echo -e "  ls $TRIAGE_DIR/*.summary"
