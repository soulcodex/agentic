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

# ── Dependency versions ────────────────────────────────────────────────────────
# Releases: https://github.com/casey/just/releases
JUST_VERSION="1.50.0"

# Releases: https://github.com/mikefarah/yq/releases
YQ_VERSION="v4.53.2"

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
detect_arch() {
  case "$(uname -m)" in
    x86_64)         echo "amd64" ;;
    aarch64|arm64)  echo "arm64" ;;
    armv7l)         echo "armv7" ;;
    *)              echo "unsupported" ;;
  esac
}

install_yq_binary() {
  local arch bin_dir bin_path
  arch="$(detect_arch)"
  [[ "$arch" == "unsupported" ]] && { warn "Unsupported architecture for yq binary install — install manually"; return 1; }
  YQ_VERSION="v4.53.2"
  bin_dir="$HOME/.local/bin"
  [[ "$EUID" -eq 0 ]] && bin_dir="/usr/local/bin"
  mkdir -p "$bin_dir"
  bin_path="$bin_dir/yq"
  info "Downloading yq ${YQ_VERSION} (${arch})..."
  curl -sSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${arch}" \
    -o "$bin_path" && chmod +x "$bin_path"
}

install_just_binary() {
  local arch bin_dir tarball
  arch="$(detect_arch)"
  [[ "$arch" == "unsupported" ]] && { warn "Unsupported architecture for just binary install — install manually"; return 1; }
  JUST_VERSION="1.50.0"
  bin_dir="$HOME/.local/bin"
  [[ "$EUID" -eq 0 ]] && bin_dir="/usr/local/bin"
  mkdir -p "$bin_dir"
  info "Downloading just ${JUST_VERSION} (${arch})..."
  tarball="just-${JUST_VERSION}-${arch}-unknown-linux-musl.tar.gz"
  [[ "$arch" == "armv7" ]] && tarball="just-${JUST_VERSION}-armv7-unknown-linux-musleabihf.tar.gz"
  curl -sSL "https://github.com/casey/just/releases/download/${JUST_VERSION}/${tarball}" \
    | tar -xz -C "$bin_dir" just
}

pkg_install() {
  local pkg_manager="$1" tool="$2"
  local sudo_prefix=""
  [[ "$EUID" -ne 0 ]] && sudo_prefix="sudo"
  case "$pkg_manager" in
    apt)    $sudo_prefix apt-get install -y "$tool" ;;
    dnf)    $sudo_prefix dnf install -y "$tool" ;;
    yum)    $sudo_prefix yum install -y "$tool" ;;
    pacman) $sudo_prefix pacman -S --noconfirm "$tool" ;;
    apk)    $sudo_prefix apk add "$tool" ;;
    zypper) $sudo_prefix zypper install -y "$tool" ;;
  esac
}

install_dependencies() {
  local os
  os="$(uname -s)"

  local missing=()
  for tool in git bash just yq jq; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0

  info "Missing required tools: ${missing[*]}"

  if [[ "$os" == "Darwin" ]]; then
    if command -v brew >/dev/null 2>&1; then
      printf "Auto-install with Homebrew? [y/N] "
      read -r REPLY
      if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        for tool in "${missing[@]}"; do
          info "Installing $tool via Homebrew..."
          brew install "$tool"
        done
      else
        die "Homebrew declined. Install tools manually then re-run this installer."
      fi
    else
      die "Homebrew not found. Install it from https://brew.sh then re-run this installer."
    fi
  elif [[ "$os" == "Linux" ]]; then
<<<<<<< HEAD
    # local distro_id=""  # Removed unused variable
    if [[ -f /etc/os-release ]]; then
      # shellcheck source=/dev/null
      source /etc/os-release
      distro_id="${ID:-}"
    fi
=======
>>>>>>> 059e6d7 (fix(install): remove unused distro_id variable SC2034)
    local pkg_manager=""
    if command -v apt-get >/dev/null 2>&1; then
      pkg_manager="apt"
    elif command -v dnf >/dev/null 2>&1; then
      pkg_manager="dnf"
    elif command -v yum >/dev/null 2>&1; then
      pkg_manager="yum"
    elif command -v pacman >/dev/null 2>&1; then
      pkg_manager="pacman"
    elif command -v apk >/dev/null 2>&1; then
      pkg_manager="apk"
    elif command -v zypper >/dev/null 2>&1; then
      pkg_manager="zypper"
    fi

    if [[ -n "$pkg_manager" ]]; then
      printf "Auto-install missing tools (%s)? [y/N] " "${missing[*]}"
      read -r REPLY
      if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        for tool in "${missing[@]}"; do
          case "$tool" in
            jq|git)
              info "Installing $tool via $pkg_manager..."
              pkg_install "$pkg_manager" "$tool"
              ;;
            yq)
              if [[ "$pkg_manager" == "pacman" ]]; then
                info "Installing yq via $pkg_manager..."
                pkg_install "$pkg_manager" "go-yq"
              else
                install_yq_binary || warn "yq binary install failed — install manually"
              fi
              ;;
            just)
              if [[ "$pkg_manager" == "pacman" ]]; then
                info "Installing just via $pkg_manager..."
                pkg_install "$pkg_manager" "just"
              else
                install_just_binary || warn "just binary install failed — install manually"
              fi
              ;;
            bash)
              warn "bash must be installed via your package manager — install manually"
              ;;
          esac
        done
      else
        printf "\nManual install instructions:\n"
        printf "  jq:   sudo %s install jq\n" \
          "$(case "$pkg_manager" in apt) echo "apt-get" ;; dnf) echo "dnf" ;; yum) echo "yum" ;; pacman) echo "pacman -S" ;; apk) echo "apk add" ;; zypper) echo "zypper install" ;; esac)"
        printf "  git:  sudo %s install git\n" \
          "$(case "$pkg_manager" in apt) echo "apt-get" ;; dnf) echo "dnf" ;; yum) echo "yum" ;; pacman) echo "pacman -S" ;; apk) echo "apk add" ;; zypper) echo "zypper install" ;; esac)"
        printf "  yq:   https://github.com/mikefarah/yq/releases (download binary)\n"
        printf "  just: https://just.systems (download binary or: cargo install just)\n"
        die "Install missing tools and re-run this installer."
      fi
    else
      printf "\nUnknown Linux distribution — cannot auto-install.\n"
      printf "Manual install instructions:\n"
      printf "  jq:   sudo apt-get install jq  /  sudo dnf install jq  /  sudo pacman -S jq\n"
      printf "  git:  sudo apt-get install git  /  sudo dnf install git\n"
      printf "  yq:   https://github.com/mikefarah/yq/releases (download binary)\n"
      printf "  just: https://just.systems (download binary or: cargo install just)\n"
      die "Install missing tools and re-run this installer."
    fi
  else
    die "Unsupported OS: $os. Install tools manually then re-run this installer."
  fi

  # Re-verify all tools
  for tool in "${missing[@]}"; do
    if ! command -v "$tool" >/dev/null 2>&1; then
      die "$tool still missing after install — install it manually then re-run this installer."
    fi
  done
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
  install_dependencies
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
    echo "  Add this to your shell profile:"
    echo ""
    if [[ "$cli_target" == "global" ]]; then
      echo "    bash/zsh:  export PATH=\"/usr/local/bin:\$PATH\""
      echo "    fish:      fish_add_path /usr/local/bin"
    else
      echo "    bash/zsh:  export PATH=\"\$HOME/.local/bin:\$PATH\""
      echo "    fish:      fish_add_path ~/.local/bin"
    fi
    echo ""
    echo "  Then reload your shell:"
    echo "    source ~/.bashrc   # bash"
    echo "    source ~/.zshrc    # zsh"
    echo "    exec fish          # fish"
    echo ""
  fi
}

main "$@"
