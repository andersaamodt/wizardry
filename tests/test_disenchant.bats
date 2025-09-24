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

@test 'disenchant requires a file argument' {
  run_spell 'spells/disenchant'
  assert_failure
  assert_output --partial 'Error: No file specified'
}

@test 'disenchant removes a specified attribute' {
  workdir="$BATS_TEST_TMPDIR/disenchant"
  mkdir -p "$workdir"
  attr_store="$workdir/attrs"
  scroll="$workdir/scroll.txt"
  printf 'plain text' >"$scroll"

  ATTR_STORAGE_DIR="$attr_store" "$attr_stubs/xattr" -w color blue "$scroll"

  cat <<'STUB' >"$workdir/read-magic"
#!/usr/bin/env bash
echo 'color: blue'
STUB
  chmod +x "$workdir/read-magic"

  pushd "$workdir" >/dev/null
  PATH="$(wizardry_join_paths "$attr_stubs" "$workdir" "$ORIGINAL_PATH")" \
    ATTR_STORAGE_DIR="$attr_store" run_spell 'spells/disenchant' 'scroll.txt' 'color'
  popd >/dev/null

  assert_success
  assert_output --partial 'Disenchanted color attribute'

  run env ATTR_STORAGE_DIR="$attr_store" "$attr_stubs/xattr" -p color "$scroll"
  assert_failure
}

