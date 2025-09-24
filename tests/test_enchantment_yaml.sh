#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"
source "$(dirname "$0")/lib/stub_helpers.sh"

BASE_PATH=$PATH
attr_stubs=$(wizardry_install_attr_stubs)

# enchantment-to-yaml error handling
run_script "spells/enchantment-to-yaml"
expect_exit_code 1
expect_in_output "incorrect number of arguments" "$RUN_STDOUT"

run_script "spells/enchantment-to-yaml" "$TEST_TMPDIR/missing.txt"
expect_exit_code 1
expect_in_output "Error: file does not exist" "$RUN_STDOUT"

# enchantment-to-yaml transforms attributes into a YAML header.
enchant_tmp=$(make_temp_dir)
attr_store="$enchant_tmp/attrs"
export ATTR_STORAGE_DIR="$attr_store"
scroll="$enchant_tmp/scroll.txt"
printf 'plain body\n' >"$scroll"
"$attr_stubs/xattr" -w name Library "$scroll"
"$attr_stubs/xattr" -w level 5 "$scroll"

pushd "$enchant_tmp" >/dev/null
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" run_script "spells/enchantment-to-yaml" "scroll.txt"
popd >/dev/null
expect_exit_code 0
expected_yaml=$'---\nname:\nlevel:\n---\n\nplain body\n'
expect_eq "$expected_yaml" "$(cat "$scroll")" "enchantment-to-yaml should prepend a YAML header"
attributes_after=$("$attr_stubs/xattr" "$scroll")
expect_eq "" "$attributes_after"

# yaml-to-enchantment error handling
run_script "spells/yaml-to-enchantment"
expect_exit_code 1
expect_in_output "incorrect number of arguments" "$RUN_STDOUT"

run_script "spells/yaml-to-enchantment" "$TEST_TMPDIR/void.txt"
expect_exit_code 1
expect_in_output "Error: file does not exist" "$RUN_STDOUT"

no_header="$enchant_tmp/no_header.txt"
printf 'plain body\n' >"$no_header"
run_script "spells/yaml-to-enchantment" "$no_header"
expect_exit_code 1
expect_in_output "Error: file does not have a YAML header" "$RUN_STDOUT"

# yaml-to-enchantment consumes the header and restores the attributes.
transmute_tmp=$(make_temp_dir)
attr_store2="$transmute_tmp/attrs"
tome="$transmute_tmp/tome.txt"
cat <<'DOC' >"$tome"
---
name: Library
level: 5
---
plain body
DOC

pushd "$transmute_tmp" >/dev/null
ATTR_STORAGE_DIR="$attr_store2" RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" \
  run_script "spells/yaml-to-enchantment" "tome.txt"
popd >/dev/null
expect_exit_code 0
expect_eq $'plain body\n' "$(cat "$tome")"
name_attr=$(ATTR_STORAGE_DIR="$attr_store2" "$attr_stubs/xattr" -p name "$tome")
expect_eq "Library" "$name_attr"
level_attr=$(ATTR_STORAGE_DIR="$attr_store2" "$attr_stubs/xattr" -p level "$tome")
expect_eq "5" "$level_attr"

assert_all_expectations_met
