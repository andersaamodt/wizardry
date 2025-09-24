#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  attr_stubs=$(wizardry_install_attr_stubs)
  export ATTR_STORAGE_DIR="$BATS_TEST_TMPDIR/attrs"
}

teardown() {
  PATH=$ORIGINAL_PATH
  unset ATTR_STORAGE_DIR
  default_teardown
}

compute_hash() {
  local file=$1
  local checksum
  checksum=$( (echo "$(basename "$file")" && cat "$file") | cksum | awk '{ print $1 }')
  printf '0x%X' "$checksum"
}

@test 'hashchant requires a file argument' {
  run_spell 'spells/hashchant'
  assert_failure
  assert_output --partial 'Error: No file specified.'
}

@test 'hashchant fails on missing files' {
  run_spell 'spells/hashchant' 'missing.txt'
  assert_failure
  assert_output --partial 'Error: File not found.'
}

@test 'hashchant stores hash via attr helpers' {
  file="$BATS_TEST_TMPDIR/attr.txt"
  printf 'alpha' >"$file"
  PATH="$(wizardry_join_paths "$attr_stubs" "$ORIGINAL_PATH")" run_spell 'spells/hashchant' "$file"
  assert_success

  expected_hash=$(compute_hash "$file")
  assert_output --partial "File enchanted with hash: $expected_hash"

  run "$attr_stubs/attr" -g user.hash "$file"
  assert_success
  assert_output --partial "$expected_hash"
}

@test 'hashchant falls back to xattr helpers' {
  xattr_only_dir=$(wizardry_install_attr_stubs xattr)
  file="$BATS_TEST_TMPDIR/xattr.txt"
  printf 'beta' >"$file"
  PATH="$(wizardry_join_paths "$xattr_only_dir" "$ORIGINAL_PATH")" \
    ATTR_STORAGE_DIR="$BATS_TEST_TMPDIR/xattr_store" run_spell 'spells/hashchant' "$file"
  assert_success

  expected_hash=$(compute_hash "$file")
  assert_output --partial "File enchanted with hash: $expected_hash"

  run env ATTR_STORAGE_DIR="$BATS_TEST_TMPDIR/xattr_store" "$attr_stubs/xattr" -p user.hash "$file"
  assert_success
  assert_output "$expected_hash"
}

@test 'hashchant falls back to setfattr helpers' {
  setfattr_only_dir=$(wizardry_install_attr_stubs setfattr getfattr)
  file="$BATS_TEST_TMPDIR/setfattr.txt"
  printf 'gamma' >"$file"
  PATH="$(wizardry_join_paths "$setfattr_only_dir" "$ORIGINAL_PATH")" \
    ATTR_STORAGE_DIR="$BATS_TEST_TMPDIR/setfattr_store" run_spell 'spells/hashchant' "$file"
  assert_success

  expected_hash=$(compute_hash "$file")
  assert_output --partial "File enchanted with hash: $expected_hash"

  run env ATTR_STORAGE_DIR="$BATS_TEST_TMPDIR/setfattr_store" "$attr_stubs/getfattr" -n user.hash --only-values "$file"
  assert_success
  assert_output "$expected_hash"
}

@test 'hashchant fails when helpers are unavailable' {
  file="$BATS_TEST_TMPDIR/unavailable.txt"
  printf 'delta' >"$file"
  PATH="/usr/bin:/bin" run_spell 'spells/hashchant' "$file"
  assert_failure
  assert_output --partial 'Cannot enchant file'
}

