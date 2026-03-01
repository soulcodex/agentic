#!/usr/bin/env bash
# setup.sh — check prerequisites and offer to install missing tools
# Usage: ./tooling/lib/setup.sh
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ok()   { printf "${GREEN}  ✔  %s${NC}\n" "$1"; }
warn() { printf "${YELLOW}  ✗  %s${NC}\n" "$1"; }
info() { printf "     %s\n" "$1"; }

# Detect OS
OS="$(uname -s)"
MISSING=()

echo ""
echo "Checking prerequisites for agentic…"
echo ""

# Check for required tools
for tool in just yq jq; do
    if command -v "$tool" >/dev/null 2>&1; then
        ok "$tool  ($(command -v "$tool"))"
    else
        warn "$tool  — not found"
        MISSING+=("$tool")
    fi
done

echo ""

if [[ ${#MISSING[@]} -eq 0 ]]; then
    echo "All prerequisites are installed. You're ready to go."
    echo ""
    exit 0
fi

echo "Missing tools: ${MISSING[*]}"
echo ""

if [[ "$OS" == "Darwin" ]] && command -v brew >/dev/null 2>&1; then
    # macOS + Homebrew present — offer to install
    printf "Homebrew detected. Install missing tools now? [y/N] "
    read -r REPLY
    echo ""
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        for tool in "${MISSING[@]}"; do
            echo "Installing $tool…"
            case "$tool" in
                just) brew install just ;;
                yq)   brew install yq ;;
                jq)   brew install jq ;;
            esac
        done
        echo ""
        echo "Done. Run 'just setup' again to verify."
        echo ""
        exit 0
    else
        echo "Skipped. Install manually:"
    fi
elif [[ "$OS" == "Darwin" ]]; then
    echo "Homebrew not found. Install it first: https://brew.sh"
    echo "Then run: brew install ${MISSING[*]}"
    echo ""
    exit 1
else
    # Linux — print platform-specific guidance
    echo "Install missing tools:"
    echo ""
    for tool in "${MISSING[@]}"; do
        case "$tool" in
            just)
                info "just — download from https://github.com/casey/just/releases"
                info "       or: cargo install just  (if Rust is available)"
                ;;
            yq)
                info "yq — wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq"
                ;;
            jq)
                info "jq — apt-get install -y jq  (Debian/Ubuntu)"
                info "      or: dnf install jq      (Fedora/RHEL)"
                ;;
        esac
        echo ""
    done
fi

exit 1
