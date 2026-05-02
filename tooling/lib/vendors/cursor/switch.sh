#!/usr/bin/env bash
# cursor/switch.sh — vendor-switch behavior for Cursor

vendor_cursor_add_managed_path() {
  local rel_path="$1"
  [[ -z "$rel_path" || "$rel_path" == "null" ]] && return
  local existing
  for existing in "${CURSOR_MANAGED_PATHS[@]}"; do
    [[ "$existing" == "$rel_path" ]] && return
  done
  CURSOR_MANAGED_PATHS+=("$rel_path")
}

vendor_cursor_load_managed_paths() {
  CURSOR_MANAGED_PATHS=()
  vendor_cursor_add_managed_path ".cursor/rules"

  if [[ -f "$CURSOR_SWITCH_MANIFEST" ]] && jq -e '.managed_paths | type == "array"' "$CURSOR_SWITCH_MANIFEST" > /dev/null 2>&1; then
    local rel_path
    while IFS= read -r rel_path; do
      vendor_cursor_add_managed_path "$rel_path"
    done < <(jq -r '.managed_paths[]?.target // empty' "$CURSOR_SWITCH_MANIFEST")
  fi

  local existing_cursor_symlink
  while IFS= read -r existing_cursor_symlink; do
    existing_cursor_symlink="${existing_cursor_symlink#"$TARGET"/}"
    vendor_cursor_add_managed_path "$existing_cursor_symlink"
  done < <(find "$TARGET" -type l -path '*/.cursor/rules' 2>/dev/null || true)
}

vendor_cursor_record_backup_move() {
  local original="$1"
  local backup="$2"
  mkdir -p "$ROLLBACK_DIR"
  printf '%s\t%s\n' "$original" "$backup" >> "$ROLLBACK_CURSOR_MOVES_FILE"
}

vendor_cursor_prepare_rules_path() {
  local rel_path="$1"
  local cursor_rules="$TARGET/$rel_path"
  if [[ -e "$cursor_rules" && ! -L "$cursor_rules" ]]; then
    local backup_path
    backup_path="$(next_backup_path "$cursor_rules")"
    mv "$cursor_rules" "$backup_path"
    vendor_cursor_record_backup_move "$cursor_rules" "$backup_path"
    echo "  Migrated: $rel_path → ${backup_path#"$TARGET"/}"
  fi
}

vendor_cursor_preflight_conflicts() {
  local rel_path
  for rel_path in "${CURSOR_MANAGED_PATHS[@]}"; do
    vendor_cursor_prepare_rules_path "$rel_path"
  done
}

vendor_cursor_files_exist() {
  [[ -d "$VENDOR_FILES_DIR/cursor/rules" ]]
}

vendor_cursor_create_symlinks() {
  if [[ -f "$CURSOR_SWITCH_MANIFEST" ]] && jq -e '.managed_paths | type == "array"' "$CURSOR_SWITCH_MANIFEST" > /dev/null 2>&1; then
    local rel_target rel_source abs_target abs_source
    while IFS=$'\t' read -r rel_target rel_source; do
      [[ -z "$rel_target" || -z "$rel_source" ]] && continue
      abs_target="$TARGET/$rel_target"
      abs_source="$TARGET/$rel_source"
      mkdir -p "$(dirname "$abs_target")"
      ln -sfn "$abs_source" "$abs_target"
      echo "    Linked: $rel_target → $rel_source"
    done < <(jq -r '.managed_paths[]? | [.target, .source] | @tsv' "$CURSOR_SWITCH_MANIFEST")
  elif [[ -d "$VENDOR_FILES_DIR/cursor/rules" ]]; then
    mkdir -p "$TARGET/.cursor"
    ln -sfn "../.agentic/vendor-files/cursor/rules" "$TARGET/.cursor/rules"
    echo "    Linked: .cursor/rules → ../.agentic/vendor-files/cursor/rules"
  fi
}
