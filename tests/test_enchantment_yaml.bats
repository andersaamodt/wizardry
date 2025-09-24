#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  attr_stubs=$(wizardry_install_attr_stubs)
}

teardown() {
  PATH=$ORIGINAL_PATH
  default_teardown
}

@test 'enchantment-to-yaml validates inputs' {
  run_spell 'spells/enchantment-to-yaml'
  assert_failure
  assert_output --partial 'incorrect number of arguments'

  run_spell 'spells/enchantment-to-yaml' "$BATS_TEST_TMPDIR/missing.txt"
  assert_failure
  assert_output --partial 'Error: file does not exist'
}

@test 'enchantment-to-yaml converts attributes into a header' {
  workdir="$BATS_TEST_TMPDIR/enchant"
  mkdir -p "$workdir"
  attr_store="$workdir/attrs"
  export ATTR_STORAGE_DIR="$attr_store"
  scroll="$workdir/scroll.txt"
  printf 'plain body\n' >"$scroll"

  "$attr_stubs/xattr" -w name Library "$scroll"
  "$attr_stubs/xattr" -w level 5 "$scroll"

  pushd "$workdir" >/dev/null
  PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" run_spell 'spells/enchantment-to-yaml' 'scroll.txt'
  popd >/dev/null
  unset ATTR_STORAGE_DIR

  assert_success
  run cat "$scroll"
  assert_success
  assert_output $'---\nname:\nlevel:\n---\n\nplain body\n'

  run "$attr_stubs/xattr" "$scroll"
  assert_success
  assert_output ''
}

@test 'yaml-to-enchantment validates inputs and requires header' {
  run_spell 'spells/yaml-to-enchantment'
  assert_failure
  assert_output --partial 'incorrect number of arguments'

  run_spell 'spells/yaml-to-enchantment' "$BATS_TEST_TMPDIR/void.txt"
  assert_failure
  assert_output --partial 'Error: file does not exist'

  no_header="$BATS_TEST_TMPDIR/no_header.txt"
  printf 'plain body\n' >"$no_header"
  run_spell 'spells/yaml-to-enchantment' "$no_header"
  assert_failure
  assert_output --partial 'Error: file does not have a YAML header'
}

@test 'yaml-to-enchantment restores attributes from YAML header' {
  workdir="$BATS_TEST_TMPDIR/transmute"
  mkdir -p "$workdir"
  attr_store="$workdir/attrs"
  tome="$workdir/tome.txt"
  cat <<'DOC' >"$tome"
---
name: Library
level: 5
---
plain body
DOC

  pushd "$workdir" >/dev/null
  ATTR_STORAGE_DIR="$attr_store" PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" \
    run_spell 'spells/yaml-to-enchantment' 'tome.txt'
  popd >/dev/null

  assert_success
  run cat "$tome"
  assert_success
  assert_output 'plain body'

  run env ATTR_STORAGE_DIR="$attr_store" "$attr_stubs/xattr" -p name "$tome"
  assert_success
  assert_output 'Library'

  run env ATTR_STORAGE_DIR="$attr_store" "$attr_stubs/xattr" -p level "$tome"
  assert_success
  assert_output '5'
}

