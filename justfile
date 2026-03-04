# Agentic Library — Command Runner
# Requires: just, bash, yq, jq
# Install: brew install just yq jq

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := false

LIBRARY_ROOT := justfile_directory()

# Show available commands
default:
    @just --list

# ─── Discovery ────────────────────────────────────────────────────────────────

# List all available composition profiles
list-profiles:
    @echo "Available profiles:"
    @for f in "{{LIBRARY_ROOT}}/profiles/"*.yaml; do \
        name=$(basename "$f" .yaml); \
        desc=$(yq '.meta.description' "$f" | tr -d '\n' | cut -c1-80); \
        printf "  %-45s %s\n" "$name" "$desc"; \
    done

# List all available skills
list-skills:
    @echo "Available skills:"
    @find "{{LIBRARY_ROOT}}/skills" -name "SKILL.md" | sort | while read -r f; do \
        dir=$(dirname "$f"); \
        group=$(basename "$(dirname "$dir")"); \
        name=$(basename "$dir"); \
        desc=$(grep '^description:' "$f" -A2 | head -3 | tail -1 | sed 's/^ *//' | cut -c1-60); \
        printf "  %-12s %-25s %s\n" "$group" "$name" "$desc"; \
    done

# List all available fragments
list-fragments:
    @echo "Available fragments:"
    @find "{{LIBRARY_ROOT}}/agents" -name "*.md" | sort | while read -r f; do \
        rel="${f#{{LIBRARY_ROOT}}/agents/}"; \
        printf "  %s\n" "${rel%.md}"; \
    done

# ─── Composition ──────────────────────────────────────────────────────────────

# Assemble AGENTS.md into a target project from a named profile
# Usage: just compose typescript-hexagonal-microservice /path/to/project
compose profile target:
    @"{{LIBRARY_ROOT}}/tooling/lib/compose.sh" \
        --library "{{LIBRARY_ROOT}}" \
        --profile "{{profile}}" \
        --target "{{target}}"

# Validate an assembled AGENTS.md in a target project
# Usage: just validate /path/to/project
validate target:
    @"{{LIBRARY_ROOT}}/tooling/lib/validate.sh" \
        --library "{{LIBRARY_ROOT}}" \
        --target "{{target}}"

# Check if a project's config has drifted from the current library
# Usage: just sync-check /path/to/project
sync-check target:
    @"{{LIBRARY_ROOT}}/tooling/lib/sync-check.sh" \
        --library "{{LIBRARY_ROOT}}" \
        --target "{{target}}"

# Regenerate a project from its local profile (.agentic/profile.yaml)
# Usage: just sync /path/to/project
sync target:
    @"{{LIBRARY_ROOT}}/tooling/lib/sync.sh" \
        --target "{{target}}"

# ─── Vendor Generation ────────────────────────────────────────────────────────

# Generate vendor-specific files from a target project's AGENTS.md
# Usage: just vendor-gen /path/to/project
# Usage: just vendor-gen /path/to/project claude,copilot
vendor-gen target vendors="all":
    @"{{LIBRARY_ROOT}}/tooling/lib/vendor-gen.sh" \
        --library "{{LIBRARY_ROOT}}" \
        --target "{{target}}" \
        --vendors "{{vendors}}"

# Switch active AI vendor(s) via symlinks (supports multiple: claude,copilot)
# Usage: just vendor-switch /path/to/project gemini
# Usage: just vendor-switch /path/to/project claude,copilot
# Usage: just vendor-switch /path/to/project list
vendor-switch target vendor:
    @"{{LIBRARY_ROOT}}/tooling/lib/vendor-switch.sh" \
        --library "{{LIBRARY_ROOT}}" --target "{{target}}" "{{vendor}}"

# ─── Skills ───────────────────────────────────────────────────────────────────

# Deploy skills to a target project
# Usage: just deploy-skills /path/to/project code-review,add-tests claude
# Usage: just deploy-skills /path/to/project all opencode
deploy-skills target skills="all" vendor="":
    @"{{LIBRARY_ROOT}}/tooling/lib/deploy-skills.sh" \
        --library "{{LIBRARY_ROOT}}" \
        --target "{{target}}" \
        --skills "{{skills}}" \
        --vendor "{{vendor}}"

# ─── Full Pipeline ────────────────────────────────────────────────────────────

# Full deploy: compose (lean) + vendor-gen + deploy skills + activate vendors
# Usage: just deploy typescript-hexagonal-microservice /path/to/project claude
# Usage: just deploy typescript-hexagonal-microservice /path/to/project claude,opencode code-review,write-adr
deploy profile target vendors skills="all":
    @just compose "{{profile}}" "{{target}}"
    @just vendor-gen "{{target}}" "{{vendors}}"
    @just deploy-skills "{{target}}" "{{skills}}" "{{vendors}}"
    @# Activate all specified vendors
    @just vendor-switch "{{target}}" "{{vendors}}"
    @echo ""
    @echo "Deployed profile '{{profile}}' to {{target}}"
    @echo "Active vendors: {{vendors}}"

# Compose monolithic AGENTS.md with all fragment content inlined
# Usage: just compose-full typescript-hexagonal-microservice /path/to/project
compose-full profile target:
    @"{{LIBRARY_ROOT}}/tooling/lib/compose.sh" \
        --library "{{LIBRARY_ROOT}}" \
        --profile "{{profile}}" \
        --target "{{target}}" \
        --full

# Full deploy with monolithic AGENTS.md (all fragment content inlined)
# Usage: just deploy-full typescript-hexagonal-microservice /path/to/project claude
# Usage: just deploy-full typescript-hexagonal-microservice /path/to/project claude,opencode code-review,write-adr
deploy-full profile target vendors skills="all":
    @just compose-full "{{profile}}" "{{target}}"
    @just vendor-gen "{{target}}" "{{vendors}}"
    @just deploy-skills "{{target}}" "{{skills}}" "{{vendors}}"
    @# Activate all specified vendors
    @just vendor-switch "{{target}}" "{{vendors}}"
    @echo ""
    @echo "Deployed profile '{{profile}}' (full mode) to {{target}}"
    @echo "Active vendors: {{vendors}}"

# ─── Index ────────────────────────────────────────────────────────────────────

# Rebuild index/skills.json and index/fragments.json
index:
    @"{{LIBRARY_ROOT}}/tooling/lib/index.sh" \
        --library "{{LIBRARY_ROOT}}"
    @echo "Index rebuilt: index/skills.json, index/fragments.json"

# ─── Quality ──────────────────────────────────────────────────────────────────

# Check prerequisites and install missing tools (macOS: via Homebrew; Linux: guided)
setup:
    @"{{LIBRARY_ROOT}}/tooling/lib/setup.sh"

# Validate all fragments, profiles, and vendor adapters
lint:
    @"{{LIBRARY_ROOT}}/tooling/lib/lint.sh" \
        --library "{{LIBRARY_ROOT}}"

# Run the integration test suite
test:
    @"{{LIBRARY_ROOT}}/tooling/lib/test.sh" \
        --library "{{LIBRARY_ROOT}}"

# ─── Installation ─────────────────────────────────────────────────────────────

# Install the global agentic CLI
# Usage: just install (default: ~/.local/bin)
# Usage: just install global (installs to /usr/local/bin with sudo)
install target="local":
    @"{{LIBRARY_ROOT}}/tooling/lib/install.sh" install "{{target}}"

# Uninstall the global agentic CLI
# Usage: just uninstall (default: ~/.local/bin)
# Usage: just uninstall global (removes from /usr/local/bin)
uninstall target="local":
    @"{{LIBRARY_ROOT}}/tooling/lib/install.sh" uninstall "{{target}}"

# ─── Utilities ────────────────────────────────────────────────────────────────

# Show what would be composed for a profile without writing any files (dry run)
# Usage: just dry-run typescript-hexagonal-microservice
dry-run profile:
    @"{{LIBRARY_ROOT}}/tooling/lib/compose.sh" \
        --library "{{LIBRARY_ROOT}}" \
        --profile "{{profile}}" \
        --target /dev/stdout \
        --dry-run

# Manage MCP servers in a target project (interactive wizard)
# Usage: just mcp-add /path/to/project
mcp-add target:
    @"{{LIBRARY_ROOT}}/tooling/lib/mcp.sh" --action add --target "{{target}}"

# Remove an MCP server from a target project
# Usage: just mcp-remove /path/to/project github
mcp-remove target name:
    @"{{LIBRARY_ROOT}}/tooling/lib/mcp.sh" --action remove --target "{{target}}" --name "{{name}}"

# List MCP servers configured in a target project
# Usage: just mcp-list /path/to/project
mcp-list target:
    @"{{LIBRARY_ROOT}}/tooling/lib/mcp.sh" --action list --target "{{target}}"
