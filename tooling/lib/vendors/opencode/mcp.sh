#!/usr/bin/env bash
# opencode/mcp.sh — MCP seeding target for opencode.json

translate_to_opencode() {
  local server_json="$1"
  jq '
    if .type == "stdio" then .type = "local"
    elif .type == "http" then .type = "remote"
    else . end
    |
    if .command != null then
      . + { "command": ([ .command ] + (if .args != null then .args else [] end)) }
      | del(.args)
    else . end
    |
    if .env != null then
      . + { "environment": .env } | del(.env)
    else . end
  ' <<< "$server_json"
}

seed_opencode_mcp_target() {
  local opencode_file="$TARGET/opencode.json"
  if [[ -f "$opencode_file" ]]; then
    local existing_oc updated_oc
    existing_oc=$(jq '.mcp // {}' "$opencode_file" 2>/dev/null || echo "{}")

    if [[ "$SEED_STRATEGY" == "replace" ]]; then
      updated_oc="{}"
      local name
      for name in "${SEED_SERVER_NAMES[@]}"; do
        local server_json oc_entry
        server_json=$(get_seed_server_json "$name")
        if [[ -n "$server_json" && "$server_json" != "null" ]]; then
          oc_entry=$(translate_to_opencode "$server_json")
          updated_oc=$(printf '%s' "$updated_oc" | jq --arg n "$name" --argjson s "$oc_entry" '. + {($n): $s}')
        fi
      done
    else
      local name
      for name in "${SEED_SERVER_NAMES[@]}"; do
        local exists
        exists=$(printf '%s' "$existing_oc" | jq -r --arg n "$name" 'has($n)')
        if [[ "$exists" == "false" ]]; then
          local server_json oc_entry
          server_json=$(get_seed_server_json "$name")
          if [[ -n "$server_json" && "$server_json" != "null" ]]; then
            oc_entry=$(translate_to_opencode "$server_json")
            existing_oc=$(printf '%s' "$existing_oc" | jq --arg n "$name" --argjson s "$oc_entry" '. + {($n): $s}')
          fi
        fi
      done
      updated_oc="$existing_oc"
    fi

    local opencode_base final_opencode
    opencode_base=$(cat "$opencode_file")
    final_opencode=$(printf '%s' "$opencode_base" | jq --argjson mcp "$updated_oc" '. + {mcp: $mcp}')
    write_json "$opencode_file" "$final_opencode"
    echo "  ✔  Seeded ${#SEED_SERVER_NAMES[@]} server(s) to opencode.json (strategy: $SEED_STRATEGY)"
  fi
}
