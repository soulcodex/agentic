#!/usr/bin/env bash
# common.sh — Shared shell utilities for agentic library
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
#
# Provides:
# - ANSI color constants
# - Output helpers (die, warn, info, ok, fail)
# - format_markdown() — canonical markdown formatter
# - safe_rm_rf() — guarded path removal
# - require_arg() — argument validation
# - Version detection (Bash >= 4.0)
# - Vendor registry (AGENTIC_VENDORS array)
# - Path constants
# - Library discovery and config reading helpers

# ══════════════════════════════════════════════════════════════════════════════
# Bash version check
# ══════════════════════════════════════════════════════════════════════════════
check_bash_version() {
  local major
  major=$(echo "$BASH_VERSION" | cut -d. -f1)
  if [[ "$major" -lt 4 ]]; then
    echo "Error: Bash 4.0+ required, but found $BASH_VERSION" >&2
    exit 1
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# ANSI Color constants
# ══════════════════════════════════════════════════════════════════════════════
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# ══════════════════════════════════════════════════════════════════════════════
# Output helpers
# ══════════════════════════════════════════════════════════════════════════════

# Error: print to stderr and exit with code 1
die() {
  echo -e "${RED}Error:${NC} $*" >&2
  exit 1
}

# Warning: print to stderr
warn() {
  echo -e "${YELLOW}Warning:${NC} $*" >&2
}

# Info: print to stdout
info() {
  echo -e "${BLUE}==>${NC} $*"
}

# Success: print to stdout
ok() {
  echo -e "${GREEN}  ✔  ${NC} $*"
}

# Failure: print to stderr
fail() {
  echo -e "  [FAIL] $*" >&2
}

# ══════════════════════════════════════════════════════════════════════════════
# Markdown formatter
# ══════════════════════════════════════════════════════════════════════════════

# Formats markdown files if mdformat is available (optional, silent if missing)
format_markdown() {
  local file="$1"
  if command -v mdformat &>/dev/null; then
    mdformat "$file" 2>/dev/null || true
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# Guarded path removal
# ══════════════════════════════════════════════════════════════════════════════

# Safely remove a path, validating it contains .agentic/ prefix
# Usage: safe_rm_rf <path>
safe_rm_rf() {
  local path="$1"
  if [[ "$path" != *".agentic/"* ]]; then
    die "safe_rm_rf: refusing to remove path not containing '.agentic/': $path"
  fi
  rm -rf "$path"
}

# ══════════════════════════════════════════════════════════════════════════════
# Argument validation
# ══════════════════════════════════════════════════════════════════════════════

# Validate that a required argument is provided
# Usage: require_arg <flag> <value>
# Example: require_arg "--library" "$2"
require_arg() {
  local flag="$1"
  local value="$2"
  if [[ -z "$value" ]]; then
    die "Missing value for $flag. Usage: script $flag <value>"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# Vendor registry
# ══════════════════════════════════════════════════════════════════════════════

# All supported vendors (single source of truth)
export AGENTIC_VENDORS=(claude copilot codex gemini opencode)

# Get vendor skill directory path
# Usage: get_vendor_skill_dir <vendor>
get_vendor_skill_dir() {
  local vendor="$1"
  case "$vendor" in
    claude)   echo ".claude/skills" ;;
    opencode) echo ".opencode/skills" ;;
    codex)    echo ".agents/skills" ;;
    copilot|gemini) echo "" ;; # These vendors use prompt-injected skills
    *)        echo "" ;;
  esac
}

# ══════════════════════════════════════════════════════════════════════════════
# Path constants
# ══════════════════════════════════════════════════════════════════════════════

export AGENTIC_DIR=".agentic"
export AGENTIC_FRAGS_DIR=".agentic/fragments"
export AGENTIC_SKILLS_DIR=".agentic/skills"
export AGENTIC_VENDOR_DIR=".agentic/vendor-files"
export AGENTIC_GENERATED_DIR="_generated"

# ══════════════════════════════════════════════════════════════════════════════
# Library discovery
# ══════════════════════════════════════════════════════════════════════════════

# Priority:
# 1. AGENTIC_REPO_ROOT env var
# 2. AGENTIC_ROOT env var (alias)
# 3. agentic_root from .agentic/config.yaml in current/parent directories
# 4. LIBRARY_ROOT (set at install time by install.sh)
# 5. Fail with helpful error
discover_library() {
  # 1. AGENTIC_REPO_ROOT env var
  if [[ -n "${AGENTIC_REPO_ROOT:-}" ]]; then
    if [[ -d "$AGENTIC_REPO_ROOT" ]]; then
      echo "$AGENTIC_REPO_ROOT"
      return 0
    else
      die "AGENTIC_REPO_ROOT is set but directory does not exist: $AGENTIC_REPO_ROOT"
    fi
  fi

  # 2. AGENTIC_ROOT env var (alias)
  if [[ -n "${AGENTIC_ROOT:-}" ]]; then
    if [[ -d "$AGENTIC_ROOT" ]]; then
      echo "$AGENTIC_ROOT"
      return 0
    else
      die "AGENTIC_ROOT is set but directory does not exist: $AGENTIC_ROOT"
    fi
  fi

  # 3. Read from .agentic/config.yaml in current and parent directories (limited depth)
  local dir="$PWD"
  local depth=0
  local max_depth=1  # Only current directory + one parent for library discovery
  # Ensure we don't walk above the user home directory
  local home_parent
  home_parent=$(dirname "$HOME")
  while [[ "$dir" != "$home_parent" && "$dir" != "/" && $depth -le $max_depth ]]; do
    local config_file="$dir/.agentic/config.yaml"
    if [[ -f "$config_file" ]]; then
      local lib_path
      lib_path="$(yq '.agentic_root // ""' "$config_file" 2>/dev/null || true)"
      if [[ -n "$lib_path" && "$lib_path" != "null" && "$lib_path" != '""' ]]; then
        # Resolve relative paths relative to the config file's directory
        if [[ "$lib_path" != /* ]]; then
          lib_path="$(cd "$dir" && cd "$lib_path" 2>/dev/null && pwd)" || true
        fi
        if [[ -n "$lib_path" && -d "$lib_path" ]]; then
          echo "$lib_path"
          return 0
        fi
      fi
    fi
    dir="$(dirname "$dir")"
    depth=$((depth + 1))
  done

  # 4. LIBRARY_ROOT from install-time embedding (set by install.sh)
  if [[ -n "${LIBRARY_ROOT:-}" && -d "$LIBRARY_ROOT" ]]; then
    echo "$LIBRARY_ROOT"
    return 0
  fi

  # 5. Fail with helpful error
  die "Cannot find agentic library. Set AGENTIC_REPO_ROOT environment variable or add 'agentic_root' to .agentic/config.yaml"
}

# Finds .agentic/config.yaml in current + immediate parent only (for library discovery)
find_target_config() {
  local dir="$PWD"
  # Check current directory only (safe for tests)
  if [[ -f "$dir/.agentic/config.yaml" ]]; then
    echo "$dir/.agentic/config.yaml"
    return 0
  fi
  # Check immediate parent only
  dir="$(dirname "$dir")"
  if [[ -f "$dir/.agentic/config.yaml" ]]; then
    echo "$dir/.agentic/config.yaml"
    return 0
  fi
  return 1
}

# Deep config search for discover_target (allows multiple parent levels)
find_target_config_deep() {
  local dir="$PWD"
  local depth=0
  local max_depth=4
  while [[ "$dir" != "/" && $depth -le $max_depth ]]; do
    if [[ -f "$dir/.agentic/config.yaml" ]]; then
      echo "$dir/.agentic/config.yaml"
      return 0
    fi
    dir="$(dirname "$dir")"
    depth=$((depth + 1))
  done
  return 1
}

# Returns the target directory (parent of .agentic/)
# Allows deeper search for project structure (like src/deep/nested in tests)
discover_target() {
  local config_path
  config_path="$(find_target_config_deep)" || true
  if [[ -n "$config_path" ]]; then
    dirname "$(dirname "$config_path")"
    return 0
  fi
  return 1
}

# ══════════════════════════════════════════════════════════════════════════════
# Config reading helpers
# ══════════════════════════════════════════════════════════════════════════════

# Read active vendors from config, handling both array and legacy string formats
# Usage: read_active_vendors <config_file>
# Returns: comma-separated vendor string
read_active_vendors() {
  local config="$1"
  local vendors=""
  
  if [[ -f "$config" ]]; then
    # Try new array format first, fall back to old string format
    vendors=$(yq '.active_vendors // [] | join(",")' "$config" 2>/dev/null || true)
    if [[ -z "$vendors" || "$vendors" == "null" ]]; then
      # Fallback to old format
      vendors=$(yq '.active_vendor // ""' "$config" 2>/dev/null || true)
      [[ "$vendors" == "null" ]] && vendors=""
    fi
  fi
  
  echo "$vendors"
}