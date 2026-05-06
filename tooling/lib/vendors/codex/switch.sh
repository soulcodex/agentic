#!/usr/bin/env bash
# codex/switch.sh — vendor-switch behavior for Codex

vendor_codex_files_exist() {
  [[ -d "$VENDOR_FILES_DIR/codex" ]]
}

vendor_codex_preflight_conflicts() {
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
  local codex_agents_dir="$TARGET/.agentic/agents/codex"
  if [[ -d "$codex_agents_dir" ]] && [[ -n "$(find "$codex_agents_dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    mkdir -p "$TARGET/.codex"
    ln -sfn "../.agentic/agents/codex" "$TARGET/.codex/agents"
    echo "    Linked: .codex/agents → ../.agentic/agents/codex"
  else
    echo "    Skipped: .codex/agents (no Codex agent outputs present)"
  fi
}
