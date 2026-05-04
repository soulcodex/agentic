#!/usr/bin/env bash
# codex/switch.sh — vendor-switch behavior for Codex

vendor_codex_files_exist() {
  [[ -d "$VENDOR_FILES_DIR/codex" ]]
}

vendor_codex_preflight_conflicts() {
  local legacy_path="$TARGET/.agents/orchestration"
  if [[ -e "$legacy_path" && ! -L "$legacy_path" ]]; then
    local backup_path
    backup_path="$(next_backup_path "$legacy_path")"
    mv "$legacy_path" "$backup_path"
    mkdir -p "$ROLLBACK_DIR"
    printf '%s\t%s\n' "$legacy_path" "$backup_path" >> "$ROLLBACK_CURSOR_MOVES_FILE"
    echo "  Migrated: .agents/orchestration → ${backup_path#"$TARGET"/}"
  fi

  local target_path="$TARGET/.codex/agents"
  if [[ -e "$target_path" && ! -L "$target_path" ]]; then
    echo "Error: Cannot activate codex agents because $target_path exists and is not a symlink." >&2
    return 1
  fi
}

vendor_codex_create_symlinks() {
  echo "    Codex reads AGENTS.md natively — no file symlink needed"
  if [[ -d "$TARGET/.agentic/skills" ]]; then
    mkdir -p "$TARGET/.agents"
    ln -sfn "../.agentic/skills" "$TARGET/.agents/skills"
    echo "    Linked: .agents/skills → ../.agentic/skills"
  fi
  mkdir -p "$TARGET/.codex"
  ln -sfn "../.agentic/agents/codex" "$TARGET/.codex/agents"
  echo "    Linked: .codex/agents → ../.agentic/agents/codex"
}
