#!/bin/bash
# mcp.sh — Manage MCP servers in a target project
# Called by: just mcp-add <target> | just mcp-remove <target> <name> | just mcp-list <target>
set -euo pipefail

ACTION=""
TARGET=""
NAME=""
PROFILE_FILE=""
MCP_FILE_INPUT=""
STRATEGY="merge"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --action) ACTION="$2"; shift 2 ;;
    --target) TARGET="$2"; shift 2 ;;
    --name)   NAME="$2";   shift 2 ;;
    --profile-file) PROFILE_FILE="$2"; shift 2 ;;
    --mcp-file) MCP_FILE_INPUT="$2"; shift 2 ;;
    --strategy)     STRATEGY="$2";   shift 2 ;;
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
  # Ensure parent directory exists
  local dir
  dir=$(dirname "$file")
  mkdir -p "$dir"
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

# ── Action: seed ─────────────────────────────────────────────────────────────────
action_seed() {
  local source_file="$1"
  local source_path="$2"
  local strategy="${3:-merge}"
  local servers_expr=""

  if [[ "$source_path" == "." ]]; then
    servers_expr=".servers"
  else
    servers_expr="${source_path}.servers"
  fi

  # Get server names as array first
  local server_names=()
  while IFS= read -r name; do
    [[ -n "$name" && "$name" != "null" ]] && server_names+=("$name")
  done < <(yq "${servers_expr} | keys | .[]" "$source_file" 2>/dev/null || true)

  if [[ ${#server_names[@]} -eq 0 ]]; then
    echo "No MCP servers declared — skipping seed"
    return 0
  fi

  # ── Seed .mcp.json (Claude) ──────────────────────────────────────────
  local mcp_file="$TARGET/.mcp.json"
  # Create or update .mcp.json if: file exists OR strategy is replace OR mcp.servers declared in profile
  if [[ -f "$mcp_file" || "$strategy" == "replace" || "${#server_names[@]}" -gt 0 ]]; then
    local existing_servers updated_servers
    existing_servers="{}"
    if [[ -f "$mcp_file" ]]; then
      existing_servers=$(jq '.mcpServers // {}' "$mcp_file" 2>/dev/null || echo "{}")
    fi

    if [[ "$strategy" == "replace" ]]; then
      # Build fresh JSON from profile - start with empty
      updated_servers="{}"
      local name
      for name in "${server_names[@]}"; do
        local server_yaml server_json
        server_yaml=$(yq -r "${servers_expr}[\"$name\"]" "$source_file" 2>/dev/null || echo "")
        if [[ -n "$server_yaml" && "$server_yaml" != "null" ]]; then
          # Convert YAML to JSON using yq -o json
          server_json=$(echo "$server_yaml" | yq -o json '.' 2>/dev/null || echo "{}")
          updated_servers=$(printf '%s' "$updated_servers" | jq --arg n "$name" --argjson s "$server_json" '. + {($n): $s}')
        fi
      done
    else
      # Merge: add only if key doesn't exist
      local name
      for name in "${server_names[@]}"; do
        local exists
        exists=$(jq -r --arg n "$name" 'has($n)' "$existing_servers" 2>/dev/null || echo "false")
        if [[ "$exists" == "false" ]]; then
          local server_yaml server_json
          server_yaml=$(yq -r "${servers_expr}[\"$name\"]" "$source_file" 2>/dev/null || echo "")
          if [[ -n "$server_yaml" && "$server_yaml" != "null" ]]; then
            # Convert YAML to JSON using yq -o json
            server_json=$(echo "$server_yaml" | yq -o json '.' 2>/dev/null || echo "{}")
            existing_servers=$(printf '%s' "$existing_servers" | jq --arg n "$name" --argjson s "$server_json" '. + {($n): $s}')
          fi
        fi
      done
      updated_servers="$existing_servers"
    fi

    local final_json
    final_json=$(printf '{"mcpServers": %s}' "$updated_servers")
    write_json "$mcp_file" "$final_json"
    echo "  ✔  Seeded ${#server_names[@]} server(s) to .mcp.json (strategy: $strategy)"
  fi

  # ── Helper: translate a profile server entry to Opencode format ─────────
  # Opencode differences from Claude/profile format:
  #   - type: stdio→local, http→remote
  #   - command+args → combined array under "command"
  #   - env → environment
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

  # ── Helper: translate a profile server entry to Gemini format ────────────
  # Gemini differences from Claude/profile format:
  #   - No "type" field (transport inferred from field presence)
  #   - url → httpUrl for http entries
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

  # ── Seed opencode.json (Opencode) ────────────────────────────────────────
  local opencode_file="$TARGET/opencode.json"
  if [[ -f "$opencode_file" ]]; then
    local existing_oc updated_oc
    existing_oc=$(jq '.mcp // {}' "$opencode_file" 2>/dev/null || echo "{}")

    if [[ "$strategy" == "replace" ]]; then
      updated_oc="{}"
      local name
      for name in "${server_names[@]}"; do
        local server_json oc_entry
        server_json=$(yq -o json "${servers_expr}[\"$name\"]" "$source_file" 2>/dev/null || echo "{}")
        if [[ -n "$server_json" && "$server_json" != "null" ]]; then
          oc_entry=$(translate_to_opencode "$server_json")
          updated_oc=$(printf '%s' "$updated_oc" | jq --arg n "$name" --argjson s "$oc_entry" '. + {($n): $s}')
        fi
      done
    else
      # Merge: add only if key doesn't already exist
      local name
      for name in "${server_names[@]}"; do
        local exists
        exists=$(printf '%s' "$existing_oc" | jq -r --arg n "$name" 'has($n)')
        if [[ "$exists" == "false" ]]; then
          local server_json oc_entry
          server_json=$(yq -o json "${servers_expr}[\"$name\"]" "$source_file" 2>/dev/null || echo "{}")
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
    echo "  ✔  Seeded ${#server_names[@]} server(s) to opencode.json (strategy: $strategy)"
  fi

  # ── Seed .gemini/settings.json (Gemini) ──────────────────────────────────
  local gemini_file="$TARGET/.gemini/settings.json"
  if [[ -f "$gemini_file" ]]; then
    local existing_gs updated_gs
    existing_gs=$(jq '.mcpServers // {}' "$gemini_file" 2>/dev/null || echo "{}")

    if [[ "$strategy" == "replace" ]]; then
      updated_gs="{}"
      local name
      for name in "${server_names[@]}"; do
        local server_json gs_entry
        server_json=$(yq -o json "${servers_expr}[\"$name\"]" "$source_file" 2>/dev/null || echo "{}")
        if [[ -n "$server_json" && "$server_json" != "null" ]]; then
          gs_entry=$(translate_to_gemini "$server_json")
          updated_gs=$(printf '%s' "$updated_gs" | jq --arg n "$name" --argjson s "$gs_entry" '. + {($n): $s}')
        fi
      done
    else
      # Merge: add only if key doesn't already exist
      local name
      for name in "${server_names[@]}"; do
        local exists
        exists=$(printf '%s' "$existing_gs" | jq -r --arg n "$name" 'has($n)')
        if [[ "$exists" == "false" ]]; then
          local server_json gs_entry
          server_json=$(yq -o json "${servers_expr}[\"$name\"]" "$source_file" 2>/dev/null || echo "{}")
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
    echo "  ✔  Seeded ${#server_names[@]} server(s) to .gemini/settings.json (strategy: $strategy)"
  fi
}

# ── Dispatch ──────────────────────────────────────────────────────────────────
case "$ACTION" in
  add)    action_add    ;;
  remove) action_remove ;;
  list)   action_list   ;;
  seed)
    # Non-interactive seed from .agentic/mcp.yaml or legacy profile mcp key
    seed_source_file=""
    seed_source_path=""
    if [[ -n "$MCP_FILE_INPUT" ]]; then
      seed_source_file="$MCP_FILE_INPUT"
      seed_source_path="."
    elif [[ -n "$PROFILE_FILE" ]]; then
      seed_source_file="$PROFILE_FILE"
      seed_source_path=".mcp"
    fi

    [[ -z "$seed_source_file" ]] && {
      echo "Error: --mcp-file or --profile-file required for seed action" >&2
      exit 1
    }
    [[ -f "$seed_source_file" ]] || { echo "Error: seed source file not found: $seed_source_file" >&2; exit 1; }
    [[ -z "$TARGET" ]] && { echo "Error: --target required for seed action" >&2; exit 1; }

    # Use default strategy if not provided
    [[ -z "$STRATEGY" ]] && STRATEGY="merge"

    action_seed "$seed_source_file" "$seed_source_path" "$STRATEGY"
    ;;
  *) echo "Error: unknown action '$ACTION' (expected add|remove|list|seed)" >&2; exit 1 ;;
esac
