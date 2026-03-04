#!/bin/bash
# index.sh — Rebuilds index/skills.json and index/fragments.json
# Called by: just index
#
# Only updates files when content actually changes (ignoring generated_at timestamp)
# to avoid noise in git diffs.
set -euo pipefail

LIBRARY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --library) LIBRARY="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$LIBRARY" ]] && { echo "Error: --library required" >&2; exit 1; }

INDEX_DIR="$LIBRARY/index"
mkdir -p "$INDEX_DIR"

# ── Helpers ───────────────────────────────────────────────────────────────────

# Writes JSON to file only if content (excluding generated_at) has changed.
# If content changed, updates generated_at to current time.
# If content unchanged, leaves file untouched.
write_if_changed() {
  local file="$1"
  local new_json="$2"

  if [[ -f "$file" ]]; then
    # Extract existing content without generated_at for comparison
    local existing_content
    existing_content=$(jq 'del(.generated_at)' "$file" 2>/dev/null || echo "{}")
    local new_content
    new_content=$(echo "$new_json" | jq 'del(.generated_at)')

    if [[ "$existing_content" == "$new_content" ]]; then
      # Content unchanged, don't update file
      return 1
    fi
  fi

  # Content changed (or new file), write with current timestamp
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "$new_json" | jq --arg ts "$timestamp" '.generated_at = $ts' > "$file"
  return 0
}

# ── Skills index ──────────────────────────────────────────────────────────────
build_skills_index() {
  local skills_json='{"version":"1.0.0","generated_at":"","skills":['
  local first=true

  while IFS= read -r skill_file; do
    local dir
    dir=$(dirname "$skill_file")
    local group
    group=$(basename "$(dirname "$dir")")
    local name
    name=$(basename "$dir")
    local path="${skill_file#$LIBRARY/}"

    # Extract frontmatter fields using yq (parse YAML block between first two --- delimiters)
    local frontmatter
    frontmatter=$(awk '/^---$/{n++; if(n==1){p=1;next} if(n==2){exit}} p' "$skill_file")
    local description
    description=$(echo "$frontmatter" | yq '.description // ""' | tr -d '\n' | sed 's/  */ /g')
    local version
    version=$(echo "$frontmatter" | yq '.version // "0.0.0"')
    local tags
    tags=$(echo "$frontmatter" | yq -o=json '.tags // []' 2>/dev/null || echo '[]')

    [[ "$first" == "false" ]] && skills_json+=","
    skills_json+=$(printf '{"name":"%s","group":"%s","path":"%s","description":"%s","version":"%s","tags":%s}' \
      "$name" "$group" "$path" "${description:0:120}" "${version:-0.0.0}" "${tags:-[]}")
    first=false
  done < <(find "$LIBRARY/skills" -name "SKILL.md" | sort)

  skills_json+="]}"

  local count
  count=$(find "$LIBRARY/skills" -name "SKILL.md" | wc -l | tr -d ' ')

  if write_if_changed "$INDEX_DIR/skills.json" "$skills_json"; then
    echo "  Updated: index/skills.json ($count skills)"
  else
    echo "  Unchanged: index/skills.json ($count skills)"
  fi
}

# ── Fragments index ───────────────────────────────────────────────────────────
build_fragments_index() {
  local frags_json='{"version":"1.0.0","generated_at":"","fragments":['
  local first=true

  while IFS= read -r frag_file; do
    local rel="${frag_file#$LIBRARY/agents/}"
    local group
    group=$(dirname "$rel")
    local name
    name=$(basename "$rel" .md)
    local heading
    heading=$(grep '^## ' "$frag_file" | head -1 | sed 's/^## //')
    local word_count
    word_count=$(wc -w < "$frag_file" | tr -d ' ')

    [[ "$first" == "false" ]] && frags_json+=","
    frags_json+=$(printf '{"name":"%s","group":"%s","path":"agents/%s","heading":"%s","words":%s}' \
      "$name" "$group" "$rel" "$heading" "$word_count")
    first=false
  done < <(find "$LIBRARY/agents" -name "*.md" | sort)

  frags_json+="]}"

  local count
  count=$(find "$LIBRARY/agents" -name "*.md" | wc -l | tr -d ' ')

  if write_if_changed "$INDEX_DIR/fragments.json" "$frags_json"; then
    echo "  Updated: index/fragments.json ($count fragments)"
  else
    echo "  Unchanged: index/fragments.json ($count fragments)"
  fi
}

echo "Rebuilding indexes..."
build_skills_index
build_fragments_index
echo "Done."
