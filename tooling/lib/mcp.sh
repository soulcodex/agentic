#!/bin/bash
# mcp.sh — Manage MCP servers in a target project
# Called by: just mcp-add <target> | just mcp-remove <target> <name> | just mcp-list <target>
set -euo pipefail

ACTION=""
TARGET=""
NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action) ACTION="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --name)   NAME="$2";   shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$ACTION" ]] && { echo "Error: --action required (add|remove|list)" >&2; exit 1; }
[[ -z "$TARGET" ]] && { echo "Error: --target required" >&2; exit 1; }

MCP_FILE="$TARGET/.mcp.json"
OPENCODE_FILE="$TARGET/opencode.json"
GEMINI_SETTINGS="$TARGET/.gemini/settings.json"

# ── Helpers ───────────────────────────────────────────────────────────────────

# Atomic JSON write: write to tmp then move
write_json() {
  local file="$1"
  local content="$2"
  local tmp
  tmp=$(mktemp)
  printf '%s\n' "$content" > "$tmp"
  mv "$tmp" "$file"
}

# Ensure .mcp.json exists with base structure
ensure_mcp_file() {
  if [[ ! -f "$MCP_FILE" ]]; then
    write_json "$MCP_FILE" '{"mcpServers":{}}'
  fi
}

# Prompt [Y/n] — default Yes
confirm_yes() {
  local prompt="$1"
  local answer
  printf '%s [Y/n]: ' "$prompt"
  read -r answer </dev/tty
  [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]]
}

# Prompt [y/N] — default No
confirm_no() {
  local prompt="$1"
  local answer
  printf '%s [y/N]: ' "$prompt"
  read -r answer </dev/tty
  [[ "$answer" =~ ^[Yy]$ ]]
}

# ── Action: list ──────────────────────────────────────────────────────────────
action_list() {
  if [[ ! -f "$MCP_FILE" ]]; then
    echo "No MCP servers configured (no .mcp.json found in $TARGET)"
    return
  fi

  local count
  count=$(jq '.mcpServers | length' "$MCP_FILE")
  if [[ "$count" -eq 0 ]]; then
    echo "No MCP servers configured."
    return
  fi

  printf '%-20s %-8s %s\n' "NAME" "TYPE" "COMMAND / URL"
  printf '%-20s %-8s %s\n' "----" "----" "-------------"

  jq -r '.mcpServers | to_entries[] | [.key, (.value.type // "stdio"), (if .value.url then .value.url elif .value.command then (.value.command + " " + ((.value.args // []) | join(" "))) else "" end)] | @tsv' "$MCP_FILE" | \
  while IFS=$'\t' read -r name type cmd; do
    printf '%-20s %-8s %s\n' "$name" "$type" "$cmd"
  done
}

# ── Action: add ───────────────────────────────────────────────────────────────
action_add() {
  echo ""
  echo "🔌 MCP Server Setup"
  echo "──────────────────────────────────────────"

  # Server name
  printf 'Server name (e.g. github, postgres, context7): '
  read -r server_name </dev/tty
  [[ -z "$server_name" ]] && { echo "Error: server name is required." >&2; exit 1; }

  # Check for duplicate
  ensure_mcp_file
  existing=$(jq -r --arg n "$server_name" '.mcpServers[$n] // ""' "$MCP_FILE")
  if [[ -n "$existing" ]]; then
    echo "Error: server '$server_name' already exists in .mcp.json" >&2
    exit 1
  fi

  # Transport type
  echo ""
  echo "Transport type:"
  echo "  1) stdio  — local executable (subprocess)"
  echo "  2) http   — remote server (URL)"
  printf 'Choice [1]: '
  read -r transport_choice </dev/tty
  transport_choice="${transport_choice:-1}"

  local entry=""

  if [[ "$transport_choice" == "2" ]]; then
    # HTTP transport
    printf 'Server URL: '
    read -r server_url </dev/tty
    [[ -z "$server_url" ]] && { echo "Error: URL is required for http transport." >&2; exit 1; }

    # Env vars
    local env_json="{}"
    echo ""
    echo "Environment variables (enter empty key to finish):"
    while true; do
      printf '  Key: '
      read -r env_key </dev/tty
      [[ -z "$env_key" ]] && break
      printf '  Value for %s: ' "$env_key"
      read -r env_val </dev/tty
      env_json=$(printf '%s' "$env_json" | jq --arg k "$env_key" --arg v "$env_val" '. + {($k): $v}')
    done

    # Build entry
    if [[ "$env_json" == "{}" ]]; then
      entry=$(jq -n --arg url "$server_url" '{"type":"http","url":$url}')
    else
      entry=$(jq -n --arg url "$server_url" --argjson env "$env_json" '{"type":"http","url":$url,"env":$env}')
    fi

  else
    # stdio transport
    printf 'Command (e.g. npx -y @modelcontextprotocol/server-github): '
    read -r full_command </dev/tty
    [[ -z "$full_command" ]] && { echo "Error: command is required for stdio transport." >&2; exit 1; }

    local cmd_bin args_json
    cmd_bin=$(printf '%s' "$full_command" | awk '{print $1}')
    local args_str
    args_str=$(printf '%s' "$full_command" | cut -d' ' -f2- | xargs -n1 2>/dev/null || true)

    # Build args array safely (bash 3.2 compatible)
    args_json="[]"
    if [[ "$full_command" == *" "* ]]; then
      args_json=$(printf '%s' "$full_command" | awk '{for(i=2;i<=NF;i++) printf "%s\n",$i}' | \
        jq -Rsc 'split("\n") | map(select(. != ""))')
    fi

    # Env vars
    local env_json="{}"
    echo ""
    echo "Environment variables (enter empty key to finish):"
    while true; do
      printf '  Key: '
      read -r env_key </dev/tty
      [[ -z "$env_key" ]] && break
      printf '  Value for %s: ' "$env_key"
      read -r env_val </dev/tty
      env_json=$(printf '%s' "$env_json" | jq --arg k "$env_key" --arg v "$env_val" '. + {($k): $v}')
    done

    # Build entry
    if [[ "$env_json" == "{}" ]]; then
      entry=$(jq -n \
        --arg bin "$cmd_bin" \
        --argjson args "$args_json" \
        '{"type":"stdio","command":$bin,"args":$args}')
    else
      entry=$(jq -n \
        --arg bin "$cmd_bin" \
        --argjson args "$args_json" \
        --argjson env "$env_json" \
        '{"type":"stdio","command":$bin,"args":$args,"env":$env}')
    fi
  fi

  # Preview
  echo ""
  echo "── Preview ───────────────────────────────"
  printf '  "%s": %s\n' "$server_name" "$(printf '%s' "$entry" | jq -c .)"
  echo "──────────────────────────────────────────"
  echo ""

  # Write to .mcp.json
  if confirm_yes "Add to $TARGET/.mcp.json?"; then
    local updated
    updated=$(jq --arg n "$server_name" --argjson e "$entry" '.mcpServers[$n] = $e' "$MCP_FILE")
    write_json "$MCP_FILE" "$updated"
    echo "  ✔  Written to .mcp.json"
  else
    echo "Aborted."
    exit 0
  fi

  # Sync to opencode.json
  if [[ -f "$OPENCODE_FILE" ]]; then
    echo ""
    if confirm_yes "Sync to opencode.json (mcp.$server_name)?"; then
      local oc_updated
      oc_updated=$(jq --arg n "$server_name" --argjson e "$entry" '.mcp[$n] = $e' "$OPENCODE_FILE")
      write_json "$OPENCODE_FILE" "$oc_updated"
      echo "  ✔  Synced to opencode.json"
    fi
  fi

  # Sync to .gemini/settings.json
  if [[ -f "$GEMINI_SETTINGS" ]]; then
    echo ""
    if confirm_yes "Sync to .gemini/settings.json (mcpServers.$server_name)?"; then
      local gs_updated
      gs_updated=$(jq --arg n "$server_name" --argjson e "$entry" '.mcpServers[$n] = $e' "$GEMINI_SETTINGS")
      write_json "$GEMINI_SETTINGS" "$gs_updated"
      echo "  ✔  Synced to .gemini/settings.json"
    fi
  fi

  echo ""
  # Print env var reminders
  local env_keys
  env_keys=$(printf '%s' "$entry" | jq -r '.env // {} | keys[]' 2>/dev/null || true)
  if [[ -n "$env_keys" ]]; then
    echo "Done. Remember to set the following in your environment before starting:"
    while IFS= read -r k; do
      echo "  $k"
    done <<< "$env_keys"
  else
    echo "Done."
  fi
}

# ── Action: remove ────────────────────────────────────────────────────────────
action_remove() {
  [[ -z "$NAME" ]] && { echo "Error: --name required for remove action" >&2; exit 1; }

  if [[ ! -f "$MCP_FILE" ]]; then
    echo "Error: no .mcp.json found in $TARGET" >&2
    exit 1
  fi

  existing=$(jq -r --arg n "$NAME" '.mcpServers[$n] // ""' "$MCP_FILE")
  if [[ -z "$existing" ]]; then
    echo "Error: server '$NAME' not found in .mcp.json" >&2
    exit 1
  fi

  local updated
  updated=$(jq --arg n "$NAME" 'del(.mcpServers[$n])' "$MCP_FILE")
  write_json "$MCP_FILE" "$updated"
  echo "  ✔  Removed '$NAME' from .mcp.json"

  # Sync removal to opencode.json
  if [[ -f "$OPENCODE_FILE" ]]; then
    echo ""
    if confirm_yes "Remove from opencode.json (mcp.$NAME)?"; then
      local oc_updated
      oc_updated=$(jq --arg n "$NAME" 'del(.mcp[$n])' "$OPENCODE_FILE")
      write_json "$OPENCODE_FILE" "$oc_updated"
      echo "  ✔  Removed from opencode.json"
    fi
  fi

  # Sync removal to .gemini/settings.json
  if [[ -f "$GEMINI_SETTINGS" ]]; then
    echo ""
    if confirm_yes "Remove from .gemini/settings.json (mcpServers.$NAME)?"; then
      local gs_updated
      gs_updated=$(jq --arg n "$NAME" 'del(.mcpServers[$n])' "$GEMINI_SETTINGS")
      write_json "$GEMINI_SETTINGS" "$gs_updated"
      echo "  ✔  Removed from .gemini/settings.json"
    fi
  fi

  echo ""
  echo "Done."
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
case "$ACTION" in
  add)    action_add    ;;
  remove) action_remove ;;
  list)   action_list   ;;
  *) echo "Error: unknown action '$ACTION' (expected add|remove|list)" >&2; exit 1 ;;
esac
