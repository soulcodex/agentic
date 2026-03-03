#!/bin/bash
# vendor-switch.sh — Switches the active AI vendor in a target project
# Called by: just vendor-switch <target> <vendor>
#            TARGET/agentic <vendor|list>
set -euo pipefail

# ── Argument parsing ──────────────────────────────────────────────────────────
LIBRARY=""
TARGET=""
VENDOR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library) LIBRARY="$2"; shift 2 ;;
    --target)  TARGET="$2";  shift 2 ;;
    -*)        echo "Unknown option: $1" >&2; exit 1 ;;
    *)         VENDOR="$1";  shift ;;
  esac
done

[[ -z "$LIBRARY" ]] && { echo "Error: --library required" >&2; exit 1; }
[[ -z "$TARGET"  ]] && { echo "Error: --target required" >&2; exit 1; }
[[ -z "$VENDOR"  ]] && { echo "Error: vendor argument required (or 'list')" >&2; exit 1; }

VENDOR_GEN="$LIBRARY/tooling/lib/vendor-gen.sh"
CONFIG="$TARGET/.agentic/config.yaml"

ALL_VENDORS="claude copilot codex gemini opencode"

# ── List subcommand ────────────────────────────────────────────────────────────
if [[ "$VENDOR" == "list" ]]; then
  ACTIVE=""
  if [[ -f "$CONFIG" ]]; then
    ACTIVE=$(yq '.active_vendor // ""' "$CONFIG" 2>/dev/null || true)
    [[ "$ACTIVE" == "null" ]] && ACTIVE=""
  fi
  echo "Available vendors:"
  for v in $ALL_VENDORS; do
    if [[ -n "$ACTIVE" && "$v" == "$ACTIVE" ]]; then
      printf "  %-12s ← active\n" "$v"
    else
      printf "  %s\n" "$v"
    fi
  done
  exit 0
fi

# ── Validate vendor ────────────────────────────────────────────────────────────
valid=false
for v in $ALL_VENDORS; do
  [[ "$VENDOR" == "$v" ]] && valid=true && break
done
if [[ "$valid" != "true" ]]; then
  echo "Error: unknown vendor '$VENDOR'. Valid vendors: $ALL_VENDORS" >&2
  exit 1
fi

# ── Read current active vendor ─────────────────────────────────────────────────
CURRENT_VENDOR=""
if [[ -f "$CONFIG" ]]; then
  CURRENT_VENDOR=$(yq '.active_vendor // ""' "$CONFIG" 2>/dev/null || true)
  [[ "$CURRENT_VENDOR" == "null" ]] && CURRENT_VENDOR=""
fi

# ── Stash current vendor files ─────────────────────────────────────────────────
stash_vendor() {
  local vendor="$1"
  local stash_dir="$TARGET/.agentic/vendor-stash/$vendor"
  mkdir -p "$stash_dir"
  echo "  Stashing $vendor files → .agentic/vendor-stash/$vendor/"
  case "$vendor" in
    claude)
      [[ -f "$TARGET/CLAUDE.md" ]] && mv "$TARGET/CLAUDE.md" "$stash_dir/CLAUDE.md"
      ;;
    copilot)
      [[ -f "$TARGET/.github/copilot-instructions.md" ]] && \
        mv "$TARGET/.github/copilot-instructions.md" "$stash_dir/copilot-instructions.md"
      if [[ -d "$TARGET/.github/instructions" ]]; then
        mkdir -p "$stash_dir/instructions"
        find "$TARGET/.github/instructions" -name "*.instructions.md" | while read -r f; do
          mv "$f" "$stash_dir/instructions/$(basename "$f")"
        done
      fi
      ;;
    codex)
      # AGENTS.md is the native format and shared — no-op
      echo "  codex uses AGENTS.md natively — nothing to stash"
      ;;
    gemini)
      [[ -f "$TARGET/.gemini/systemPrompt.md" ]] && \
        mv "$TARGET/.gemini/systemPrompt.md" "$stash_dir/systemPrompt.md"
      ;;
    opencode)
      [[ -f "$TARGET/opencode.json" ]] && mv "$TARGET/opencode.json" "$stash_dir/opencode.json"
      ;;
  esac
}

if [[ -n "$CURRENT_VENDOR" && "$CURRENT_VENDOR" != "$VENDOR" ]]; then
  stash_vendor "$CURRENT_VENDOR"
fi

# ── Generate new vendor files ──────────────────────────────────────────────────
echo "Generating $VENDOR files..."
bash "$VENDOR_GEN" --library "$LIBRARY" --target "$TARGET" --vendors "$VENDOR"

# ── Update config.yaml ─────────────────────────────────────────────────────────
if [[ -f "$CONFIG" ]]; then
  _tmp_config=$(mktemp)
  awk -v vendor="$VENDOR" \
    '/^active_vendor:/{print "active_vendor: " vendor; next} {print}' \
    "$CONFIG" > "$_tmp_config"
  mv "$_tmp_config" "$CONFIG"
fi

echo ""
echo "Switched to vendor: $VENDOR"
if [[ -n "$CURRENT_VENDOR" && "$CURRENT_VENDOR" != "$VENDOR" ]]; then
  echo "Previous vendor ($CURRENT_VENDOR) stashed to .agentic/vendor-stash/$CURRENT_VENDOR/"
fi
