#!/usr/bin/env bash
# opencode.sh — Vendor generation for OpenCode
gen_opencode() {
  echo "  Generating Opencode adapter..."
  echo "  OpenCode reads AGENTS.md natively — no opencode.json generated."
  echo "  Users manage their own opencode.json configuration."
  mkdir -p "$VENDOR_FILES_DIR/opencode"
}