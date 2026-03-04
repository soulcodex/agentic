#!/bin/bash
# vendor-switch.sh — Switches the active AI vendor(s) in a target project
# Called by: just vendor-switch <target> <vendors>
#            agentic switch <vendor[,vendor...]|list|sync>
# Supports multiple vendors: agentic switch claude,copilot or agentic switch claude copilot
set -euo pipefail

# ── Argument parsing ──────────────────────────────────────────────────────────
LIBRARY=""
TARGET=""
VENDORS_INPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library) LIBRARY="$2"; shift 2 ;;
    --target)  TARGET="$2";  shift 2 ;;
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
DEPLOY_SKILLS="$LIBRARY/tooling/lib/deploy-skills.sh"
SYNC_SCRIPT="$LIBRARY/tooling/lib/sync.sh"
CONFIG="$TARGET/.agentic/config.yaml"
VENDOR_FILES_DIR="$TARGET/.agentic/vendor-files"

ALL_VENDORS="claude copilot codex gemini opencode"

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
    # Try new array format first, fall back to old string format
    ACTIVE_VENDORS=$(yq '.active_vendors // [] | join(",")' "$CONFIG" 2>/dev/null || true)
    if [[ -z "$ACTIVE_VENDORS" || "$ACTIVE_VENDORS" == "null" ]]; then
      # Fallback to old format
      ACTIVE_VENDORS=$(yq '.active_vendor // ""' "$CONFIG" 2>/dev/null || true)
      [[ "$ACTIVE_VENDORS" == "null" ]] && ACTIVE_VENDORS=""
    fi
  fi
  echo "Available vendors:"
  for v in $ALL_VENDORS; do
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
  for v in $ALL_VENDORS; do
    [[ "$vendor" == "$v" ]] && valid=true && break
  done
  if [[ "$valid" != "true" ]]; then
    echo "Error: unknown vendor '$vendor'. Valid vendors: $ALL_VENDORS" >&2
    exit 1
  fi
done

# ── Read current active vendors ────────────────────────────────────────────────
CURRENT_VENDORS=""
if [[ -f "$CONFIG" ]]; then
  # Try new array format first
  CURRENT_VENDORS=$(yq '.active_vendors // [] | join(",")' "$CONFIG" 2>/dev/null || true)
  if [[ -z "$CURRENT_VENDORS" || "$CURRENT_VENDORS" == "null" ]]; then
    # Fallback to old string format
    CURRENT_VENDORS=$(yq '.active_vendor // ""' "$CONFIG" 2>/dev/null || true)
    [[ "$CURRENT_VENDORS" == "null" ]] && CURRENT_VENDORS=""
  fi
fi

# ── Legacy migration: stash system ─────────────────────────────────────────────
migrate_from_stash() {
  local stash_dir="$TARGET/.agentic/vendor-stash"
  if [[ -d "$stash_dir" ]]; then
    echo "Migrating from old stash system..."
    rm -rf "$stash_dir"
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
  [[ -L "$TARGET/opencode.json" ]] && rm "$TARGET/opencode.json"
  [[ -L "$TARGET/.github/copilot-instructions.md" ]] && rm "$TARGET/.github/copilot-instructions.md"
  [[ -L "$TARGET/.github/instructions" ]] && rm "$TARGET/.github/instructions"
  [[ -L "$TARGET/.gemini/systemPrompt.md" ]] && rm "$TARGET/.gemini/systemPrompt.md"
  
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
      if [[ -f "$VENDOR_FILES_DIR/gemini/systemPrompt.md" ]]; then
        mkdir -p "$TARGET/.gemini"
        ln -sf "../.agentic/vendor-files/gemini/systemPrompt.md" "$TARGET/.gemini/systemPrompt.md"
        echo "    Linked: .gemini/systemPrompt.md"
      fi
      # Gemini uses prompt-injected skills, no symlink needed
      ;;
    opencode)
      if [[ -f "$VENDOR_FILES_DIR/opencode/opencode.json" ]]; then
        ln -sf ".agentic/vendor-files/opencode/opencode.json" "$TARGET/opencode.json"
        echo "    Linked: opencode.json → .agentic/vendor-files/opencode/opencode.json"
      fi
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
    gemini)   [[ -f "$VENDOR_FILES_DIR/gemini/systemPrompt.md" ]] ;;
    opencode) [[ -f "$VENDOR_FILES_DIR/opencode/opencode.json" ]] ;;
    *)        return 1 ;;
  esac
}

# ── Main ───────────────────────────────────────────────────────────────────────

# Run legacy migrations
migrate_from_stash
migrate_active_vendor_format

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
