#!/usr/bin/env bash
set -euo pipefail

wizardry_attr_storage_dir() {
  local dir
  if [ -n "${ATTR_STORAGE_DIR:-}" ]; then
    dir="$ATTR_STORAGE_DIR"
  else
    dir="${TMPDIR:-/tmp}/wizardry-attrs"
  fi
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

wizardry_attr_abs_path() {
  local path=$1
  if command -v readlink >/dev/null 2>&1; then
    readlink -f "$path"
  else
    local dir
    dir=$(cd "$(dirname "$path")" >/dev/null 2>&1 && pwd -P)
    printf '%s/%s\n' "$dir" "$(basename "$path")"
  fi
}

wizardry_attr_storage_file_for() {
  local file=$1
  local abs
  abs=$(wizardry_attr_abs_path "$file")
  local sanitized
  sanitized=$(printf '%s' "$abs" | sed 's#[^A-Za-z0-9_]#_#g')
  printf '%s/%s\n' "$(wizardry_attr_storage_dir)" "$sanitized"
}

set_attr_value() {
  local file=$1
  local key=$2
  local value=$3
  local storage
  storage=$(wizardry_attr_storage_file_for "$file")
  local dir
  dir=$(wizardry_attr_storage_dir)
  local tmp
  tmp=$(mktemp "$dir/attr.XXXXXX")
  local found=0
  if [ -f "$storage" ]; then
    while IFS=$'\t' read -r existing_key existing_value; do
      if [ -z "$existing_key" ]; then
        continue
      fi
      if [ "$existing_key" = "$key" ]; then
        printf '%s\t%s\n' "$key" "$value" >>"$tmp"
        found=1
      else
        printf '%s\t%s\n' "$existing_key" "$existing_value" >>"$tmp"
      fi
    done <"$storage"
  fi
  if [ "$found" -eq 0 ]; then
    printf '%s\t%s\n' "$key" "$value" >>"$tmp"
  fi
  mv "$tmp" "$storage"
}

get_attr_value() {
  local file=$1
  local key=$2
  local storage
  storage=$(wizardry_attr_storage_file_for "$file")
  if [ ! -f "$storage" ]; then
    return 1
  fi
  while IFS=$'\t' read -r existing_key existing_value; do
    if [ "$existing_key" = "$key" ]; then
      printf '%s' "$existing_value"
      return 0
    fi
  done <"$storage"
  return 1
}

remove_attr_value() {
  local file=$1
  local key=$2
  local storage
  storage=$(wizardry_attr_storage_file_for "$file")
  if [ ! -f "$storage" ]; then
    return 1
  fi
  local dir
  dir=$(wizardry_attr_storage_dir)
  local tmp
  tmp=$(mktemp "$dir/attr.XXXXXX")
  local removed=1
  while IFS=$'\t' read -r existing_key existing_value; do
    if [ "$existing_key" = "$key" ]; then
      removed=0
      continue
    fi
    if [ -n "$existing_key" ]; then
      printf '%s\t%s\n' "$existing_key" "$existing_value" >>"$tmp"
    fi
  done <"$storage"
  mv "$tmp" "$storage"
  return "$removed"
}

clear_attr_values() {
  local file=$1
  local storage
  storage=$(wizardry_attr_storage_file_for "$file")
  rm -f "$storage"
}

list_attr_keys() {
  local file=$1
  local storage
  storage=$(wizardry_attr_storage_file_for "$file")
  if [ ! -f "$storage" ]; then
    return 0
  fi
  while IFS=$'\t' read -r existing_key existing_value; do
    if [ -n "$existing_key" ]; then
      printf '%s\n' "$existing_key"
    fi
  done <"$storage"
}
