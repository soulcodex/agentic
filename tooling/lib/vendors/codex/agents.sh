#!/usr/bin/env bash
# codex/agents.sh — Agents orchestration switching output for Codex

map_reasoning_effort_codex() {
  local canonical="$1"
  case "$canonical" in
    low|medium|high) printf '%s' "$canonical" ;;
    extra_high) printf '%s' "xhigh" ;;
    *) printf '%s' "" ;;
  esac
}

collect_codex_agent_mappings() {
  local target="$1"
  local agents_file="$2"
  local -n mappings_ref="$3"

  local agent_names=()
  while IFS= read -r name; do
    [[ -z "$name" || "$name" == "null" ]] && continue
    agent_names+=("$name")
  done < <(yq '.agents | keys | .[]' "$agents_file" 2>/dev/null || true)

  local name prompt_text desc model reasoning_canonical reasoning enabled target_rel target_abs tmp_render
  for name in "${agent_names[@]}"; do
    enabled=$(yq -r ".agents.\"$name\".providers.codex.enabled" "$agents_file" 2>/dev/null || echo "null")
    [[ "$enabled" == "null" ]] && enabled="true"
    [[ "$enabled" != "true" ]] && continue

    prompt_text=$(yq -r ".agents.\"$name\".prompt // \"\"" "$agents_file" 2>/dev/null || echo "")
    desc=$(yq -r ".agents.\"$name\".description // \"\"" "$agents_file" 2>/dev/null || echo "")
    model=$(yq -r ".agents.\"$name\".providers.codex.model // \"\"" "$agents_file" 2>/dev/null || echo "")
    reasoning_canonical=$(yq -r ".agents.\"$name\".providers.codex.reasoning_effort // \"\"" "$agents_file" 2>/dev/null || echo "")
    reasoning=$(map_reasoning_effort_codex "$reasoning_canonical")

    if [[ -z "$prompt_text" || "$prompt_text" == "null" ]]; then
      echo "Warning: skipping codex agent '$name' because prompt text is empty" >&2
      continue
    fi

    target_rel=".agents/orchestration/$name.md"
    target_abs="$target/$target_rel"
    tmp_render="$(mktemp "${TMPDIR:-/tmp}/agentic-codex-agent-XXXXXX.md")"
    {
      echo "# Agent: $name"
      echo
      echo "provider: codex"
      [[ -n "$model" ]] && echo "model: $model"
      [[ -n "$reasoning" ]] && echo "reasoning_effort: $reasoning"
      echo "description: $desc"
      echo
      printf '%s\n' "$prompt_text"
      echo
    } > "$tmp_render"

    mappings_ref+=("$tmp_render"$'\t'"$target_abs"$'\t'"$target_rel")
  done
}

apply_codex_agent_mappings() {
  local entry source_abs target_abs target_rel

  for entry in "$@"; do
    IFS=$'\t' read -r source_abs target_abs target_rel <<< "$entry"
    mkdir -p "$(dirname "$target_abs")"
    cp "$source_abs" "$target_abs"
    echo "  ✔  Codex agent synced: $target_rel"
  done
}

cleanup_codex_agent_outputs() {
  local target="$1"
  local active="$2"
  shift 2

  local output_dir="$target/.agents/orchestration"
  [[ ! -d "$output_dir" ]] && return 0

  if [[ "$active" != "true" ]]; then
    rm -rf "$output_dir"
    rmdir "$target/.agents" 2>/dev/null || true
    echo "  ✔  Codex agent scaffolds removed (inactive provider)"
    return 0
  fi

  local expected=()
  local entry target_rel basename
  for entry in "$@"; do
    IFS=$'\t' read -r _ _ target_rel <<< "$entry"
    basename=$(basename "$target_rel")
    expected+=("$basename")
  done

  shopt -s nullglob
  local file keep
  for file in "$output_dir"/*.md; do
    keep=false
    basename=$(basename "$file")
    for target_rel in "${expected[@]}"; do
      if [[ "$basename" == "$target_rel" ]]; then
        keep=true
        break
      fi
    done
    if [[ "$keep" == "false" ]]; then
      rm -f "$file"
      echo "  ✔  Codex orphan removed: .agents/orchestration/$basename"
    fi
  done
  shopt -u nullglob

  rmdir "$output_dir" 2>/dev/null || true
  rmdir "$target/.agents" 2>/dev/null || true
}
