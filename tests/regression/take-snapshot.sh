#!/usr/bin/env bash
# Captures the build output of the claude-code adapter into tests/regression/snapshot/.
# Run this to update the snapshot after intentional changes to source files or adapters.
set -eo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SNAPSHOT_DIR="$SCRIPT_DIR/snapshot"

# Build the claude-code adapter
bash "$REPO_DIR/scripts/build.sh" --platform claude-code

DIST_DIR="$REPO_DIR/dist/claude-code"
[[ -d "$DIST_DIR" ]] || { echo "Build did not produce $DIST_DIR"; exit 1; }

# Replace snapshot with current build output
rm -rf "$SNAPSHOT_DIR"
mkdir -p "$SNAPSHOT_DIR"
cp -r "$DIST_DIR"/* "$DIST_DIR"/.claude "$DIST_DIR"/.mcp.json "$SNAPSHOT_DIR/" 2>/dev/null || true

# Remove non-deterministic / install-only artifacts
rm -f "$SNAPSHOT_DIR/.claude/.mbifc-manifest"
rm -rf "$SNAPSHOT_DIR/.claude-plugin"

echo "Snapshot saved to $SNAPSHOT_DIR"
echo "Files:"
(cd "$SNAPSHOT_DIR" && find . -type f | sort)
