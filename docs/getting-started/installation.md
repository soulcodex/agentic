# Installation

## One-line Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash
```

Clones the library to `~/.local/share/agentic` and installs the `agentic` CLI
to `~/.local/bin`.

After installation, ensure `~/.local/bin` is in your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
# Add to ~/.bashrc or ~/.zshrc to make it permanent
```

## Manual Install

```bash
# 1. Clone the library
git clone https://github.com/soulcodex/agentic ~/agentic-library

# 2. Install the global CLI
cd ~/agentic-library
just install
# Installs to ~/.local/bin — add to PATH if needed
```

## Prerequisites

Run `just setup` from the library directory to check and install all required tools:

| Tool | Purpose | Install |
|---|---|---|
| `bash` | Shell runtime | Usually pre-installed |
| `just` | Task runner | `brew install just` / [just.systems](https://just.systems) |
| `yq` | YAML processor | `brew install yq` / [github.com/mikefarah/yq](https://github.com/mikefarah/yq) |
| `jq` | JSON processor | `brew install jq` / [stedolan.github.io/jq](https://stedolan.github.io/jq) |

## Verify Installation

```bash
agentic --help
agentic list profiles
```

## Update

```bash
cd ~/.local/share/agentic   # or wherever you cloned the library
git pull origin main
```

## Uninstall

```bash
cd ~/.local/share/agentic
just uninstall
```
