#!/usr/bin/env bash
# providers.sh — Optional providers.yaml validation helpers
# Sourced by: compose.sh, sync.sh

# shellcheck source=tooling/lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

validate_providers_config() {
  local target="$1"
  local providers_file="$target/.agentic/providers.yaml"

  [[ ! -f "$providers_file" ]] && return 0

  if ! yq -e '.' "$providers_file" > /dev/null 2>&1; then
    echo "Error: Invalid YAML in $providers_file" >&2
    return 1
  fi

  local default_provider
  default_provider=$(yq '.default_provider // ""' "$providers_file" 2>/dev/null || echo "")
  if [[ -n "$default_provider" && "$default_provider" != "null" && "$default_provider" != "\"\"" ]]; then
    local is_valid=false
    local vendor
    for vendor in "${AGENTIC_VENDORS[@]}"; do
      if [[ "$default_provider" == "$vendor" ]]; then
        is_valid=true
        break
      fi
    done
    if [[ "$is_valid" != "true" ]]; then
      echo "Error: Invalid default_provider '$default_provider' in $providers_file" >&2
      return 1
    fi
  fi

  local provider_keys=()
  while IFS= read -r provider; do
    [[ -z "$provider" || "$provider" == "null" ]] && continue
    provider_keys+=("$provider")
  done < <(yq '.providers | keys | .[]' "$providers_file" 2>/dev/null || true)

  local key
  for key in "${provider_keys[@]}"; do
    local valid_key=false
    local vendor
    for vendor in "${AGENTIC_VENDORS[@]}"; do
      if [[ "$key" == "$vendor" ]]; then
        valid_key=true
        break
      fi
    done
    if [[ "$valid_key" != "true" ]]; then
      echo "Error: Invalid provider key '$key' in $providers_file" >&2
      return 1
    fi

    local enabled_type
    enabled_type=$(yq ".providers.\"$key\".enabled | type" "$providers_file" 2>/dev/null || echo "!!null")
    if [[ "$enabled_type" != "!!null" && "$enabled_type" != "!!bool" ]]; then
      echo "Error: providers.$key.enabled must be boolean in $providers_file" >&2
      return 1
    fi
  done

  return 0
}
