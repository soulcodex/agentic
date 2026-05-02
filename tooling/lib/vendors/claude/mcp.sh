#!/usr/bin/env bash
# claude/mcp.sh — MCP seeding target for .mcp.json

seed_claude_mcp_target() {
  local mcp_file="$TARGET/.mcp.json"
  if [[ -f "$mcp_file" || "$SEED_STRATEGY" == "replace" || "${#SEED_SERVER_NAMES[@]}" -gt 0 ]]; then
    local existing_servers updated_servers
    existing_servers="{}"
    if [[ -f "$mcp_file" ]]; then
      existing_servers=$(jq '.mcpServers // {}' "$mcp_file" 2>/dev/null || echo "{}")
    fi

    if [[ "$SEED_STRATEGY" == "replace" ]]; then
      updated_servers="{}"
      local name
      for name in "${SEED_SERVER_NAMES[@]}"; do
        local server_json
        server_json=$(get_seed_server_json "$name")
        if [[ -n "$server_json" && "$server_json" != "null" ]]; then
          updated_servers=$(printf '%s' "$updated_servers" | jq --arg n "$name" --argjson s "$server_json" '. + {($n): $s}')
        fi
      done
    else
      local name
      for name in "${SEED_SERVER_NAMES[@]}"; do
        local exists
        exists=$(jq -r --arg n "$name" 'has($n)' "$existing_servers" 2>/dev/null || echo "false")
        if [[ "$exists" == "false" ]]; then
          local server_json
          server_json=$(get_seed_server_json "$name")
          if [[ -n "$server_json" && "$server_json" != "null" ]]; then
            existing_servers=$(printf '%s' "$existing_servers" | jq --arg n "$name" --argjson s "$server_json" '. + {($n): $s}')
          fi
        fi
      done
      updated_servers="$existing_servers"
    fi

    local final_json
    final_json=$(printf '{"mcpServers": %s}' "$updated_servers")
    write_json "$mcp_file" "$final_json"
    echo "  ✔  Seeded ${#SEED_SERVER_NAMES[@]} server(s) to .mcp.json (strategy: $SEED_STRATEGY)"
  fi
}
