#!/usr/bin/env bash
# agents.sh — Portable agents sync orchestration
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

  local provider_keys=()
  while IFS= read -r provider; do
    [[ -z "$provider" || "$provider" == "null" ]] && continue
    provider_keys+=("$provider")
  done < <(yq '.providers | keys | .[]' "$agents_file" 2>/dev/null || true)

  local key
  for key in "${provider_keys[@]}"; do
    case "$key" in
      codex|opencode) ;;
      *)
        echo "Error: Invalid provider key '$key' in $agents_file" >&2
        return 1
        ;;
    esac
  done

  return 0
}

sync_portable_agents() {
  local target="$1"
  local agents_file="$target/.agentic/agents.yaml"
  local enabled

  [[ ! -f "$agents_file" ]] && return 0

  validate_agents_config "$target" || return 1

  enabled=$(yq '.enabled // false' "$agents_file" 2>/dev/null || echo "false")
  if [[ "$enabled" != "true" ]]; then
    echo "Portable agents sync: disabled (no-op)."
    return 0
  fi

  echo "Portable agents sync: enabled."
  sync_codex_agents "$target" "$agents_file"
  sync_opencode_agents "$target" "$agents_file"
}
