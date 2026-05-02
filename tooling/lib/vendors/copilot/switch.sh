#!/usr/bin/env bash
# copilot/switch.sh — vendor-switch behavior for Copilot

vendor_copilot_files_exist() {
  [[ -f "$VENDOR_FILES_DIR/copilot/copilot-instructions.md" ]]
}

vendor_copilot_create_symlinks() {
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
}
