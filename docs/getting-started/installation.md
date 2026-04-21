# Installation

## Prerequisites

| Tool | Purpose | macOS | Linux |
|---|---|---|---|
| `bash` | Shell runtime | Pre-installed | Pre-installed |
| `git` | Clone the library | Pre-installed | `sudo apt install git` / `sudo dnf install git` |
| `just` | Task runner | `brew install just` | `cargo install just` or [prebuilt binary](https://just.systems) |
| `yq` | YAML processor | `brew install yq` | `snap install yq` or [prebuilt binary](https://github.com/mikefarah/yq/releases) |
| `jq` | JSON processor | `brew install jq` | `sudo apt install jq` / `sudo dnf install jq` |

On macOS, run `just setup` from the library directory to auto-install missing tools via Homebrew.
On Linux, install missing tools with your package manager then run `just setup` to verify.

## One-line Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash
```

Clones the library to `~/.local/share/agentic`, installs the `agentic` CLI to `~/.local/bin`,
and checks that all prerequisites are present before proceeding.

After installation, ensure `~/.local/bin` is in your `PATH`:

**macOS (zsh):**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

**Linux (bash):**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

**Linux/macOS (fish):**
```bash
fish_add_path ~/.local/bin
```

## Manual Install

Once prerequisites are met:

```bash
# 1. Clone the library
git clone https://github.com/soulcodex/agentic ~/agentic-library

# 2. Install the global CLI
cd ~/agentic-library
just install
# Installs to ~/.local/bin — add to PATH if needed (see PATH section above)
```

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
