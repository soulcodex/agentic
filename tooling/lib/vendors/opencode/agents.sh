#!/usr/bin/env bash
# opencode/agents.sh — Agents orchestration switching output for OpenCode

map_reasoning_effort_opencode() {
  local canonical="$1"
  case "$canonical" in
    low|medium|high) printf '%s' "$canonical" ;;
    extra_high) printf '%s' "xhigh" ;;
    *) printf '%s' "" ;;
  esac
}

collect_opencode_agent_mappings() {
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
    enabled=$(yq -r ".agents.\"$name\".providers.opencode.enabled" "$agents_file" 2>/dev/null || echo "null")
    [[ "$enabled" == "null" ]] && enabled="true"
    [[ "$enabled" != "true" ]] && continue

    prompt_text=$(yq -r ".agents.\"$name\".prompt // \"\"" "$agents_file" 2>/dev/null || echo "")
    desc=$(yq -r ".agents.\"$name\".description // \"\"" "$agents_file" 2>/dev/null || echo "")
    model=$(yq -r ".agents.\"$name\".providers.opencode.model // \"\"" "$agents_file" 2>/dev/null || echo "")
    reasoning_canonical=$(yq -r ".agents.\"$name\".providers.opencode.reasoning_effort // \"\"" "$agents_file" 2>/dev/null || echo "")
    reasoning=$(map_reasoning_effort_opencode "$reasoning_canonical")

    if [[ -z "$prompt_text" || "$prompt_text" == "null" ]]; then
      echo "Warning: skipping opencode agent '$name' because prompt text is empty" >&2
      continue
    fi

    target_rel=".opencode/agents/$name.md"
    target_abs="$target/$target_rel"
    tmp_render="$(mktemp "${TMPDIR:-/tmp}/agentic-opencode-agent-XXXXXX.md")"
    {
      echo "# Agent: $name"
      echo
      echo "provider: opencode"
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

apply_opencode_agent_mappings() {
  local entry source_abs target_abs target_rel

  for entry in "$@"; do
    IFS=$'\t' read -r source_abs target_abs target_rel <<< "$entry"
    mkdir -p "$(dirname "$target_abs")"
    cp "$source_abs" "$target_abs"
    echo "  ✔  OpenCode agent synced: $target_rel"
  done
}
