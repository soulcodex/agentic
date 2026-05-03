#!/usr/bin/env bash
# opencode/agents.sh — Portable agents mapping for OpenCode

sync_opencode_agents() {
  local target="$1"
  local agents_file="$2"
  local enabled
  enabled=$(yq '.providers.opencode.enabled // false' "$agents_file" 2>/dev/null || echo "false")
  [[ "$enabled" != "true" ]] && return 0

  local mapping_count idx source_rel target_rel source_abs target_abs
  mapping_count=$(yq '.providers.opencode.mappings | length' "$agents_file" 2>/dev/null || echo 0)
  [[ "$mapping_count" == "null" ]] && mapping_count=0
  [[ "$mapping_count" -eq 0 ]] && return 0

  for ((idx = 0; idx < mapping_count; idx++)); do
    source_rel=$(yq ".providers.opencode.mappings[$idx].source // \"\"" "$agents_file" 2>/dev/null || echo "")
    target_rel=$(yq ".providers.opencode.mappings[$idx].target // \"\"" "$agents_file" 2>/dev/null || echo "")

    if [[ -z "$source_rel" || -z "$target_rel" || "$source_rel" == "null" || "$target_rel" == "null" ]]; then
      echo "Warning: skipping invalid opencode mapping at index $idx in $agents_file" >&2
      continue
    fi
    if [[ "$source_rel" == /* || "$target_rel" == /* ]]; then
      echo "Warning: opencode mappings must use project-relative paths; skipping index $idx" >&2
      continue
    fi

    source_abs="$target/$source_rel"
    target_abs="$target/$target_rel"
    if [[ ! -f "$source_abs" ]]; then
      echo "Warning: opencode mapping source not found: $source_rel" >&2
      continue
    fi

    mkdir -p "$(dirname "$target_abs")"
    cp "$source_abs" "$target_abs"
    echo "  ✔  OpenCode agent synced: $source_rel -> $target_rel"
  done
}
