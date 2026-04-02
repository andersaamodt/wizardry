#!/bin/sh
# Test for prompt-with-fallback imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_prompt_with_fallback_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/input/prompt-with-fallback" ]
}

test_prompt_with_fallback_finds_ask_text_in_path() {
  stub_dir=$(make_tempdir)
  old_path=$PATH
  cat >"$stub_dir/ask-text" <<'SH'
#!/bin/sh
printf '%s\n' test-input
SH
  chmod +x "$stub_dir/ask-text"

  PATH="$stub_dir:$PATH"
  run_sourced_spell spells/.imps/input/prompt-with-fallback "Enter value:"
  PATH=$old_path
  assert_success || return 1
  assert_output_contains "test-input" || return 1
}

test_prompt_with_fallback_passes_prompt() {
  stub_dir=$(make_tempdir)
  old_path=$PATH
  cat >"$stub_dir/ask-text" <<'SH'
#!/bin/sh
printf 'Prompted: %s\n' "$*"
SH
  chmod +x "$stub_dir/ask-text"

  PATH="$stub_dir:$PATH"
  run_sourced_spell spells/.imps/input/prompt-with-fallback "Custom prompt:"
  PATH=$old_path
  assert_success || return 1
  assert_output_contains "Custom prompt:" || return 1
}

test_prompt_with_fallback_fails_on_empty_input() {
  stub_dir=$(make_tempdir)
  old_path=$PATH
  cat >"$stub_dir/ask-text" <<'SH'
#!/bin/sh
printf '%s' ''
SH
  chmod +x "$stub_dir/ask-text"

  PATH="$stub_dir:$PATH"
  run_sourced_spell spells/.imps/input/prompt-with-fallback "Enter value:"
  PATH=$old_path
  assert_failure || return 1
}

run_test_case "prompt-with-fallback is executable" test_prompt_with_fallback_is_executable
run_test_case "prompt-with-fallback finds ask-text in PATH" test_prompt_with_fallback_finds_ask_text_in_path
run_test_case "prompt-with-fallback passes prompt to ask-text" test_prompt_with_fallback_passes_prompt
run_test_case "prompt-with-fallback fails on empty input" test_prompt_with_fallback_fails_on_empty_input

finish_tests
