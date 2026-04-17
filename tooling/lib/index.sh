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
  # Use jq for proper JSON construction (avoids issues with special characters)
  local skills_entries=()
  
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

    # Build JSON entry using jq
    local entry
    entry=$(jq -n \
      --arg name "$name" \
      --arg group "$group" \
      --arg path "$path" \
      --arg desc "${description:0:120}" \
      --arg ver "${version:-0.0.0}" \
      --argjson tags "$tags" \
      '{name: $name, group: $group, path: $path, description: $desc, version: $ver, tags: $tags}')
    skills_entries+=("$entry")
  done < <(find "$LIBRARY/skills" -name "SKILL.md" | sort)

  # Combine all entries into the final JSON
  local skills_json
  if [[ ${#skills_entries[@]} -eq 0 ]]; then
    skills_json=$(jq -n '{version: "1.0.0", generated_at: "", skills: []}')
  else
    skills_json=$(printf '%s\n' "${skills_entries[@]}" | jq -s '{version: "1.0.0", generated_at: "", skills: .}')
  fi

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
  # Use jq for proper JSON construction (avoids issues with special characters)
  local frags_entries=()

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

    # Build JSON entry using jq (properly escapes special characters)
    local entry
    entry=$(jq -n \
      --arg name "$name" \
      --arg group "$group" \
      --arg path "agents/$rel" \
      --arg heading "$heading" \
      --argjson words "$word_count" \
      '{name: $name, group: $group, path: $path, heading: $heading, words: $words}')
    frags_entries+=("$entry")
  done < <(find "$LIBRARY/agents" -name "*.md" | sort)

  # Combine all entries into the final JSON
  local frags_json
  if [[ ${#frags_entries[@]} -eq 0 ]]; then
    frags_json=$(jq -n '{version: "1.0.0", generated_at: "", fragments: []}')
  else
    frags_json=$(printf '%s\n' "${frags_entries[@]}" | jq -s '{version: "1.0.0", generated_at: "", fragments: .}')
  fi

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
