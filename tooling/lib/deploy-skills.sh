#!/usr/bin/env bash
# deploy-skills.sh — Deploys skill directories to a target project
# Called by: just deploy-skills <target> [skills] [vendor]
set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tooling/lib/common.sh
source "$SCRIPT_DIR/common.sh"

# ── Argument parsing ──────────────────────────────────────────────────────────
LIBRARY=""
TARGET=""
SKILLS="all"
VENDOR=""
LINK_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library) require_arg "--library" "$2"; LIBRARY="$2"; shift 2 ;;
    --target)  require_arg "--target" "$2";  TARGET="$2";  shift 2 ;;
    --skills)  require_arg "--skills" "$2"; SKILLS="$2"; shift 2 ;;
    --vendor)  require_arg "--vendor" "$2"; VENDOR="$2"; shift 2 ;;
    --link)    LINK_MODE=true; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$LIBRARY" ]] && { echo "Error: --library required" >&2; exit 1; }
[[ -z "$TARGET"  ]] && { echo "Error: --target required" >&2; exit 1; }

# Canonical skill location
SKILLS_DST="$TARGET/.agentic/skills"
mkdir -p "$SKILLS_DST"

# ── Link mode ────────────────────────────────────────────────────────────────
if [[ "$LINK_MODE" == "true" ]]; then
  echo "Deploying skills (link mode) to $TARGET..."
  # Remove any existing copy or symlink using safe_rm_rf
  safe_rm_rf "$SKILLS_DST"
  ln -sf "$LIBRARY/skills" "$SKILLS_DST"
  echo "Linked .agentic/skills → $LIBRARY/skills (link mode)"

  # Still create vendor skill symlinks if vendor specified
  if [[ -n "$VENDOR" ]]; then
    IFS=',' read -ra VENDOR_LIST <<< "$VENDOR"
    for v in "${VENDOR_LIST[@]}"; do
      v=$(echo "$v" | tr -d ' ')
      create_skill_symlinks "$v"
    done
  fi

  generate_skills_readme
  echo ""
  echo "Skills deployed (symlinked) to $TARGET/.agentic/skills/"
  exit 0
fi

# ── Skill resolution ──────────────────────────────────────────────────────────
deploy_skill() {
  local skill_dir="$1"
  local skill_name
  skill_name=$(basename "$skill_dir")
  local dst="$SKILLS_DST/$skill_name"

  mkdir -p "$dst"
  cp -r "$skill_dir/." "$dst/"
  echo "  Deployed skill: $skill_name → .agentic/skills/$skill_name"
}

# Deploy a project-local skill (project: prefix)
deploy_project_skill() {
  local skill_name="$1"
  local project_skills_dir="$TARGET/.agentic/project-skills"
  local skill_dir="$project_skills_dir/$skill_name"

  if [[ ! -d "$skill_dir" ]]; then
    echo "Warning: project skill '$skill_name' not found at $skill_dir — skipping" >&2
    return 0
  fi

  if [[ ! -f "$skill_dir/SKILL.md" ]]; then
    echo "Warning: project skill '$skill_name' missing SKILL.md — skipping" >&2
    return 0
  fi

  local dst="$SKILLS_DST/$skill_name"
  mkdir -p "$dst"
  cp -r "$skill_dir/." "$dst/"
  echo "  Deployed project skill: $skill_name → .agentic/skills/$skill_name"
}

# ── Generate skills README ────────────────────────────────────────────────────
generate_skills_readme() {
  local readme="$SKILLS_DST/README.md"
  local skills_index="$LIBRARY/index/skills.json"

  cat > "$readme" <<'HEADER'
# Skills

This directory contains reusable agent skills deployed by the agentic library.

## Vendor Compatibility

| Vendor | Skill Path | Support |
|--------|-----------|---------|
| Claude | `.claude/skills/` (symlinked here) | Native |
| OpenCode | `.opencode/skills/` (symlinked here) | Native |
| Codex | `.agents/skills/` (symlinked here) | Native |
| Copilot | Injected into copilot-instructions.md | Prompt-injected |
| Gemini | Injected into systemPrompt.md | Prompt-injected |

## How It Works

Skills are stored in `.agentic/skills/` as the canonical location. Vendor-specific
symlinks are created when you switch vendors:

```
.claude/skills   → ../.agentic/skills   (Claude)
.opencode/skills → ../.agentic/skills   (OpenCode)
.agents/skills   → ../.agentic/skills   (Codex)
```

Run `agentic switch <vendor>` to switch vendors and update symlinks.

## Available Skills

HEADER

  # Build skill table
  echo "| Skill | Description |" >> "$readme"
  echo "|-------|-------------|" >> "$readme"

  if [[ -f "$skills_index" ]]; then
    for skill_dir in "$SKILLS_DST"/*/; do
      [[ ! -d "$skill_dir" ]] && continue
      local skill_name
      skill_name=$(basename "$skill_dir")
      [[ "$skill_name" == "README.md" ]] && continue
      local skill_desc
      skill_desc=$(jq -r --arg n "$skill_name" '.skills[] | select(.name == $n) | .description // "No description"' "$skills_index" 2>/dev/null || echo "No description")
      # Truncate description
      [[ ${#skill_desc} -gt 80 ]] && skill_desc="${skill_desc:0:77}..."
      echo "| \`$skill_name\` | $skill_desc |" >> "$readme"
    done
  else
    # Fallback: read from SKILL.md files directly
    for skill_dir in "$SKILLS_DST"/*/; do
      [[ ! -d "$skill_dir" ]] && continue
      local skill_name
      skill_name=$(basename "$skill_dir")
      local skill_file="$skill_dir/SKILL.md"
      if [[ -f "$skill_file" ]]; then
        local skill_desc
        skill_desc=$(grep -A2 '^description:' "$skill_file" 2>/dev/null | tail -1 | sed 's/^ *//' | cut -c1-80 || echo "No description")
        echo "| \`$skill_name\` | $skill_desc |" >> "$readme"
      fi
    done
  fi

  {
    echo ""
    echo "---"
    echo ""
    echo "*Generated by [agentic library](https://github.com/soulcodex/agentic)*"
  } >> "$readme"

  format_markdown "$readme"
}

# ── Create vendor-specific skill symlinks ─────────────────────────────────────
create_skill_symlinks() {
  local vendor="$1"
  [[ -z "$vendor" ]] && return

  echo "  Creating skill symlinks for vendor: $vendor"

  case "$vendor" in
    claude)
      mkdir -p "$TARGET/.claude"
      rm -f "$TARGET/.claude/skills"
      ln -s "../.agentic/skills" "$TARGET/.claude/skills"
      echo "  Linked: .claude/skills → ../.agentic/skills"
      ;;
    opencode)
      mkdir -p "$TARGET/.opencode"
      rm -f "$TARGET/.opencode/skills"
      ln -s "../.agentic/skills" "$TARGET/.opencode/skills"
      echo "  Linked: .opencode/skills → ../.agentic/skills"
      ;;
    codex)
      mkdir -p "$TARGET/.agents"
      rm -f "$TARGET/.agents/skills"
      ln -s "../.agentic/skills" "$TARGET/.agents/skills"
      echo "  Linked: .agents/skills → ../.agentic/skills"
      ;;
    copilot|gemini)
      echo "  $vendor uses prompt-injected skills — no symlink needed"
      ;;
    *)
      echo "  Unknown vendor '$vendor' — skipping skill symlinks"
      ;;
  esac
}

# ── Main ──────────────────────────────────────────────────────────────────────
if [[ "$SKILLS" == "all" ]]; then
  echo "Deploying all skills to $TARGET..."
  while IFS= read -r skill_dir; do
    deploy_skill "$skill_dir"
  done < <(find "$LIBRARY/skills" -maxdepth 3 -name "SKILL.md" -exec dirname {} \; | sort)
else
  echo "Deploying selected skills to $TARGET..."
  IFS=',' read -ra SKILL_NAMES <<< "$SKILLS"
  for name in "${SKILL_NAMES[@]}"; do
    name=$(echo "$name" | tr -d ' ')

    # Handle project: prefix for project-specific skills
    if [[ "$name" == project:* ]]; then
      local_skill_name="${name#project:}"
      deploy_project_skill "$local_skill_name"
      continue
    fi

    skill_dir=$(find "$LIBRARY/skills" -maxdepth 2 -type d -name "$name" | head -1)
    if [[ -z "$skill_dir" ]]; then
      echo "Warning: skill '$name' not found in library — skipping" >&2
      continue
    fi
    deploy_skill "$skill_dir"
  done
fi

# Generate README with skill documentation
generate_skills_readme

# Create vendor-specific symlinks if vendor specified
# Handle comma-separated list of vendors - create symlinks for each
if [[ -n "$VENDOR" ]]; then
  IFS=',' read -ra VENDOR_LIST <<< "$VENDOR"
  for v in "${VENDOR_LIST[@]}"; do
    v=$(echo "$v" | tr -d ' ')
    create_skill_symlinks "$v"
  done
fi

echo ""
echo "Skills deployed to $TARGET/.agentic/skills/"
