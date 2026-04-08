#!/usr/bin/env bash
# Captures the output of bash launchme.sh into tests/regression/snapshot/
# Run this BEFORE the refactor so we have a comparison baseline.
set -eo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAPSHOT_DIR="$SCRIPT_DIR/snapshot"
TMPVAULT="$(mktemp -d)"

# Mirror the repo into a fake parent vault
mkdir -p "$TMPVAULT/My-Brain-Is-Full-Crew"
for d in scripts agents references skills hooks; do
  ln -s "$REPO_DIR/$d" "$TMPVAULT/My-Brain-Is-Full-Crew/$d"
done
for f in settings.json CLAUDE.md .mcp.json; do
  [[ -f "$REPO_DIR/$f" ]] && ln -s "$REPO_DIR/$f" "$TMPVAULT/My-Brain-Is-Full-Crew/$f"
done

# Run launchme non-interactively (auto-confirm)
cd "$TMPVAULT/My-Brain-Is-Full-Crew"
printf 'y\nn\n' | bash scripts/launchme.sh >/dev/null 2>&1 || true

# Capture the resulting vault state
rm -rf "$SNAPSHOT_DIR"
mkdir -p "$SNAPSHOT_DIR"
cp -r "$TMPVAULT/.claude" "$SNAPSHOT_DIR/.claude" 2>/dev/null || true
[[ -f "$TMPVAULT/CLAUDE.md" ]] && cp "$TMPVAULT/CLAUDE.md" "$SNAPSHOT_DIR/CLAUDE.md"
[[ -f "$TMPVAULT/.mcp.json" ]] && cp "$TMPVAULT/.mcp.json" "$SNAPSHOT_DIR/.mcp.json"

# Strip non-deterministic content from manifest
[[ -f "$SNAPSHOT_DIR/.claude/.mbifc-manifest" ]] && sort -o "$SNAPSHOT_DIR/.claude/.mbifc-manifest" "$SNAPSHOT_DIR/.claude/.mbifc-manifest"

rm -rf "$TMPVAULT"
echo "Snapshot saved to $SNAPSHOT_DIR"
