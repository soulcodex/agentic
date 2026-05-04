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

    target_rel=".agentic/agents/opencode/$name.md"
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

  local subagent_names=()
  while IFS= read -r name; do
    [[ -z "$name" || "$name" == "null" ]] && continue
    subagent_names+=("$name")
  done < <(yq '.subagents | keys | .[]' "$agents_file" 2>/dev/null || true)

  local parent
  for name in "${subagent_names[@]}"; do
    enabled=$(yq -r ".subagents.\"$name\".providers.opencode.enabled" "$agents_file" 2>/dev/null || echo "null")
    [[ "$enabled" == "null" ]] && enabled="true"
    [[ "$enabled" != "true" ]] && continue

    parent=$(yq -r ".subagents.\"$name\".parent // \"\"" "$agents_file" 2>/dev/null || echo "")
    prompt_text=$(yq -r ".subagents.\"$name\".prompt // \"\"" "$agents_file" 2>/dev/null || echo "")
    desc=$(yq -r ".subagents.\"$name\".description // \"\"" "$agents_file" 2>/dev/null || echo "")
    model=$(yq -r ".subagents.\"$name\".providers.opencode.model // \"\"" "$agents_file" 2>/dev/null || echo "")
    reasoning_canonical=$(yq -r ".subagents.\"$name\".providers.opencode.reasoning_effort // \"\"" "$agents_file" 2>/dev/null || echo "")
    reasoning=$(map_reasoning_effort_opencode "$reasoning_canonical")

    if [[ -z "$prompt_text" || "$prompt_text" == "null" ]]; then
      echo "Warning: skipping opencode subagent '$name' because prompt text is empty" >&2
      continue
    fi

    target_rel=".agentic/agents/opencode/$name.subagent.md"
    target_abs="$target/$target_rel"
    tmp_render="$(mktemp "${TMPDIR:-/tmp}/agentic-opencode-subagent-XXXXXX.md")"
    {
      echo "# Subagent: $name"
      echo
      echo "provider: opencode"
      echo "parent: $parent"
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
  local target="$1"
  shift

  local output_dir="$target/.agentic/agents/opencode"
  local output_parent="$target/.agentic/agents"
  local staged_dir
  staged_dir="$(mktemp -d "${TMPDIR:-/tmp}/agentic-opencode-agents-XXXXXX")"

  local entry source_abs target_rel dest_basename
  for entry in "$@"; do
    IFS=$'\t' read -r source_abs _ target_rel <<< "$entry"
    dest_basename="$(basename "$target_rel")"
    cp "$source_abs" "$staged_dir/$dest_basename"
  done

  mkdir -p "$output_parent"
  rm -rf "$output_dir"
  if [[ -n "$(find "$staged_dir" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
    mv "$staged_dir" "$output_dir"
    echo "  ✔  OpenCode agents synced: .agentic/agents/opencode"
  else
    rm -rf "$staged_dir"
    rmdir "$output_parent" 2>/dev/null || true
    echo "  ✔  OpenCode agents cleared: .agentic/agents/opencode"
  fi
}
