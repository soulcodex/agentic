# Installation

## One-line Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/soulcodex/agentic/main/install.sh | bash
```

Clones the library to `~/.local/share/agentic` and installs the `agentic` CLI
to `~/.local/bin`.

After installation, ensure `~/.local/bin` is in your `PATH`.

**macOS (zsh):**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

**Linux (bash):**
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
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

### Linux — PATH persistence

After manual install, add the CLI to your PATH permanently:

```bash
# bash (most Linux distros)
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc

# zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc

# fish
fish_add_path ~/.local/bin
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
