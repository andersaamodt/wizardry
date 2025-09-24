#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
}

teardown() {
  PATH=$ORIGINAL_PATH
  default_teardown
}

@test 'copy writes file contents into clipboard using available commands' {
  run_spell "spells/copy" "$BATS_TEST_TMPDIR/nowhere.txt"
  assert_failure
  assert_output --partial 'That file does not exist.'

  test_dir="$BATS_TEST_TMPDIR"
  file="$test_dir/message.txt"
  printf 'hello world' >"$file"

  clipboard="$test_dir/pbcopy.txt"
  pbcopy_stub=$(wizardry_install_clipboard_stubs pbcopy)
  RUN_PATH_OVERRIDE="$(wizardry_join_paths "$pbcopy_stub" "$ORIGINAL_PATH")" \
    CLIPBOARD_FILE="$clipboard" run_spell "spells/copy" "$file"
  assert_success
  run cat "$clipboard"
  assert_success
  assert_output 'hello world'

  clipboard="$test_dir/xsel.txt"
  xsel_stub=$(wizardry_install_clipboard_stubs xsel)
  RUN_PATH_OVERRIDE="$(wizardry_join_paths "$xsel_stub" "$ORIGINAL_PATH")" \
    CLIPBOARD_FILE="$clipboard" run_spell "spells/copy" "$file"
  assert_success
  run cat "$clipboard"
  assert_success
  assert_output 'hello world'

  clipboard="$test_dir/xclip.txt"
  xclip_stub=$(wizardry_install_clipboard_stubs xclip)
  RUN_PATH_OVERRIDE="$(wizardry_join_paths "$xclip_stub" "$ORIGINAL_PATH")" \
    CLIPBOARD_FILE="$clipboard" run_spell "spells/copy" "$file"
  assert_success
  run cat "$clipboard"
  assert_success
  assert_output 'hello world'

  RUN_PATH_OVERRIDE="$ORIGINAL_PATH" CLIPBOARD_FILE="$test_dir/missing.txt" run_spell "spells/copy" "$file"
  assert_failure
  [[ "$stderr" == *'Your spell fizzles.'* ]]
}
