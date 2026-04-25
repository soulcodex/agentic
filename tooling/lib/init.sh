#!/usr/bin/env bash
# init.sh — Scaffold .agentic skeleton for custom profile workflows
# Called by: agentic init [target]
set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tooling/lib/common.sh
source "$SCRIPT_DIR/common.sh"

LIBRARY=""
TARGET=""
PROMPT_SYNC=true
FORCE_SYNC=false
SKIP_SYNC=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library)     require_arg "--library" "$2"; LIBRARY="$2"; shift 2 ;;
    --target)      require_arg "--target" "$2"; TARGET="$2"; shift 2 ;;
    --prompt-sync) PROMPT_SYNC=true; shift ;;
    --sync)        FORCE_SYNC=true; PROMPT_SYNC=false; shift ;;
    --no-sync)     SKIP_SYNC=true; PROMPT_SYNC=false; shift ;;
    *)             echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$LIBRARY" ]] && { echo "Error: --library required" >&2; exit 1; }
[[ -z "$TARGET" ]] && { echo "Error: --target required" >&2; exit 1; }

if [[ "$FORCE_SYNC" == "true" && "$SKIP_SYNC" == "true" ]]; then
  echo "Error: --sync and --no-sync are mutually exclusive" >&2
  exit 1
fi

AGENTIC_DIR="$TARGET/.agentic"
PROJECT_SKILLS_DIR="$AGENTIC_DIR/project-skills"
CONFIG_FILE="$AGENTIC_DIR/config.yaml"
PROFILE_FILE="$AGENTIC_DIR/profile.yaml"
MCP_FILE="$AGENTIC_DIR/mcp.yaml"

mkdir -p "$PROJECT_SKILLS_DIR"

if [[ -e "$CONFIG_FILE" || -e "$PROFILE_FILE" || -e "$MCP_FILE" ]]; then
  echo "Error: .agentic skeleton already exists in $TARGET" >&2
  echo "Refusing to overwrite existing files. Remove them manually if needed." >&2
  exit 1
fi

cat > "$CONFIG_FILE" <<EOF
# yaml-language-server: \$schema=https://raw.githubusercontent.com/soulcodex/agentic/main/schemas/config.schema.json
# Managed by agentic library
library_commit: "unknown"
profile: "custom"
profile_version: "1.0.0"
composed_at: ""
mode: lean
agentic_root: "$LIBRARY"
deploy_mode: copy
active_vendors: []
EOF

cat > "$PROFILE_FILE" <<'EOF'
# yaml-language-server: $schema=https://raw.githubusercontent.com/soulcodex/agentic/main/schemas/profile.schema.json
meta:
  name: "Custom Profile"
  description: >
    Project-local custom profile scaffolded by `agentic init`.
    Edit fragments, commands, and skills, then run `agentic sync`.
  version: "1.0.0"

fragments:
  base:
    - git-conventions
    - security
    - code-review
    - testing-philosophy
    - documentation
  languages: []
  frameworks: []
  architecture: []
  practices:
    - tdd
    - ci-cd
  domains: []

tech_stack:
  language_runtime: "Define runtime"
  package_manager: "Define package manager"
  test_framework: "Define test framework"

skills: []

output:
  build_command: "make build"
  test_command: "make test"
  lint_command: "make lint"
  project_header: |
    This project uses a custom agentic profile. Keep instructions aligned with
    real build/test/lint commands and project architecture.

vendors:
  enabled:
    - claude
    - copilot
    - codex
    - gemini
    - opencode
EOF

cat > "$MCP_FILE" <<'EOF'
# yaml-language-server: $schema=https://raw.githubusercontent.com/soulcodex/agentic/main/schemas/mcp.schema.json
strategy: merge
servers: {}
EOF

echo "Initialized .agentic skeleton in: $TARGET/.agentic"
echo "  - config.yaml"
echo "  - profile.yaml"
echo "  - mcp.yaml"
echo "  - project-skills/"

run_sync=false

if [[ "$FORCE_SYNC" == "true" ]]; then
  run_sync=true
elif [[ "$SKIP_SYNC" == "true" ]]; then
  run_sync=false
elif [[ "$PROMPT_SYNC" == "true" ]]; then
  if [[ -t 0 ]]; then
    printf 'Run "agentic sync" now? [y/N]: '
    read -r reply
    if [[ "$reply" =~ ^[Yy]$ ]]; then
      run_sync=true
    fi
  else
    echo "Skipping sync prompt (non-interactive shell)."
  fi
fi

if [[ "$run_sync" == "true" ]]; then
  bash "$LIBRARY/tooling/lib/sync.sh" --target "$TARGET"
else
  echo "Next step: run 'agentic sync ${TARGET}' when ready."
fi
