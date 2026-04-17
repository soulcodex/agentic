#!/usr/bin/env bash
# sync-check.sh — Checks if a project's config has drifted from the current library
# Called by: just sync-check <target>
set -euo pipefail

LIBRARY=""
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library) LIBRARY="$2"; shift 2 ;;
    --target)  TARGET="$2";  shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$LIBRARY" ]] && { echo "Error: --library required" >&2; exit 1; }
[[ -z "$TARGET"  ]] && { echo "Error: --target required" >&2; exit 1; }

LOCK_FILE="$TARGET/.agentic/config.yaml"
if [[ ! -f "$LOCK_FILE" ]]; then
  echo "No lock file found at $LOCK_FILE."
  echo "This project was not set up with the agentic library (or was set up manually)."
  exit 0
fi

DEPLOYED_COMMIT=$(yq '.library_commit' "$LOCK_FILE" 2>/dev/null || echo "unknown")
CURRENT_COMMIT=$(cd "$LIBRARY" && git rev-parse HEAD 2>/dev/null || echo "unknown")
PROFILE=$(yq '.profile' "$LOCK_FILE" 2>/dev/null || echo "unknown")
COMPOSED_AT=$(yq '.composed_at' "$LOCK_FILE" 2>/dev/null || echo "unknown")

echo "Sync check for: $TARGET"
echo "  Profile:       $PROFILE"
echo "  Composed at:   $COMPOSED_AT"
echo "  Deployed from: $DEPLOYED_COMMIT"
echo "  Library HEAD:  $CURRENT_COMMIT"
echo ""

if [[ "$DEPLOYED_COMMIT" == "$CURRENT_COMMIT" ]]; then
  echo "Status: UP TO DATE — no drift detected."
  exit 0
fi

# Find changed fragments since the deployed commit
if [[ "$DEPLOYED_COMMIT" != "unknown" && "$CURRENT_COMMIT" != "unknown" ]]; then
  CHANGED=$(cd "$LIBRARY" && git diff --name-only "$DEPLOYED_COMMIT" "$CURRENT_COMMIT" -- agents/ 2>/dev/null || true)
  if [[ -n "$CHANGED" ]]; then
    echo "Status: DRIFTED — the following fragments changed since deployment:"
    while IFS= read -r line; do
      printf "  - %s\n" "$line"
    done <<< "$CHANGED"
  else
    echo "Status: DRIFTED (library commit changed, but no agent fragment changes detected)"
  fi
else
  echo "Status: UNKNOWN — cannot compare commits (git not available or shallow clone)"
fi

echo ""
echo "To update, run: just compose $PROFILE $TARGET"
exit 1
