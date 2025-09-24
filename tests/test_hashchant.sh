#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"
source "$(dirname "$0")/lib/stub_helpers.sh"

BASE_PATH=$PATH
attr_stubs=$(wizardry_install_attr_stubs)

# Missing argument should be rejected.
run_script "spells/hashchant"
expect_exit_code 1
expect_in_output "Error: No file specified." "$RUN_STDOUT" "hashchant should demand a target file"

# Non-existent files should error.
run_script "spells/hashchant" "missing.txt"
expect_exit_code 1
expect_in_output "Error: File not found." "$RUN_STDOUT"

tmp_dir=$(make_temp_dir)
attr_store="$tmp_dir/attrs"
export ATTR_STORAGE_DIR="$attr_store"

# Successful enchantment when attr is available.
attr_file="$tmp_dir/attr.txt"
printf 'alpha' >"$attr_file"
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" run_script "spells/hashchant" "$attr_file"
expect_exit_code 0
expected_hash_attr=$( (echo "$(basename "$attr_file")" && cat "$attr_file") | cksum | awk '{ print $1 }')
expected_hash_attr=$(printf '0x%X' "$expected_hash_attr")
expect_in_output "File enchanted with hash: $expected_hash_attr" "$RUN_STDOUT"
if attr_output=$("$attr_stubs/attr" -g user.hash "$attr_file" 2>/dev/null); then
  expect_in_output "$expected_hash_attr" "$attr_output" "hashchant should store the hash under user.hash"
else
  record_failure "hashchant should make user.hash retrievable via attr"
fi

# Fallback to xattr when attr is unavailable.
xattr_only_dir=$(wizardry_install_attr_stubs xattr)
xattr_file="$tmp_dir/xattr.txt"
printf 'beta' >"$xattr_file"
ATTR_STORAGE_DIR="$tmp_dir/xattr_store" RUN_PATH_OVERRIDE="$(wizardry_join_paths "$xattr_only_dir" "$BASE_PATH")" \
  run_script "spells/hashchant" "$xattr_file"
expect_exit_code 0
expected_hash_xattr=$( (echo "$(basename "$xattr_file")" && cat "$xattr_file") | cksum | awk '{ print $1 }')
expected_hash_xattr=$(printf '0x%X' "$expected_hash_xattr")
expect_in_output "File enchanted with hash: $expected_hash_xattr" "$RUN_STDOUT"
xattr_value=$(ATTR_STORAGE_DIR="$tmp_dir/xattr_store" "$attr_stubs/xattr" -p user.hash "$xattr_file" 2>/dev/null || true)
expect_eq "$expected_hash_xattr" "$xattr_value" "hashchant should use xattr when attr is missing"

# Fallback to setfattr when only it is available.
setfattr_only_dir=$(wizardry_install_attr_stubs setfattr getfattr)
setfattr_file="$tmp_dir/setfattr.txt"
printf 'gamma' >"$setfattr_file"
ATTR_STORAGE_DIR="$tmp_dir/setfattr_store" RUN_PATH_OVERRIDE="$(wizardry_join_paths "$setfattr_only_dir" "$BASE_PATH")" \
  run_script "spells/hashchant" "$setfattr_file"
expect_exit_code 0
expected_hash_setfattr=$( (echo "$(basename "$setfattr_file")" && cat "$setfattr_file") | cksum | awk '{ print $1 }')
expected_hash_setfattr=$(printf '0x%X' "$expected_hash_setfattr")
expect_in_output "File enchanted with hash: $expected_hash_setfattr" "$RUN_STDOUT"
setfattr_value=$(ATTR_STORAGE_DIR="$tmp_dir/setfattr_store" "$attr_stubs/getfattr" -n user.hash --only-values "$setfattr_file" 2>/dev/null || true)
expect_eq "$expected_hash_setfattr" "$setfattr_value" "hashchant should fall back to setfattr"

# When no helper commands exist the spell should fail loudly.
RUN_PATH_OVERRIDE="/usr/bin:/bin" run_script "spells/hashchant" "$setfattr_file"
expect_exit_code 1
expect_in_output "Cannot enchant file" "$RUN_STDOUT" "hashchant should error when helpers are missing"

assert_all_expectations_met
