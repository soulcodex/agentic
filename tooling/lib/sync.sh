#!/bin/bash
# sync.sh — Regenerates target project from local profile
# Called by: agentic sync
# Uses: .agentic/profile.yaml (local customizable profile)
#       .agentic/config.yaml (agentic_root, active_vendors)
set -euo pipefail

# ── Argument parsing ──────────────────────────────────────────────────────────
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    *)        echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$TARGET" ]] && { echo "Error: --target required" >&2; exit 1; }

CONFIG="$TARGET/.agentic/config.yaml"
LOCAL_PROFILE="$TARGET/.agentic/profile.yaml"

# ── Validate prerequisites ────────────────────────────────────────────────────
[[ ! -f "$CONFIG" ]] && {
  echo "Error: $CONFIG not found. Run 'just compose' first to initialize." >&2
  exit 1
}

[[ ! -f "$LOCAL_PROFILE" ]] && {
  echo "Error: $LOCAL_PROFILE not found. Run 'just compose' first to copy the profile." >&2
  exit 1
}

# ── Resolve library path ──────────────────────────────────────────────────────
# Priority: 1. AGENTIC_REPO_ROOT env var  2. AGENTIC_ROOT env var  3. config.yaml agentic_root  4. config.yaml library_path (legacy)
LIBRARY=""

# 1. AGENTIC_REPO_ROOT env var
if [[ -n "${AGENTIC_REPO_ROOT:-}" ]]; then
  LIBRARY="$AGENTIC_REPO_ROOT"
fi

# 2. AGENTIC_ROOT env var
if [[ -z "$LIBRARY" && -n "${AGENTIC_ROOT:-}" ]]; then
  LIBRARY="$AGENTIC_ROOT"
fi

# 3. config.yaml agentic_root
if [[ -z "$LIBRARY" ]]; then
  LIBRARY=$(yq '.agentic_root // ""' "$CONFIG" 2>/dev/null || echo "")
  [[ "$LIBRARY" == "null" || "$LIBRARY" == '""' ]] && LIBRARY=""
fi

# 4. config.yaml library_path (legacy)
if [[ -z "$LIBRARY" ]]; then
  LIBRARY=$(yq '.library_path // ""' "$CONFIG" 2>/dev/null || echo "")
  [[ "$LIBRARY" == "null" || "$LIBRARY" == '""' ]] && LIBRARY=""
fi

if [[ -z "$LIBRARY" ]]; then
  echo "Error: Cannot find agentic library." >&2
  echo "Set AGENTIC_REPO_ROOT environment variable or add 'agentic_root' to .agentic/config.yaml" >&2
  exit 1
fi

[[ ! -d "$LIBRARY" ]] && {
  echo "Error: library path '$LIBRARY' does not exist" >&2
  exit 1
}

COMPOSE_SCRIPT="$LIBRARY/tooling/lib/compose.sh"
[[ ! -f "$COMPOSE_SCRIPT" ]] && {
  echo "Error: compose.sh not found at $COMPOSE_SCRIPT" >&2
  exit 1
}

# ── Read current configuration ────────────────────────────────────────────────
# Try new array format first, fall back to old string format
ACTIVE_VENDORS=$(yq '.active_vendors // [] | join(",")' "$CONFIG" 2>/dev/null || echo "")
if [[ -z "$ACTIVE_VENDORS" || "$ACTIVE_VENDORS" == "null" ]]; then
  ACTIVE_VENDORS=$(yq '.active_vendor // ""' "$CONFIG" 2>/dev/null || echo "")
  [[ "$ACTIVE_VENDORS" == "null" ]] && ACTIVE_VENDORS=""
fi

MODE=$(yq '.mode // "lean"' "$CONFIG" 2>/dev/null || echo "lean")
[[ "$MODE" == "null" ]] && MODE="lean"

# ── Sync: regenerate from local profile ───────────────────────────────────────
echo "Syncing from local profile: $LOCAL_PROFILE"
echo "Library: $LIBRARY"
echo "Mode: $MODE"
[[ -n "$ACTIVE_VENDORS" ]] && echo "Active vendors: $ACTIVE_VENDORS"
echo ""

# Build compose command
COMPOSE_CMD=("bash" "$COMPOSE_SCRIPT" "--library" "$LIBRARY" "--profile-file" "$LOCAL_PROFILE" "--target" "$TARGET")
[[ "$MODE" == "full" ]] && COMPOSE_CMD+=("--full")

# Run compose
"${COMPOSE_CMD[@]}"

# ── Restore active vendors if set ─────────────────────────────────────────────
if [[ -n "$ACTIVE_VENDORS" ]]; then
  echo ""
  echo "Restoring vendors: $ACTIVE_VENDORS"
  VENDOR_SWITCH="$LIBRARY/tooling/lib/vendor-switch.sh"
  bash "$VENDOR_SWITCH" --library "$LIBRARY" --target "$TARGET" "$ACTIVE_VENDORS"
fi

echo ""
echo "Sync complete. Project regenerated from local profile."
