#!/usr/bin/env bash
# sync-links.sh — Re-creates symlinks for a project deployed in --link mode
# Called by: just sync-links <target>
set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$TARGET" ]] && { echo "Error: --target required" >&2; exit 1; }

CONFIG="$TARGET/.agentic/config.yaml"
[[ ! -f "$CONFIG" ]] && { echo "Error: $CONFIG not found. Is this an agentic project?" >&2; exit 1; }

DEPLOY_MODE=$(yq '.deploy_mode // "copy"' "$CONFIG" 2>/dev/null || echo "copy")
if [[ "$DEPLOY_MODE" != "link" ]]; then
  echo "Project is not in link mode (deploy_mode: $DEPLOY_MODE). Nothing to sync."
  exit 0
fi

AGENTIC_ROOT=$(yq '.agentic_root // ""' "$CONFIG")
[[ -z "$AGENTIC_ROOT" || "$AGENTIC_ROOT" == "null" ]] && {
  echo "Error: agentic_root not set in $CONFIG" >&2; exit 1
}
[[ ! -d "$AGENTIC_ROOT" ]] && {
  echo "Error: agentic_root '$AGENTIC_ROOT' does not exist." >&2; exit 1
}

echo "Syncing symlinks for $TARGET (agentic_root: $AGENTIC_ROOT)..."

# Re-create fragments symlink
FRAGS="$TARGET/.agentic/fragments"
safe_rm_rf "$FRAGS"
ln -sf "$AGENTIC_ROOT/agents" "$FRAGS"
echo "  Linked: .agentic/fragments → $AGENTIC_ROOT/agents"

# Re-create skills symlink
SKILLS="$TARGET/.agentic/skills"
safe_rm_rf "$SKILLS"
ln -sf "$AGENTIC_ROOT/skills" "$SKILLS"
echo "  Linked: .agentic/skills → $AGENTIC_ROOT/skills"

# Re-create vendor-files symlink if generated dir exists
PROJECT_NAME=$(basename "$TARGET")
GENERATED_DIR="$AGENTIC_ROOT/_generated/$PROJECT_NAME/vendor-files"
if [[ -d "$GENERATED_DIR" ]]; then
  VENDOR_FILES="$TARGET/.agentic/vendor-files"
  safe_rm_rf "$VENDOR_FILES"
  ln -sf "$GENERATED_DIR" "$VENDOR_FILES"
  echo "  Linked: .agentic/vendor-files → $GENERATED_DIR"
fi

echo "Done. Run 'agentic switch <vendor>' to re-activate vendor symlinks."
