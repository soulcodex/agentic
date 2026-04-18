#!/usr/bin/env bash
# vendor-switch.sh — Switches the active AI vendor(s) in a target project
# Called by: just vendor-switch <target> <vendors>
#            agentic switch <vendor[,vendor...]|list|sync>
# Supports multiple vendors: agentic switch claude,copilot or agentic switch claude copilot
set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tooling/lib/common.sh
source "$SCRIPT_DIR/common.sh"

# ── Argument parsing ──────────────────────────────────────────────────────────
LIBRARY=""
TARGET=""
VENDORS_INPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library) require_arg "--library" "$2"; LIBRARY="$2"; shift 2 ;;
    --target)  require_arg "--target" "$2";  TARGET="$2";  shift 2 ;;
    -*)        echo "Unknown option: $1" >&2; exit 1 ;;
    *)         
      # Accumulate all positional args (vendors)
      if [[ -n "$VENDORS_INPUT" ]]; then
        VENDORS_INPUT="$VENDORS_INPUT,$1"
      else
        VENDORS_INPUT="$1"
      fi
      shift 
      ;;
  esac
done

[[ -z "$LIBRARY" ]] && { echo "Error: --library required" >&2; exit 1; }
[[ -z "$TARGET"  ]] && { echo "Error: --target required" >&2; exit 1; }
[[ -z "$VENDORS_INPUT" ]] && { echo "Error: vendor argument required (or 'list', 'sync')" >&2; exit 1; }

VENDOR_GEN="$LIBRARY/tooling/lib/vendor-gen.sh"
SYNC_SCRIPT="$LIBRARY/tooling/lib/sync.sh"
CONFIG="$TARGET/.agentic/config.yaml"
VENDOR_FILES_DIR="$TARGET/.agentic/vendor-files"

# Use AGENTIC_VENDORS from common.sh (single source of truth)

# ── Sync subcommand ────────────────────────────────────────────────────────────
if [[ "$VENDORS_INPUT" == "sync" ]]; then
  if [[ ! -f "$SYNC_SCRIPT" ]]; then
    echo "Error: sync.sh not found at $SYNC_SCRIPT" >&2
    exit 1
  fi
  exec bash "$SYNC_SCRIPT" --target "$TARGET"
fi

# ── List subcommand ────────────────────────────────────────────────────────────
if [[ "$VENDORS_INPUT" == "list" ]]; then
  ACTIVE_VENDORS=""
  if [[ -f "$CONFIG" ]]; then
    # Use read_active_vendors from common.sh
    ACTIVE_VENDORS=$(read_active_vendors "$CONFIG")
  fi
  echo "Available vendors:"
  for v in "${AGENTIC_VENDORS[@]}"; do
    if [[ ",$ACTIVE_VENDORS," == *",$v,"* ]]; then
      printf "  %-12s ← active\n" "$v"
    else
      printf "  %s\n" "$v"
    fi
  done
  exit 0
fi

# ── Parse vendors (comma or space separated) ───────────────────────────────────
# Normalize: replace commas with spaces, then split
VENDORS_INPUT="${VENDORS_INPUT//,/ }"
read -ra VENDORS <<< "$VENDORS_INPUT"

# ── Validate all vendors ───────────────────────────────────────────────────────
for vendor in "${VENDORS[@]}"; do
  valid=false
  for v in "${AGENTIC_VENDORS[@]}"; do
    [[ "$vendor" == "$v" ]] && valid=true && break
  done
  if [[ "$valid" != "true" ]]; then
    echo "Error: unknown vendor '$vendor'. Valid vendors: ${AGENTIC_VENDORS[*]}" >&2
    exit 1
  fi
done

# ── Read current active vendors ────────────────────────────────────────────────
CURRENT_VENDORS=$(read_active_vendors "$CONFIG")

# ── Legacy migration: stash system ─────────────────────────────────────────────
migrate_from_stash() {
  local stash_dir="$TARGET/.agentic/vendor-stash"
  if [[ -d "$stash_dir" ]]; then
    echo "Migrating from old stash system..."
    safe_rm_rf "$stash_dir"
    echo "  Removed: .agentic/vendor-stash/"
  fi
}

# ── Legacy migration: active_vendor string → active_vendors array ──────────────
migrate_active_vendor_format() {
  if [[ -f "$CONFIG" ]]; then
    # Check if old format exists and new format doesn't
    local old_vendor new_vendors
    old_vendor=$(yq '.active_vendor // ""' "$CONFIG" 2>/dev/null || true)
    new_vendors=$(yq '.active_vendors // ""' "$CONFIG" 2>/dev/null || true)
    
    if [[ -n "$old_vendor" && "$old_vendor" != "null" && ( -z "$new_vendors" || "$new_vendors" == "null" ) ]]; then
      echo "Migrating config: active_vendor → active_vendors..."
      yq -i 'del(.active_vendor) | .active_vendors = ["'"$old_vendor"'"]' "$CONFIG"
    fi
  fi
}

# ── Remove all vendor symlinks ─────────────────────────────────────────────────
remove_all_vendor_symlinks() {
  # Remove vendor entrypoint symlinks (check if symlink before removing)
  [[ -L "$TARGET/CLAUDE.md" ]] && rm "$TARGET/CLAUDE.md"

  [[ -L "$TARGET/.github/copilot-instructions.md" ]] && rm "$TARGET/.github/copilot-instructions.md"
  [[ -L "$TARGET/.github/instructions" ]] && rm "$TARGET/.github/instructions"
  [[ -L "$TARGET/.gemini/GEMINI.md" ]] && rm "$TARGET/GEMINI.md"
  [[ -L "$TARGET/.gemini/system.md" ]] && rm "$TARGET/.gemini/system.md"
  [[ -L "$TARGET/.gemini/skills" ]] && rm "$TARGET/.gemini/skills"
  
  # Remove skill symlinks
  [[ -L "$TARGET/.claude/skills" ]] && rm "$TARGET/.claude/skills"
  [[ -L "$TARGET/.opencode/skills" ]] && rm "$TARGET/.opencode/skills"
  [[ -L "$TARGET/.agents/skills" ]] && rm "$TARGET/.agents/skills"
  
  # Clean up empty directories (only if they exist and are empty)
  [[ -d "$TARGET/.github/instructions" ]] && rmdir "$TARGET/.github/instructions" 2>/dev/null || true
  [[ -d "$TARGET/.github" ]] && rmdir "$TARGET/.github" 2>/dev/null || true
  [[ -d "$TARGET/.gemini" ]] && rmdir "$TARGET/.gemini" 2>/dev/null || true
  [[ -d "$TARGET/.claude" ]] && rmdir "$TARGET/.claude" 2>/dev/null || true
  [[ -d "$TARGET/.opencode" ]] && rmdir "$TARGET/.opencode" 2>/dev/null || true
  [[ -d "$TARGET/.agents" ]] && rmdir "$TARGET/.agents" 2>/dev/null || true
}

# ── Create vendor-specific symlinks ────────────────────────────────────────────
create_vendor_symlinks() {
  local vendor="$1"
  echo "  Creating symlinks for $vendor..."
  
  case "$vendor" in
    claude)
      if [[ -f "$VENDOR_FILES_DIR/claude/CLAUDE.md" ]]; then
        ln -sf ".agentic/vendor-files/claude/CLAUDE.md" "$TARGET/CLAUDE.md"
        echo "    Linked: CLAUDE.md → .agentic/vendor-files/claude/CLAUDE.md"
      fi
      # Skills symlink
      if [[ -d "$TARGET/.agentic/skills" ]]; then
        mkdir -p "$TARGET/.claude"
        ln -sf "../.agentic/skills" "$TARGET/.claude/skills"
        echo "    Linked: .claude/skills → ../.agentic/skills"
      fi
      ;;
    copilot)
      if [[ -f "$VENDOR_FILES_DIR/copilot/copilot-instructions.md" ]]; then
        mkdir -p "$TARGET/.github"
        ln -sf "../.agentic/vendor-files/copilot/copilot-instructions.md" "$TARGET/.github/copilot-instructions.md"
        echo "    Linked: .github/copilot-instructions.md"
      fi
      if [[ -d "$VENDOR_FILES_DIR/copilot/instructions" ]]; then
        mkdir -p "$TARGET/.github"
        ln -sfn "../../.agentic/vendor-files/copilot/instructions" "$TARGET/.github/instructions"
        echo "    Linked: .github/instructions/"
      fi
      # Copilot uses prompt-injected skills, no symlink needed
      ;;
    codex)
      # Codex uses AGENTS.md natively - no file symlink needed
      echo "    Codex reads AGENTS.md natively — no file symlink needed"
      # Skills symlink
      if [[ -d "$TARGET/.agentic/skills" ]]; then
        mkdir -p "$TARGET/.agents"
        ln -sf "../.agentic/skills" "$TARGET/.agents/skills"
        echo "    Linked: .agents/skills → ../.agentic/skills"
      fi
      ;;
    gemini)
      # Primary context file (auto-discovered, zero config)
      if [[ -f "$VENDOR_FILES_DIR/gemini/GEMINI.md" ]]; then
        ln -sf ".agentic/vendor-files/gemini/GEMINI.md" "$TARGET/GEMINI.md"
        echo "    Linked: GEMINI.md → .agentic/vendor-files/gemini/GEMINI.md"
      fi
      # System prompt override (requires GEMINI_SYSTEM_MD=1)
      if [[ -f "$VENDOR_FILES_DIR/gemini/system.md" ]]; then
        mkdir -p "$TARGET/.gemini"
        ln -sf "../.agentic/vendor-files/gemini/system.md" "$TARGET/.gemini/system.md"
        echo "    Linked: .gemini/system.md → ../.agentic/vendor-files/gemini/system.md"
      fi
      # Native skills directory
      if [[ -d "$TARGET/.agentic/skills" ]]; then
        mkdir -p "$TARGET/.gemini"
        ln -sf "../.agentic/skills" "$TARGET/.gemini/skills"
        echo "    Linked: .gemini/skills → ../.agentic/skills"
      fi
      ;;
    opencode)
      # NOTE: opencode.json is intentionally not generated — users manage their own config.
      # Skills symlink - OpenCode reads from .opencode/skills
      if [[ -d "$TARGET/.agentic/skills" ]]; then
        mkdir -p "$TARGET/.opencode"
        ln -sf "../.agentic/skills" "$TARGET/.opencode/skills"
        echo "    Linked: .opencode/skills → ../.agentic/skills"
      fi
      ;;
  esac
}

# ── Check if vendor files exist ────────────────────────────────────────────────
vendor_files_exist() {
  local vendor="$1"
  case "$vendor" in
    claude)   [[ -f "$VENDOR_FILES_DIR/claude/CLAUDE.md" ]] ;;
    copilot)  [[ -f "$VENDOR_FILES_DIR/copilot/copilot-instructions.md" ]] ;;
    codex)    [[ -d "$VENDOR_FILES_DIR/codex" ]] ;;
    gemini)   [[ -f "$VENDOR_FILES_DIR/gemini/GEMINI.md" ]] ;;
    opencode) [[ -d "$VENDOR_FILES_DIR/opencode" ]] ;;
    *)        return 1 ;;
  esac
}

# ── Main ───────────────────────────────────────────────────────────────────────

# Run legacy migrations
migrate_from_stash
migrate_active_vendor_format

# Guard: if link mode and agentic_root is missing, fail clearly
if [[ -f "$CONFIG" ]]; then
  DEPLOY_MODE=$(yq '.deploy_mode // "copy"' "$CONFIG" 2>/dev/null || echo "copy")
  AGENTIC_ROOT=$(yq '.agentic_root // ""' "$CONFIG" 2>/dev/null || echo "")
  if [[ "$DEPLOY_MODE" == "link" && -n "$AGENTIC_ROOT" && ! -d "$AGENTIC_ROOT" ]]; then
    echo "Error: deploy_mode is 'link' but agentic_root '$AGENTIC_ROOT' does not exist." >&2
    echo "Run 'just sync-links $TARGET' after restoring the library." >&2
    exit 1
  fi
fi

# Generate vendor files for any vendors that don't have them
for vendor in "${VENDORS[@]}"; do
  if ! vendor_files_exist "$vendor"; then
    echo "Generating $vendor files..."
    bash "$VENDOR_GEN" --library "$LIBRARY" --target "$TARGET" --vendors "$vendor"
  fi
done

# Remove existing symlinks
echo "Removing existing vendor symlinks..."
remove_all_vendor_symlinks

# Create symlinks for all requested vendors
echo "Activating vendors: ${VENDORS[*]}"
for vendor in "${VENDORS[@]}"; do
  create_vendor_symlinks "$vendor"
done

# ── Update config.yaml with active_vendors array ──────────────────────────────
if [[ -f "$CONFIG" ]]; then
  # Build YAML array string: ["claude", "copilot"]
  yaml_array="["
  for i in "${!VENDORS[@]}"; do
    [[ $i -gt 0 ]] && yaml_array+=", "
    yaml_array+="\"${VENDORS[$i]}\""
  done
  yaml_array+="]"
  
  # Remove old active_vendor if present, set active_vendors array
  yq -i "del(.active_vendor) | .active_vendors = $yaml_array" "$CONFIG"
fi

echo ""
echo "Activated vendors: ${VENDORS[*]}"
if [[ -n "$CURRENT_VENDORS" && "$CURRENT_VENDORS" != "${VENDORS[*]}" ]]; then
  echo "Previous vendors: $CURRENT_VENDORS"
fi
echo ""
echo "Note: Symlinks are gitignored. After cloning, run 'agentic switch ${VENDORS[*]}' to recreate them."
