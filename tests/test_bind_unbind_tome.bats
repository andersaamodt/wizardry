#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
}

teardown() {
  default_teardown
}

@test 'bind-tome requires a directory argument' {
  run_spell 'spells/bind-tome'
  assert_failure
  assert_output --partial 'Error: Please provide a folder path as an argument.'
}

@test 'bind-tome combines files into a tome' {
  workdir="$BATS_TEST_TMPDIR/bind"
  mkdir -p "$workdir/pages"
  printf 'alpha rune\n' >"$workdir/pages/first"
  printf 'beta glyph\n' >"$workdir/pages/second"

  pushd "$workdir" >/dev/null
  run_spell 'spells/bind-tome' 'pages'
  popd >/dev/null

  assert_success
  assert_output --partial 'Text file created: pages.txt'

  bound_scroll="$workdir/pages.txt"
  run cat "$bound_scroll"
  assert_success
  assert_output --partial 'first'
  assert_output --partial 'alpha rune'
  assert_output --partial 'End of first'
  assert_output --partial 'second'
  assert_output --partial 'beta glyph'
  assert_output --partial 'End of second'
}

@test 'bind-tome -d on missing directory emits placeholders' {
  workdir="$BATS_TEST_TMPDIR/deletion"
  mkdir -p "$workdir"
  pushd "$workdir" >/dev/null
  run_spell 'spells/bind-tome' '-d'
  popd >/dev/null

  assert_success
  assert_output --partial 'Original files deleted.'
  assert_output --partial 'Text file created: .txt'
}

@test 'unbind-tome requires a file argument' {
  run_spell 'spells/unbind-tome'
  assert_failure
  assert_output --partial 'Error: Please provide a file path as an argument.'
}

@test 'unbind-tome splits the tome into sanitised files' {
  workdir="$BATS_TEST_TMPDIR/unbind"
  mkdir -p "$workdir"
  cat <<'STORY' >"$workdir/story.txt"
First page
Symbols & sigils
Trailing space
STORY

  pushd "$workdir" >/dev/null
  run_spell 'spells/unbind-tome' 'story.txt'
  popd >/dev/null

  assert_success
  [[ "$stderr" != *Error* ]]

  pieces_dir="$workdir/story"
  [ -d "$pieces_dir" ]
  [ -f "$pieces_dir/First_page" ]
  [ -f "$pieces_dir/Symbols__sigils" ]
  [ -f "$pieces_dir/Trailing_space" ]
}

