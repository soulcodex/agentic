#!/bin/bash
# cli.sh — CLI logic for the agentic global CLI
# Sourced by: bin/agentic
# Provides: main(), discover_library(), discover_target(), and all command handlers

# ── Version ───────────────────────────────────────────────────────────────────
VERSION="1.0.0"

# ── Output helpers ────────────────────────────────────────────────────────────
die() {
  echo "Error: $*" >&2
  exit 1
}

warn() {
  echo "Warning: $*" >&2
}

info() {
  echo "$*"
}

# ── Library discovery ─────────────────────────────────────────────────────────
# Priority:
# 1. AGENTIC_REPO_ROOT env var
# 2. AGENTIC_ROOT env var (alias)
# 3. agentic_root from .agentic/config.yaml in current/parent directories
# 4. Fail with helpful error
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

  # 3. Read from .agentic/config.yaml in current/parent directories
  local config_path
  config_path="$(find_target_config)"
  if [[ -n "$config_path" && -f "$config_path" ]]; then
    local lib_path
    lib_path="$(yq '.agentic_root // ""' "$config_path" 2>/dev/null || true)"
    if [[ -n "$lib_path" && "$lib_path" != "null" && "$lib_path" != '""' ]]; then
      # Resolve relative paths
      if [[ "$lib_path" != /* ]]; then
        local config_dir
        config_dir="$(dirname "$config_path")"
        lib_path="$(cd "$config_dir" && cd "$lib_path" 2>/dev/null && pwd)" || true
      fi
      if [[ -n "$lib_path" && -d "$lib_path" ]]; then
        echo "$lib_path"
        return 0
      fi
    fi
  fi

  # 4. Fail with helpful error
  die "Cannot find agentic library. Set AGENTIC_REPO_ROOT environment variable or add 'agentic_root' to .agentic/config.yaml"
}

# ── Target auto-detection ─────────────────────────────────────────────────────
# Walks up from current directory to find .agentic/config.yaml
find_target_config() {
  local dir="$PWD"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "$dir/.agentic/config.yaml" ]]; then
      echo "$dir/.agentic/config.yaml"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

# Returns the target directory (parent of .agentic/)
discover_target() {
  local config_path
  config_path="$(find_target_config)" || true
  if [[ -n "$config_path" ]]; then
    dirname "$(dirname "$config_path")"
    return 0
  fi
  return 1
}

# ── Help system ───────────────────────────────────────────────────────────────
show_help() {
  cat <<'EOF'
agentic — Global CLI for the agentic library

Usage:
  agentic <command> [options]

Commands:
  deploy <profile> [target] <vendors>   Full deploy: compose + vendor-gen + skills + activate
  compose <profile> [target]            Assemble AGENTS.md from a profile
  switch [target] <vendors>             Switch active vendor(s) via symlinks
  sync [target]                         Regenerate from local profile
  list <resource>                       List profiles, skills, fragments, or vendors

  version                               Show version
  help                                  Show this help

Options:
  --full          Inline all fragment content (monolithic AGENTS.md)
  --skills LIST   Deploy specific skills (default: all from profile)
  --help          Show help for a command

Target Auto-detection:
  If [target] is omitted, agentic looks for .agentic/config.yaml in the
  current directory or parent directories.

Library Discovery:
  1. AGENTIC_REPO_ROOT environment variable
  2. AGENTIC_ROOT environment variable (alias)
  3. 'agentic_root' key in .agentic/config.yaml
  4. Error with instructions

Examples:
  agentic deploy typescript-hexagonal-microservice ./my-project claude
  agentic switch claude,copilot
  agentic sync
  agentic list profiles
EOF
}

show_deploy_help() {
  cat <<'EOF'
agentic deploy — Full deployment pipeline

Usage:
  agentic deploy <profile> [target] <vendors> [options]

Arguments:
  profile    Name of the profile to use (see: agentic list profiles)
  target     Target project directory (auto-detected if omitted)
  vendors    Comma-separated list of vendors to activate (e.g., claude,copilot)

Options:
  --full          Inline all fragment content into AGENTS.md
  --skills LIST   Comma-separated skills to deploy (default: all from profile)

Examples:
  agentic deploy golang-hexagonal-cobra-cli ./my-cli claude
  agentic deploy typescript-hexagonal-microservice . claude,copilot --skills code-review,write-adr
  agentic deploy python-fastapi-microservice /path/to/project gemini --full
EOF
}

show_compose_help() {
  cat <<'EOF'
agentic compose — Assemble AGENTS.md from a profile

Usage:
  agentic compose <profile> [target] [options]

Arguments:
  profile    Name of the profile to use (see: agentic list profiles)
  target     Target project directory (auto-detected if omitted)

Options:
  --full     Inline all fragment content into AGENTS.md (monolithic mode)

Examples:
  agentic compose golang-hexagonal-cobra-cli ./my-cli
  agentic compose typescript-hexagonal-microservice --full
EOF
}

show_switch_help() {
  cat <<'EOF'
agentic switch — Switch active vendor(s)

Usage:
  agentic switch [target] <vendors>
  agentic switch [target] list

Arguments:
  target     Target project directory (auto-detected if omitted)
  vendors    Comma-separated list of vendors to activate
             Use "list" to show available vendors

Examples:
  agentic switch claude
  agentic switch ./my-project gemini
  agentic switch claude,copilot
  agentic switch list
EOF
}

show_sync_help() {
  cat <<'EOF'
agentic sync — Regenerate from local profile

Usage:
  agentic sync [target]

Arguments:
  target     Target project directory (auto-detected if omitted)

Description:
  Regenerates AGENTS.md and vendor files from the local .agentic/profile.yaml.
  Active vendors are preserved after regeneration.

Examples:
  agentic sync
  agentic sync ./my-project
EOF
}

show_list_help() {
  cat <<'EOF'
agentic list — List available resources

Usage:
  agentic list <resource>

Resources:
  profiles    List available composition profiles
  skills      List available skills
  fragments   List available fragments
  vendors     List supported vendors

Examples:
  agentic list profiles
  agentic list skills
  agentic list vendors
EOF
}

# ── Command handlers ──────────────────────────────────────────────────────────

cmd_deploy() {
  local profile="" target="" vendors="" skills="all" full_mode=""
  local args=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --full)    full_mode="--full"; shift ;;
      --skills)  skills="$2"; shift 2 ;;
      --help)    show_deploy_help; exit 0 ;;
      -*)        die "Unknown option: $1" ;;
      *)         args+=("$1"); shift ;;
    esac
  done

  # Interpret positional args: profile [target] vendors
  case "${#args[@]}" in
    2)
      # profile vendors (target auto-detected)
      profile="${args[0]}"
      vendors="${args[1]}"
      target="$(discover_target)" || die "Cannot auto-detect target. Specify target directory or run from within a project with .agentic/config.yaml"
      ;;
    3)
      # profile target vendors
      profile="${args[0]}"
      target="${args[1]}"
      vendors="${args[2]}"
      ;;
    *)
      die "Usage: agentic deploy <profile> [target] <vendors> [--full] [--skills LIST]"
      ;;
  esac

  local library
  library="$(discover_library)"

  info "Deploying profile '$profile' to $target with vendors: $vendors"

  # Run compose
  local compose_args=("--library" "$library" "--profile" "$profile" "--target" "$target")
  [[ -n "$full_mode" ]] && compose_args+=("--full")
  bash "$library/tooling/lib/compose.sh" "${compose_args[@]}"

  # Run vendor-gen
  bash "$library/tooling/lib/vendor-gen.sh" \
    --library "$library" \
    --target "$target" \
    --vendors "$vendors"

  # Deploy skills
  bash "$library/tooling/lib/deploy-skills.sh" \
    --library "$library" \
    --target "$target" \
    --skills "$skills" \
    --vendor "$vendors"

  # Activate vendors
  bash "$library/tooling/lib/vendor-switch.sh" \
    --library "$library" \
    --target "$target" \
    "$vendors"

  info ""
  info "Deployed profile '$profile' to $target"
  info "Active vendors: $vendors"
}

cmd_compose() {
  local profile="" target="" full_mode=""
  local args=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --full)  full_mode="--full"; shift ;;
      --help)  show_compose_help; exit 0 ;;
      -*)      die "Unknown option: $1" ;;
      *)       args+=("$1"); shift ;;
    esac
  done

  # Interpret positional args: profile [target]
  case "${#args[@]}" in
    1)
      # profile only (target auto-detected)
      profile="${args[0]}"
      target="$(discover_target)" || die "Cannot auto-detect target. Specify target directory or run from within a project with .agentic/config.yaml"
      ;;
    2)
      # profile target
      profile="${args[0]}"
      target="${args[1]}"
      ;;
    *)
      die "Usage: agentic compose <profile> [target] [--full]"
      ;;
  esac

  local library
  library="$(discover_library)"

  local compose_args=("--library" "$library" "--profile" "$profile" "--target" "$target")
  [[ -n "$full_mode" ]] && compose_args+=("--full")

  bash "$library/tooling/lib/compose.sh" "${compose_args[@]}"
}

cmd_switch() {
  local target="" vendors=""
  local args=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help) show_switch_help; exit 0 ;;
      -*)     die "Unknown option: $1" ;;
      *)      args+=("$1"); shift ;;
    esac
  done

  # Interpret positional args: [target] vendors
  case "${#args[@]}" in
    1)
      # vendors only (target auto-detected)
      vendors="${args[0]}"
      target="$(discover_target)" || die "Cannot auto-detect target. Specify target directory or run from within a project with .agentic/config.yaml"
      ;;
    2)
      # target vendors
      target="${args[0]}"
      vendors="${args[1]}"
      ;;
    *)
      die "Usage: agentic switch [target] <vendors|list>"
      ;;
  esac

  local library
  library="$(discover_library)"

  bash "$library/tooling/lib/vendor-switch.sh" \
    --library "$library" \
    --target "$target" \
    "$vendors"
}

cmd_sync() {
  local target=""
  local args=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help) show_sync_help; exit 0 ;;
      -*)     die "Unknown option: $1" ;;
      *)      args+=("$1"); shift ;;
    esac
  done

  # Interpret positional args: [target]
  case "${#args[@]}" in
    0)
      # target auto-detected
      target="$(discover_target)" || die "Cannot auto-detect target. Specify target directory or run from within a project with .agentic/config.yaml"
      ;;
    1)
      target="${args[0]}"
      ;;
    *)
      die "Usage: agentic sync [target]"
      ;;
  esac

  local library
  library="$(discover_library)"

  bash "$library/tooling/lib/sync.sh" --target "$target"
}

cmd_list() {
  local resource=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help) show_list_help; exit 0 ;;
      -*)     die "Unknown option: $1" ;;
      *)      resource="$1"; shift ;;
    esac
  done

  [[ -z "$resource" ]] && die "Usage: agentic list <profiles|skills|fragments|vendors>"

  local library
  library="$(discover_library)"

  case "$resource" in
    profiles)
      echo "Available profiles:"
      for f in "$library/profiles/"*.yaml; do
        local name desc
        name="$(basename "$f" .yaml)"
        desc="$(yq '.meta.description' "$f" 2>/dev/null | tr -d '\n' | cut -c1-80)"
        printf "  %-45s %s\n" "$name" "$desc"
      done
      ;;
    skills)
      echo "Available skills:"
      find "$library/skills" -name "SKILL.md" | sort | while read -r f; do
        local dir group name desc
        dir="$(dirname "$f")"
        group="$(basename "$(dirname "$dir")")"
        name="$(basename "$dir")"
        desc="$(grep '^description:' "$f" -A2 | head -3 | tail -1 | sed 's/^ *//' | cut -c1-60)"
        printf "  %-12s %-25s %s\n" "$group" "$name" "$desc"
      done
      ;;
    fragments)
      echo "Available fragments:"
      find "$library/agents" -name "*.md" | sort | while read -r f; do
        local rel="${f#$library/agents/}"
        printf "  %s\n" "${rel%.md}"
      done
      ;;
    vendors)
      echo "Supported vendors:"
      echo "  claude     Claude Code (CLAUDE.md, .claude/)"
      echo "  copilot    GitHub Copilot (.github/copilot-instructions.md)"
      echo "  codex      OpenAI Codex (AGENTS.md, .agents/)"
      echo "  gemini     Gemini CLI (.gemini/systemPrompt.md)"
      echo "  opencode   Opencode (opencode.json, .opencode/)"
      ;;
    *)
      die "Unknown resource: $resource. Use: profiles, skills, fragments, vendors"
      ;;
  esac
}

cmd_version() {
  echo "agentic version $VERSION"
}

# ── Main entry point ──────────────────────────────────────────────────────────
main() {
  local command=""

  # Handle global flags before command
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)
        show_help
        exit 0
        ;;
      --version|-v)
        cmd_version
        exit 0
        ;;
      -*)
        die "Unknown global option: $1. Use 'agentic --help' for usage."
        ;;
      *)
        command="$1"
        shift
        break
        ;;
    esac
  done

  [[ -z "$command" ]] && { show_help; exit 0; }

  case "$command" in
    deploy)  cmd_deploy "$@" ;;
    compose) cmd_compose "$@" ;;
    switch)  cmd_switch "$@" ;;
    sync)    cmd_sync "$@" ;;
    list)    cmd_list "$@" ;;
    version) cmd_version ;;
    help)    show_help ;;
    *)       die "Unknown command: $command. Use 'agentic --help' for usage." ;;
  esac
}
