#!/bin/bash
# start.sh: Launch a Poly/ML fuzzing campaign in a managed tmux session
#
# Opens three tmux windows automatically:
#   [0] fuzzer    - AFL++ campaign via launch.sh
#   [1] monitor   - Live status dashboard, refreshed every 30 seconds
#   [2] analytics - Hourly edge logging and saturation detection
#
# Navigate between windows: Ctrl+B, n (next) / Ctrl+B, p (previous)
# Detach from session:       Ctrl+B, d
# Reattach later:            tmux attach -t fuzz-phase1
#
# Usage:
#   ./campaign/start.sh --phase 1 [--duration SECONDS] [--instances N]
#   ./campaign/start.sh --phase 2 --evolved phase1-lexer-YYYYMMDD-HHMMSS [--duration SECONDS]
#
# Examples:
#   ./campaign/start.sh --phase 1 --duration 259200 --instances 2
#   ./campaign/start.sh --phase 2 --evolved phase1-lexer-20260312-174859
#   ./campaign/start.sh --phase 1 --duration 1800 --instances 2   # 30-min smoke test

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# Defaults
PHASE=""
DURATION=259200
INSTANCES=4
EVOLVED_CAMPAIGN=""
USE_EVOLVED=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --phase)     PHASE="$2";            shift 2 ;;
        --duration)  DURATION="$2";         shift 2 ;;
        --instances) INSTANCES="$2";        shift 2 ;;
        --evolved)   EVOLVED_CAMPAIGN="$2"; USE_EVOLVED=1; shift 2 ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)
            echo -e "${RED}[!] Unknown argument: $1${NC}"; exit 1 ;;
    esac
done

if [[ -z "$PHASE" ]]; then
    echo -e "${RED}[!] --phase is required (1 or 2)${NC}"
    echo -e "    Usage: $0 --phase 1 [--duration 259200] [--instances 2]"
    exit 1
fi

if [[ "$PHASE" != "1" && "$PHASE" != "2" ]]; then
    echo -e "${RED}[!] --phase must be 1 or 2${NC}"; exit 1
fi

if ! command -v tmux &>/dev/null; then
    echo -e "${RED}[!] tmux not found. Install with: sudo apt install tmux${NC}"
    exit 1
fi

# Pre-generate the campaign name so all windows reference the same name.
# launch.sh accepts --name to use this instead of generating its own.
PHASE_LABEL=$([[ "$PHASE" == "1" ]] && echo "lexer" || echo "parser")
CAMPAIGN_NAME="phase${PHASE}-${PHASE_LABEL}-$(date +%Y%m%d-%H%M%S)"
SESSION="fuzz-phase${PHASE}"

echo -e "${GREEN}+============================================+${NC}"
echo -e "${GREEN}|  Poly/ML Fuzzer: Campaign Launcher         |${NC}"
echo -e "${GREEN}+============================================+${NC}"
echo ""
echo -e "${BLUE}Campaign:${NC}  $CAMPAIGN_NAME"
echo -e "${BLUE}Phase:${NC}     $PHASE"
echo -e "${BLUE}Duration:${NC}  $DURATION seconds ($(( DURATION / 3600 )) hours)"
echo -e "${BLUE}Instances:${NC} $INSTANCES"
echo ""

# If evolving from a prior phase, prepare evolved seeds first
if [[ "$USE_EVOLVED" -eq 1 ]]; then
    if [[ -z "$EVOLVED_CAMPAIGN" ]]; then
        echo -e "${RED}[!] --evolved requires a campaign name (e.g. phase1-lexer-20260312-174859)${NC}"
        exit 1
    fi
    echo -e "${GREEN}[*] Preparing evolved seeds from: $EVOLVED_CAMPAIGN${NC}"
    "${PROJECT_ROOT}/scripts/prepare-evolved-seeds.sh" "$EVOLVED_CAMPAIGN"
    echo ""
fi

# Kill any stale session with the same name
tmux kill-session -t "$SESSION" 2>/dev/null || true

# Build the launch command for window 0
LAUNCH_CMD="cd ${PROJECT_ROOT}"
LAUNCH_CMD+=" && ./campaign/launch.sh"
LAUNCH_CMD+=" --phase ${PHASE}"
LAUNCH_CMD+=" --duration ${DURATION}"
LAUNCH_CMD+=" --instances ${INSTANCES}"
LAUNCH_CMD+=" --name ${CAMPAIGN_NAME}"
[[ "$USE_EVOLVED" -eq 1 ]] && LAUNCH_CMD+=" --use-evolved"
LAUNCH_CMD+="; echo ''; echo '[done] Campaign finished. Press Enter to close.'; read"

# Monitor window: wait for the results dir to exist, then start watch
MONITOR_CMD="cd ${PROJECT_ROOT}"
MONITOR_CMD+="; echo 'Waiting for campaign to start...'"
MONITOR_CMD+="; until [ -d results/${CAMPAIGN_NAME} ]; do sleep 2; done"
MONITOR_CMD+="; sleep 5"
MONITOR_CMD+="; watch -c -n 30 ./campaign/monitor.sh ${CAMPAIGN_NAME}"

# Analytics window: wait for fuzzer01 to initialise, then start analytics
ANALYTICS_CMD="cd ${PROJECT_ROOT}"
ANALYTICS_CMD+="; echo 'Waiting for campaign to start...'"
ANALYTICS_CMD+="; until [ -d results/${CAMPAIGN_NAME}/fuzzer01 ]; do sleep 5; done"
ANALYTICS_CMD+="; sleep 10"
ANALYTICS_CMD+="; ./campaign/analytics.sh ${CAMPAIGN_NAME}"

# Create tmux session with three named windows
tmux new-session -d -s "$SESSION" -n "fuzzer"    -x 220 -y 50
tmux new-window     -t "$SESSION" -n "monitor"
tmux new-window     -t "$SESSION" -n "analytics"

# Send commands to each window
tmux send-keys -t "${SESSION}:fuzzer"    "$LAUNCH_CMD"    Enter
tmux send-keys -t "${SESSION}:monitor"   "$MONITOR_CMD"   Enter
tmux send-keys -t "${SESSION}:analytics" "$ANALYTICS_CMD" Enter

# Focus fuzzer window and attach
tmux select-window -t "${SESSION}:fuzzer"

echo -e "${GREEN}[*] tmux session '${SESSION}' created with 3 windows${NC}"
echo -e "${YELLOW}    Ctrl+B, n  - next window${NC}"
echo -e "${YELLOW}    Ctrl+B, p  - previous window${NC}"
echo -e "${YELLOW}    Ctrl+B, d  - detach (campaign keeps running)${NC}"
echo -e "${YELLOW}    tmux attach -t ${SESSION}  - reattach${NC}"
echo ""

# Attach (or switch if already inside tmux)
if [[ -n "${TMUX:-}" ]]; then
    tmux switch-client -t "$SESSION"
else
    tmux attach-session -t "$SESSION"
fi
