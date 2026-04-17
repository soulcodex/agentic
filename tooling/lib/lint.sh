#!/usr/bin/env bash
# lint.sh — Validates fragments, profiles, and vendor adapters
# Called by: just lint
set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tooling/lib/common.sh
source "$SCRIPT_DIR/common.sh"

LIBRARY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library) LIBRARY="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$LIBRARY" ]] && { echo "Error: --library required" >&2; exit 1; }

ERRORS=0
WARNINGS=0

fail() { echo "  [FAIL] $*" >&2; ((ERRORS++)); }
warn() { echo "  [WARN] $*"; ((WARNINGS++)); }
ok()   { echo "  [ OK ] $*"; }

# ── Fragment validation ───────────────────────────────────────────────────────
echo "Validating fragments..."
while IFS= read -r frag_file; do
  rel="${frag_file#"$LIBRARY"/}"

  # Must start with H2 heading
  first_heading=$(grep -m1 '^## ' "$frag_file" || true)
  if [[ -z "$first_heading" ]]; then
    fail "$rel — no H2 heading found (fragments must start with '## Heading')"
  else
    ok "$rel"
  fi

  # Should not contain unfilled template tokens
  tokens=$(grep -oE '\{\{[A-Z_]+\}\}' "$frag_file" || true)
  if [[ -n "$tokens" ]]; then
    warn "$rel — contains template tokens: $tokens (these will be substituted at compose time)"
  fi

  # Warn if file is very long
  line_count=$(wc -l < "$frag_file" | tr -d ' ')
  if [[ "$line_count" -gt 300 ]]; then
    warn "$rel — $line_count lines (consider splitting; recommended max is 300)"
  fi
done < <(find "$LIBRARY/agents" -name "*.md" | sort)

# ── Profile validation ────────────────────────────────────────────────────────
echo ""
echo "Validating profiles..."
while IFS= read -r profile_file; do
  rel="${profile_file#"$LIBRARY"/}"

  # Must have required fields
  name=$(yq '.meta.name // ""' "$profile_file" 2>/dev/null)
  version=$(yq '.meta.version // ""' "$profile_file" 2>/dev/null)

  if [[ -z "$name" || "$name" == "null" ]]; then
    fail "$rel — missing meta.name"
  elif [[ -z "$version" || "$version" == "null" ]]; then
    fail "$rel — missing meta.version"
  else
    ok "$rel"
  fi

  # Verify referenced fragments exist
  for group in base languages frameworks architecture practices domains; do
    frags=()
    while IFS= read -r _frag; do
      frags+=("$_frag")
    done < <(yq ".fragments.${group}[]" "$profile_file" 2>/dev/null || true)
    for frag in "${frags[@]+"${frags[@]}"}"; do
      [[ -z "$frag" || "$frag" == "null" ]] && continue
      subdir="agents"
      case "$group" in
        base)         subdir="agents/base" ;;
        languages)    subdir="agents/languages" ;;
        frameworks)   subdir="agents/frameworks" ;;
        architecture) subdir="agents/architecture" ;;
        practices)    subdir="agents/practices" ;;
        domains)      subdir="agents/domains" ;;
      esac
      frag_path="$LIBRARY/$subdir/$frag.md"
      if [[ ! -f "$frag_path" ]]; then
        fail "$rel — references missing fragment: $subdir/$frag.md"
      fi
    done
  done
done < <(find "$LIBRARY/profiles" -name "*.yaml" | sort)

# ── Vendor adapter validation ─────────────────────────────────────────────────
echo ""
echo "Validating vendor adapters..."
for vendor in "${AGENTIC_VENDORS[@]}"; do
  adapter_file="$LIBRARY/vendors/$vendor/adapter.json"
  if [[ ! -f "$adapter_file" ]]; then
    warn "vendors/$vendor/adapter.json — not found"
    continue
  fi

  vendor_in_file=$(jq -r '.vendor // ""' "$adapter_file" 2>/dev/null)
  if [[ "$vendor_in_file" != "$vendor" ]]; then
    fail "vendors/$vendor/adapter.json — vendor field is '$vendor_in_file', expected '$vendor'"
  else
    ok "vendors/$vendor/adapter.json"
  fi
done

# ── Skill validation ──────────────────────────────────────────────────────────
echo ""
echo "Validating skills..."
while IFS= read -r skill_file; do
  rel="${skill_file#"$LIBRARY"/}"

  # Must have frontmatter
  if ! grep -q '^---$' "$skill_file"; then
    fail "$rel — no YAML frontmatter found"
    continue
  fi

  name=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^name:' | head -1 | sed 's/^name: *//')
  version=$(sed -n '/^---$/,/^---$/p' "$skill_file" | grep '^version:' | head -1 | sed 's/^version: *//')

  if [[ -z "$name" ]]; then
    fail "$rel — missing 'name' in frontmatter"
  elif [[ -z "$version" ]]; then
    fail "$rel — missing 'version' in frontmatter"
  else
    ok "$rel"
  fi
done < <(find "$LIBRARY/skills" -name "SKILL.md" | sort)

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
if [[ "$ERRORS" -gt 0 ]]; then
  echo "Lint FAILED: $ERRORS error(s), $WARNINGS warning(s)"
  exit 1
elif [[ "$WARNINGS" -gt 0 ]]; then
  echo "Lint PASSED with $WARNINGS warning(s)"
else
  echo "Lint PASSED — no issues found"
fi
