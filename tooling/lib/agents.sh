#!/usr/bin/env bash
# agents.sh — Agents orchestration switching sync
# Sourced by: sync.sh

# shellcheck source=tooling/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
# shellcheck source=tooling/lib/vendors/codex/agents.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/vendors/codex/agents.sh"
# shellcheck source=tooling/lib/vendors/opencode/agents.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/vendors/opencode/agents.sh"

validate_agents_config() {
  local target="$1"
  local agents_file="$target/.agentic/agents.yaml"

  [[ ! -f "$agents_file" ]] && return 0

  if ! yq -e '.' "$agents_file" > /dev/null 2>&1; then
    echo "Error: Invalid YAML in $agents_file" >&2
    return 1
  fi

  local enabled_type
  enabled_type=$(yq '.enabled | type' "$agents_file" 2>/dev/null || echo "!!null")
  if [[ "$enabled_type" != "!!null" && "$enabled_type" != "!!bool" ]]; then
    echo "Error: enabled must be boolean in $agents_file" >&2
    return 1
  fi

  local version
  version=$(yq '.version // ""' "$agents_file" 2>/dev/null || echo "")
  if [[ "$version" != "1" ]]; then
    echo "Error: version must be \"1\" in $agents_file" >&2
    return 1
  fi

  local enabled
  enabled=$(yq -r '.enabled // false' "$agents_file" 2>/dev/null || echo "false")
  if [[ "$enabled" != "true" ]]; then
    return 0
  fi

  local agent_keys=()
  while IFS= read -r agent; do
    [[ -z "$agent" || "$agent" == "null" ]] && continue
    agent_keys+=("$agent")
  done < <(yq '.agents | keys | .[]' "$agents_file" 2>/dev/null || true)

  local key desc prompt provider_keys provider
  for key in "${agent_keys[@]}"; do
    if [[ ! "$key" =~ ^[a-z]+$ ]]; then
      echo "Error: Invalid agent key '$key' in $agents_file (expected lowercase letters only)" >&2
      return 1
    fi

    desc=$(yq -r ".agents.\"$key\".description // \"\"" "$agents_file" 2>/dev/null || echo "")
    prompt=$(yq -r ".agents.\"$key\".prompt // \"\"" "$agents_file" 2>/dev/null || echo "")
    if [[ -z "$desc" || -z "$prompt" || "$desc" == "null" || "$prompt" == "null" ]]; then
      echo "Error: Agent '$key' must define non-empty description and prompt in $agents_file" >&2
      return 1
    fi

    provider_keys=()
    while IFS= read -r provider; do
      [[ -z "$provider" || "$provider" == "null" ]] && continue
      provider_keys+=("$provider")
    done < <(yq ".agents.\"$key\".providers | keys | .[]" "$agents_file" 2>/dev/null || true)

    for provider in "${provider_keys[@]}"; do
      case "$provider" in
        codex|opencode) ;;
        *)
          echo "Error: Agent '$key' has invalid provider '$provider' in $agents_file" >&2
          return 1
          ;;
      esac
    done
  done

  return 0
}

preflight_portable_agents_mappings() {
  local -n all_mappings_ref="$1"
  local entry source_abs target_abs target_rel

  for entry in "${all_mappings_ref[@]}"; do
    IFS=$'\t' read -r source_abs target_abs target_rel <<< "$entry"

    if [[ -e "$target_abs" ]]; then
      if [[ ! -f "$target_abs" ]]; then
        echo "Error: Unmanaged destination conflict at $target_rel (not a file)" >&2
        return 1
      fi
      if ! cmp -s "$source_abs" "$target_abs"; then
        echo "Error: Unmanaged destination conflict at $target_rel (already exists with different content)" >&2
        return 1
      fi
    fi
  done

  return 0
}

sync_portable_agents() {
  local target="$1"
  local agents_file="$target/.agentic/agents.yaml"
  local enabled
  local agent_count
  local codex_mappings=()
  local opencode_mappings=()
  local all_mappings=()
  local tmp_files=()

  [[ ! -f "$agents_file" ]] && return 0

  validate_agents_config "$target" || return 1

  enabled=$(yq '.enabled // false' "$agents_file" 2>/dev/null || echo "false")
  if [[ "$enabled" != "true" ]]; then
    echo "Agents orchestration switching: disabled (no-op)."
    return 0
  fi

  echo "Agents orchestration switching: enabled."
  agent_count=$(yq '.agents | length' "$agents_file" 2>/dev/null || echo 0)
  [[ "$agent_count" == "null" ]] && agent_count=0
  if [[ "$agent_count" -eq 0 ]]; then
    echo "Warning: agents orchestration switching enabled but no agent definitions found; no mutations applied." >&2
    return 0
  fi

  collect_codex_agent_mappings "$target" "$agents_file" codex_mappings
  collect_opencode_agent_mappings "$target" "$agents_file" opencode_mappings

  if [[ "${#codex_mappings[@]}" -eq 0 && "${#opencode_mappings[@]}" -eq 0 ]]; then
    echo "Warning: agents orchestration switching enabled but no provider outputs resolved; no mutations applied." >&2
    return 0
  fi

  all_mappings=("${codex_mappings[@]}" "${opencode_mappings[@]}")
  local entry rendered_file _
  for entry in "${all_mappings[@]}"; do
    IFS=$'\t' read -r rendered_file _ <<< "$entry"
    tmp_files+=("$rendered_file")
  done

  if ! preflight_portable_agents_mappings all_mappings; then
    local file
    for file in "${tmp_files[@]}"; do
      rm -f "$file"
    done
    return 1
  fi

  apply_codex_agent_mappings "${codex_mappings[@]}"
  apply_opencode_agent_mappings "${opencode_mappings[@]}"

  local file
  for file in "${tmp_files[@]}"; do
    rm -f "$file"
  done
}
