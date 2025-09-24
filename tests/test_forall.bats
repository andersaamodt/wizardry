#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
}

teardown() {
  default_teardown
}

@test 'forall runs command for each file and indents output' {
  workdir="$BATS_TEST_TMPDIR/forall"
  mkdir -p "$workdir"
  printf 'aaa\n' >"$workdir/a.txt"
  printf 'bb\n' >"$workdir/b.txt"

  pushd "$workdir" >/dev/null
  run_spell 'spells/forall' wc -c
  popd >/dev/null

  assert_success
  assert_output --partial 'a.txt'
  assert_output --partial 'b.txt'
  assert_output --partial '   4 ./a.txt'
  assert_output --partial '   3 ./b.txt'
}

