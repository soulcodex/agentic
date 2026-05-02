#!/usr/bin/env bash
# cursor/mcp.sh — MCP seeding target for .cursor/mcp.json

seed_cursor_mcp_target() {
  local cursor_mcp_file="$CURSOR_MCP_FILE"
  if [[ -f "$cursor_mcp_file" ]]; then
    if ! jq -e '.mcpServers // {}' "$cursor_mcp_file" > /dev/null 2>&1; then
      echo "Error: existing .cursor/mcp.json is invalid JSON; refusing to overwrite" >&2
      exit 1
    fi
  fi
  if [[ -f "$cursor_mcp_file" || "$SEED_STRATEGY" == "replace" || "${#SEED_SERVER_NAMES[@]}" -gt 0 ]]; then
    local existing_cursor updated_cursor
    existing_cursor="{}"
    if [[ -f "$cursor_mcp_file" ]]; then
      existing_cursor=$(jq '.mcpServers // {}' "$cursor_mcp_file")
    fi

    if [[ "$SEED_STRATEGY" == "replace" ]]; then
      updated_cursor="{}"
      local name
      for name in "${SEED_SERVER_NAMES[@]}"; do
        local server_json
        server_json=$(get_seed_server_json "$name")
        if [[ -n "$server_json" && "$server_json" != "null" ]]; then
          updated_cursor=$(printf '%s' "$updated_cursor" | jq --arg n "$name" --argjson s "$server_json" '. + {($n): $s}')
        fi
      done
    else
      local name
      for name in "${SEED_SERVER_NAMES[@]}"; do
        local exists
        exists=$(jq -r --arg n "$name" 'has($n)' "$existing_cursor" 2>/dev/null || echo "false")
        if [[ "$exists" == "false" ]]; then
          local server_json
          server_json=$(get_seed_server_json "$name")
          if [[ -n "$server_json" && "$server_json" != "null" ]]; then
            existing_cursor=$(printf '%s' "$existing_cursor" | jq --arg n "$name" --argjson s "$server_json" '. + {($n): $s}')
          fi
        fi
      done
      updated_cursor="$existing_cursor"
    fi

    local final_cursor_json
    final_cursor_json=$(printf '{"mcpServers": %s}' "$updated_cursor")
    write_json "$cursor_mcp_file" "$final_cursor_json"
    echo "  ✔  Seeded ${#SEED_SERVER_NAMES[@]} server(s) to .cursor/mcp.json (strategy: $SEED_STRATEGY)"
  fi
}
