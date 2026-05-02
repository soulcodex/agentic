#!/usr/bin/env bash
# gemini/mcp.sh — MCP seeding target for .gemini/settings.json

translate_to_gemini() {
  local server_json="$1"
  jq '
    if .type == "http" and .url != null then
      . + { "httpUrl": .url } | del(.url)
    else . end
    |
    del(.type)
  ' <<< "$server_json"
}

seed_gemini_mcp_target() {
  local gemini_file="$TARGET/.gemini/settings.json"
  if [[ -f "$gemini_file" ]]; then
    local existing_gs updated_gs
    existing_gs=$(jq '.mcpServers // {}' "$gemini_file" 2>/dev/null || echo "{}")

    if [[ "$SEED_STRATEGY" == "replace" ]]; then
      updated_gs="{}"
      local name
      for name in "${SEED_SERVER_NAMES[@]}"; do
        local server_json gs_entry
        server_json=$(get_seed_server_json "$name")
        if [[ -n "$server_json" && "$server_json" != "null" ]]; then
          gs_entry=$(translate_to_gemini "$server_json")
          updated_gs=$(printf '%s' "$updated_gs" | jq --arg n "$name" --argjson s "$gs_entry" '. + {($n): $s}')
        fi
      done
    else
      local name
      for name in "${SEED_SERVER_NAMES[@]}"; do
        local exists
        exists=$(printf '%s' "$existing_gs" | jq -r --arg n "$name" 'has($n)')
        if [[ "$exists" == "false" ]]; then
          local server_json gs_entry
          server_json=$(get_seed_server_json "$name")
          if [[ -n "$server_json" && "$server_json" != "null" ]]; then
            gs_entry=$(translate_to_gemini "$server_json")
            existing_gs=$(printf '%s' "$existing_gs" | jq --arg n "$name" --argjson s "$gs_entry" '. + {($n): $s}')
          fi
        fi
      done
      updated_gs="$existing_gs"
    fi

    local gemini_base final_gemini
    gemini_base=$(cat "$gemini_file")
    final_gemini=$(printf '%s' "$gemini_base" | jq --argjson mcpServers "$updated_gs" '. + {mcpServers: $mcpServers}')
    write_json "$gemini_file" "$final_gemini"
    echo "  ✔  Seeded ${#SEED_SERVER_NAMES[@]} server(s) to .gemini/settings.json (strategy: $SEED_STRATEGY)"
  fi
}
