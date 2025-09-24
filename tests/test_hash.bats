#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
}

teardown() {
  default_teardown
}

@test 'hash requires a file argument' {
  run_spell 'spells/hash'
  assert_failure
  assert_output --partial 'Usage: hash file'
}

@test 'hash reports missing files' {
  run_spell 'spells/hash' 'does-not-exist.txt'
  assert_failure
  assert_output --partial 'Your spell fizzles. There is no file.'
}

@test 'hash prints resolved path and CRC-32 checksum' {
  tmp_dir="$BATS_TEST_TMPDIR/hash"
  mkdir -p "$tmp_dir"
  file="$tmp_dir/scroll.txt"
  printf 'magic words' >"$file"
  relative_path=$(python3 - <<PY
import os
print(os.path.relpath("$file", "$BATS_TEST_DIRNAME"))
PY
)

  run_spell 'spells/hash' "$relative_path"
  assert_success

  expected_path=$(cd "$(dirname "$file")" && pwd)/"$(basename "$file")"
  expected_crc=$(cksum "$file" | awk '{print $1}')
  printf -v expected_hex '0x%x' "$expected_crc"

  assert_output --partial "$expected_path"
  assert_output --partial "$expected_hex"
}

