#!/usr/bin/env bash
# codex.sh — Vendor generation for Codex
gen_codex() {
  echo "  Generating Codex adapter (passthrough — AGENTS.md is native)..."
  # Codex reads AGENTS.md natively. No transformation needed.
  # We just create an empty marker directory to track that codex was generated
  mkdir -p "$VENDOR_FILES_DIR/codex"
  echo "  AGENTS.md is already the Codex-compatible file."
}