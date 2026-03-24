#!/bin/bash
# fetch-campaign-findings.sh -- Download campaign artefacts from EC2 into results/findings/
#
# Usage:
#   ./scripts/fetch-campaign-findings.sh
#
# Requires:
#   - SSH key at ~/Downloads/polyml-fuzz-key.pem
#   - EC2 instance running and reachable
#   - All three campaigns analysed and hang-triaged on EC2

set -euo pipefail

EC2_HOST="ubuntu@ec2-18-134-13-1.eu-west-2.compute.amazonaws.com"
EC2_KEY="$HOME/Downloads/polyml-fuzz-key.pem"
EC2_BASE="/home/ubuntu/polyml-fuzz/results"
LOCAL_BASE="$(cd "$(dirname "$0")/.." && pwd)/results/findings"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

LABELS="phase1 phase2 grammar-retry"
CAMPAIGN_phase1="phase1-lexer-20260316-124325"
CAMPAIGN_phase2="phase2-parser-20260319-131212"
CAMPAIGN_grammarretry="phase2-parser-20260322-192228"

SCP="scp -i $EC2_KEY -r"

echo ""
echo "+============================================+"
echo "|  Fetch Campaign Findings from EC2          |"
echo "+============================================+"
echo ""
echo "EC2 host: $EC2_HOST"
echo "Local:    $LOCAL_BASE"
echo ""

# Verify key exists
if [[ ! -f "$EC2_KEY" ]]; then
    echo -e "${RED}[error] SSH key not found: $EC2_KEY${NC}"
    exit 1
fi

mkdir -p "$LOCAL_BASE"

for label in $LABELS; do
    key="${label//-/}"
    eval "campaign=\$CAMPAIGN_${key}"
    local_dir="$LOCAL_BASE/$label"
    ec2_dir="$EC2_BASE/$campaign"

    echo -e "${YELLOW}[*] Fetching $label ($campaign)...${NC}"
    mkdir -p "$local_dir"

    # REPORT.md
    echo "  -> REPORT.md"
    $SCP "$EC2_HOST:$ec2_dir/REPORT.md" "$local_dir/" 2>/dev/null \
        || echo -e "  ${YELLOW}[skip] REPORT.md not found${NC}"

    # campaign.meta
    echo "  -> campaign.meta"
    $SCP "$EC2_HOST:$ec2_dir/campaign.meta" "$local_dir/" 2>/dev/null \
        || echo -e "  ${YELLOW}[skip] campaign.meta not found${NC}"

    # Collected (minimised) crashes
    echo "  -> collected-crashes/"
    $SCP "$EC2_HOST:$ec2_dir/collected-crashes" "$local_dir/" 2>/dev/null \
        || echo -e "  ${YELLOW}[skip] collected-crashes/ not found${NC}"

    # Hang triage summaries
    echo "  -> triaged-hangs/"
    $SCP "$EC2_HOST:$ec2_dir/triaged-hangs" "$local_dir/" 2>/dev/null \
        || echo -e "  ${YELLOW}[skip] triaged-hangs/ not found${NC}"

    # LLVM coverage report (text only, not HTML)
    echo "  -> coverage/coverage_report.txt"
    mkdir -p "$local_dir/coverage"
    $SCP "$EC2_HOST:$ec2_dir/coverage/coverage_report.txt" "$local_dir/coverage/" 2>/dev/null \
        || echo -e "  ${YELLOW}[skip] coverage_report.txt not found${NC}"

    # Analytics CSV
    echo "  -> analytics/"
    $SCP "$EC2_HOST:$ec2_dir/analytics" "$local_dir/" 2>/dev/null \
        || echo -e "  ${YELLOW}[skip] analytics/ not found${NC}"

    echo -e "  ${GREEN}[ok] $label done${NC}"
    echo ""
done

echo -e "${GREEN}+============================================+"
echo -e "|  Done. Findings saved to results/findings/ |"
echo -e "+============================================+${NC}"
echo ""
echo "Next steps:"
echo "  git add results/findings/"
echo "  git commit -m \"Add production campaign findings (Phase 1, Phase 2, grammar retry)\""
