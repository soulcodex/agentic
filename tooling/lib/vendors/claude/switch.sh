#!/usr/bin/env bash
# claude/switch.sh — vendor-switch behavior for Claude

vendor_claude_files_exist() {
  [[ -f "$VENDOR_FILES_DIR/claude/CLAUDE.md" ]]
}

vendor_claude_create_symlinks() {
  if [[ -f "$VENDOR_FILES_DIR/claude/CLAUDE.md" ]]; then
    ln -sf ".agentic/vendor-files/claude/CLAUDE.md" "$TARGET/CLAUDE.md"
    echo "    Linked: CLAUDE.md → .agentic/vendor-files/claude/CLAUDE.md"
  fi
  if [[ -d "$TARGET/.agentic/skills" ]]; then
    mkdir -p "$TARGET/.claude"
    ln -sf "../.agentic/skills" "$TARGET/.claude/skills"
    echo "    Linked: .claude/skills → ../.agentic/skills"
  fi
}
