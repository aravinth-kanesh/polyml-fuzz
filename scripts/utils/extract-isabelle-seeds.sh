#!/bin/bash
# Extract seed programs from Isabelle/HOL source

set -euo pipefail

ISABELLE_PATH="${1:-}"
SEEDS_DIR="${2:-seeds/modules}"
TARGET_COUNT="${3:-30}"

if [ -z "$ISABELLE_PATH" ] || [ ! -d "$ISABELLE_PATH" ]; then
    echo "Usage: $0 <isabelle-path> [seeds-dir] [count]"
    echo ""
    echo "Example:"
    echo "  $0 /path/to/isabelle seeds/modules 30"
    echo ""
    echo "This will extract up to 30 .ML files from Isabelle and copy them to seeds/modules/"
    exit 1
fi

mkdir -p "$SEEDS_DIR"

echo "[*] Extracting SML seeds from Isabelle: $ISABELLE_PATH"
echo "[*] Target directory: $SEEDS_DIR"
echo "[*] Target count: $TARGET_COUNT"
echo ""

# Find .ML files, prefer smaller files, take first N
find "$ISABELLE_PATH" -name "*.ML" -size -20k -type f | \
    head -n "$TARGET_COUNT" | \
    while read -r ml_file; do
        # Generate a clean filename
        basename=$(basename "$ml_file")
        counter=1
        dest="$SEEDS_DIR/$basename"

        # Avoid name collisions
        while [ -f "$dest" ]; do
            dest="$SEEDS_DIR/${basename%.ML}_${counter}.ML"
            counter=$((counter + 1))
        done

        cp "$ml_file" "$dest"
        echo "  [ok] $basename -> $(basename "$dest")"
    done

EXTRACTED=$(find "$SEEDS_DIR" -name "*.ML" | wc -l)
echo ""
echo "[ok] Extracted $EXTRACTED Isabelle seeds"
echo ""
echo "Next: Validate seeds with ./scripts/validate-seeds.sh"
