#!/bin/bash
# install.sh — Install/uninstall the agentic CLI
# Called by: just install / just uninstall
# Usage: ./install.sh install [local|global]
#        ./install.sh uninstall [local|global]
set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
LOCAL_BIN="$HOME/.local/bin"
GLOBAL_BIN="/usr/local/bin"
CLI_NAME="agentic"

# Resolve script location to find bin/agentic
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIBRARY_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE_BIN="$LIBRARY_ROOT/bin/$CLI_NAME"

# ── Helpers ───────────────────────────────────────────────────────────────────
die() {
  echo "Error: $*" >&2
  exit 1
}

info() {
  echo "$*"
}

warn() {
  echo "Warning: $*" >&2
}

check_path() {
  local dir="$1"
  if [[ ":$PATH:" != *":$dir:"* ]]; then
    warn "$dir is not in your PATH"
    echo ""
    echo "Add this to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo "  export PATH=\"$dir:\$PATH\""
    echo ""
  fi
}

# ── Install ───────────────────────────────────────────────────────────────────
do_install() {
  local target="$1"
  local dest_dir

  case "$target" in
    local)  dest_dir="$LOCAL_BIN" ;;
    global) dest_dir="$GLOBAL_BIN" ;;
    *)      die "Unknown target: $target. Use 'local' or 'global'" ;;
  esac

  # Verify source exists
  [[ ! -f "$SOURCE_BIN" ]] && die "Source binary not found: $SOURCE_BIN"

  # Create destination directory if needed
  if [[ ! -d "$dest_dir" ]]; then
    info "Creating $dest_dir..."
    if [[ "$target" == "global" ]]; then
      sudo mkdir -p "$dest_dir"
    else
      mkdir -p "$dest_dir"
    fi
  fi

  local dest_file="$dest_dir/$CLI_NAME"

  # Install (copy, not symlink, for portability)
  info "Installing $CLI_NAME to $dest_file..."
  if [[ "$target" == "global" ]]; then
    sudo cp "$SOURCE_BIN" "$dest_file"
    sudo chmod +x "$dest_file"
  else
    cp "$SOURCE_BIN" "$dest_file"
    chmod +x "$dest_file"
  fi

  # The installed script needs to reference the library location
  # We embed the library path at install time
  local tmp_file
  tmp_file=$(mktemp)

  cat > "$tmp_file" <<SCRIPT
#!/bin/bash
# agentic — Global CLI for the agentic library
# Installed from: $LIBRARY_ROOT
# Install location: $dest_file
set -euo pipefail

# Library root is fixed at install time
LIBRARY_ROOT="$LIBRARY_ROOT"

# Source the CLI logic
CLI_LIB="\$LIBRARY_ROOT/tooling/lib/cli.sh"
if [[ ! -f "\$CLI_LIB" ]]; then
  echo "Error: CLI library not found at \$CLI_LIB" >&2
  echo "The agentic library may have been moved from: $LIBRARY_ROOT" >&2
  echo "Reinstall with: cd <new-library-path> && just install" >&2
  exit 1
fi

source "\$CLI_LIB"

# Run the CLI
main "\$@"
SCRIPT

  if [[ "$target" == "global" ]]; then
    sudo mv "$tmp_file" "$dest_file"
    sudo chmod +x "$dest_file"
  else
    mv "$tmp_file" "$dest_file"
    chmod +x "$dest_file"
  fi

  info "Installed successfully!"
  info ""

  # Check if destination is in PATH
  check_path "$dest_dir"

  info "Usage: $CLI_NAME --help"
}

# ── Uninstall ─────────────────────────────────────────────────────────────────
do_uninstall() {
  local target="$1"
  local dest_dir

  case "$target" in
    local)  dest_dir="$LOCAL_BIN" ;;
    global) dest_dir="$GLOBAL_BIN" ;;
    *)      die "Unknown target: $target. Use 'local' or 'global'" ;;
  esac

  local dest_file="$dest_dir/$CLI_NAME"

  if [[ ! -f "$dest_file" ]]; then
    info "$CLI_NAME is not installed at $dest_file"
    return 0
  fi

  info "Removing $dest_file..."
  if [[ "$target" == "global" ]]; then
    sudo rm -f "$dest_file"
  else
    rm -f "$dest_file"
  fi

  info "Uninstalled successfully!"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  local action="${1:-}"
  local target="${2:-local}"

  case "$action" in
    install)   do_install "$target" ;;
    uninstall) do_uninstall "$target" ;;
    *)
      echo "Usage: $0 <install|uninstall> [local|global]"
      echo ""
      echo "Locations:"
      echo "  local   Install to ~/.local/bin (default)"
      echo "  global  Install to /usr/local/bin (requires sudo)"
      exit 1
      ;;
  esac
}

main "$@"
