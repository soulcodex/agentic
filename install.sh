#!/bin/bash
# install.sh — Remote installer for the agentic library
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash
#   curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash -s -- --dir ~/my-agentic
#   curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash -s -- --global
#
# Options:
#   --dir PATH    Install library to PATH (default: ~/.agentic)
#   --global      Install CLI to /usr/local/bin instead of ~/.local/bin
#   --branch REF  Clone specific branch/tag (default: main)
#   --help        Show this help
#
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
DEFAULT_INSTALL_DIR="$HOME/.local/share/agentic"
DEFAULT_BRANCH="main"
REPO_URL="https://github.com/soulcodex/agentic.git"

# ── Output helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

die() {
  echo -e "${RED}Error:${NC} $*" >&2
  exit 1
}

info() {
  echo -e "${BLUE}==>${NC} $*"
}

success() {
  echo -e "${GREEN}==>${NC} $*"
}

warn() {
  echo -e "${YELLOW}Warning:${NC} $*"
}

# ── Dependency checks ─────────────────────────────────────────────────────────
check_dependencies() {
  local missing=()

  command -v git >/dev/null 2>&1 || missing+=("git")
  command -v bash >/dev/null 2>&1 || missing+=("bash")

  # Check for just (required for install)
  if ! command -v just >/dev/null 2>&1; then
    missing+=("just")
  fi

  # Check for yq (required by agentic)
  if ! command -v yq >/dev/null 2>&1; then
    missing+=("yq")
  fi

  # Check for jq (required by agentic)
  if ! command -v jq >/dev/null 2>&1; then
    missing+=("jq")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo ""
    die "Missing required tools: ${missing[*]}

Install them first:
  macOS:   brew install ${missing[*]}
  Ubuntu:  sudo apt install ${missing[*]}
  Arch:    sudo pacman -S ${missing[*]}

Then re-run this installer."
  fi
}

# ── Help ──────────────────────────────────────────────────────────────────────
show_help() {
  cat <<'EOF'
agentic installer — One library. One deploy. All your AI tools stay in sync.

Usage:
  curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash
  curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash -s -- [options]

Options:
  --dir PATH    Install library to PATH (default: ~/.local/share/agentic)
  --global      Install CLI to /usr/local/bin instead of ~/.local/bin
  --branch REF  Clone specific branch/tag (default: main)
  --help        Show this help

Examples:
  # Default install (library to ~/.local/share/agentic, CLI to ~/.local/bin)
  curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash

  # Install to custom directory
  curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash -s -- --dir ~/code/agentic

  # Install CLI globally (requires sudo)
  curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash -s -- --global

What this does:
  1. Clones the agentic repository to the specified directory
  2. Installs the 'agentic' CLI to your PATH
  3. Verifies the installation

After installation:
  agentic list profiles    # See available profiles
  agentic --help           # Full command reference
EOF
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  local install_dir="$DEFAULT_INSTALL_DIR"
  local cli_target="local"
  local branch="$DEFAULT_BRANCH"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dir)
        install_dir="$2"
        shift 2
        ;;
      --global)
        cli_target="global"
        shift
        ;;
      --branch)
        branch="$2"
        shift 2
        ;;
      --help|-h)
        show_help
        exit 0
        ;;
      *)
        die "Unknown option: $1. Use --help for usage."
        ;;
    esac
  done

  # Expand ~ in install_dir
  install_dir="${install_dir/#\~/$HOME}"

  echo ""
  echo "  ╭─────────────────────────────────────╮"
  echo "  │     agentic library installer       │"
  echo "  ╰─────────────────────────────────────╯"
  echo ""

  # Check dependencies
  info "Checking dependencies..."
  check_dependencies
  success "All dependencies found"

  # Clone or update repository
  if [[ -d "$install_dir/.git" ]]; then
    info "Updating existing installation at $install_dir..."
    cd "$install_dir"
    git fetch origin
    git checkout "$branch"
    git pull origin "$branch"
    success "Updated to latest $branch"
  else
    if [[ -d "$install_dir" ]]; then
      die "Directory exists but is not a git repo: $install_dir
Remove it first or choose a different --dir"
    fi

    info "Cloning agentic library to $install_dir..."
    git clone --branch "$branch" "$REPO_URL" "$install_dir"
    success "Cloned successfully"
  fi

  cd "$install_dir"

  # Install CLI
  info "Installing agentic CLI..."
  if [[ "$cli_target" == "global" ]]; then
    just install global
  else
    just install
  fi

  # Verify installation
  echo ""
  if command -v agentic >/dev/null 2>&1; then
    success "Installation complete!"
    echo ""
    echo "  Library: $install_dir"
    echo "  CLI:     $(command -v agentic)"
    echo ""
    echo "  Get started:"
    echo "    agentic list profiles"
    echo "    agentic deploy <profile> <target> <vendors>"
    echo ""
  else
    warn "CLI installed but not found in PATH"
    echo ""
    echo "  Add this to your shell profile (~/.bashrc, ~/.zshrc):"
    if [[ "$cli_target" == "global" ]]; then
      echo "    export PATH=\"/usr/local/bin:\$PATH\""
    else
      echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
    echo ""
    echo "  Then restart your shell or run:"
    echo "    source ~/.bashrc  # or ~/.zshrc"
    echo ""
  fi
}

main "$@"
