#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

setup_stubbed_env() {
  tmpdir=$(make_tempdir)
  stubdir="$tmpdir/stubs"
  mkdir -p "$stubdir"
  original_path=$PATH

  cat <<'STUB' >"$stubdir/read-magic"
#!/bin/sh
printf '%s\n' "read-magic: attribute does not exist."
exit 1
STUB
  chmod +x "$stubdir/read-magic"

  LOOK_RC_FILE="$tmpdir/look_rc"
  HOME="$tmpdir/home/me"
  TMPDIR="$tmpdir/tmp"
  LOOK_HOME_PATH="$HOME"
  mkdir -p "$HOME" "$TMPDIR"

  cat <<'BLOCK' >"$LOOK_RC_FILE"
# >>> wizardry look spell >>>
# <<< wizardry look spell <<<
BLOCK

  export LOOK_RC_FILE HOME TMPDIR LOOK_HOME_PATH
  export NO_COLOR=1
  export PATH="$stubdir:$PATH"
}

teardown_stubbed_env() {
  if [ -n "${tmpdir-}" ]; then
    rm -rf "$tmpdir"
  fi
  if [ -n "${original_path-}" ]; then
    PATH=$original_path
  fi
}

test_help() {
  run_spell "spells/mud/look" --help
  assert_success && assert_output_contains "Usage: look"
}

test_home_default_description() {
  setup_stubbed_env
  run_spell "spells/mud/look" "$HOME"
  assert_success || return 1
  assert_output_contains "Your home folder." || return 1
  teardown_stubbed_env
}

test_other_home_description() {
  setup_stubbed_env
  other_home=$(dirname -- "$HOME")/chris
  mkdir -p "$other_home"
  run_spell "spells/mud/look" "$other_home"
  assert_success || return 1
  assert_output_contains "chris' home folder." || return 1
  teardown_stubbed_env
}

test_root_description() {
  setup_stubbed_env
  run_spell "spells/mud/look" /
  assert_success || return 1
  assert_output_contains "The root of the filesystem." || return 1
  teardown_stubbed_env
}

test_folder_title_when_attributes_missing() {
  setup_stubbed_env
  room="$TMPDIR/case.e2Sw9n"
  mkdir -p "$room"
  run_spell "spells/mud/look" "$room"
  assert_success || return 1
  case "$OUTPUT" in
    *"case.e2Sw9n"*) : ;;
    *) TEST_FAILURE_REASON="output missing folder name"; return 1 ;;
  esac
  last_line=$(printf '%s' "$OUTPUT" | tail -n 1)
  case "$last_line" in
    *.) : ;;
    *) TEST_FAILURE_REASON="description missing trailing period"; return 1 ;;
  esac
  teardown_stubbed_env
}

test_reads_attributes_when_present() {
  setup_stubbed_env
  cat <<'STUB' >"$stubdir/read-magic"
#!/bin/sh
case "$2" in
  title) printf '%s\n' "Custom Title" ;;
  description) printf '%s\n' "Custom Description." ;;
esac
exit 0
STUB
  chmod +x "$stubdir/read-magic"
  run_spell "spells/mud/look" "$TMPDIR"
  assert_success || return 1
  assert_output_contains "Custom Title" || return 1
  assert_output_contains "Custom Description." || return 1
  teardown_stubbed_env
}

test_installs_rc_block_when_approved() {
  setup_stubbed_env
  cat <<'STUB' >"$stubdir/ask_yn"
#!/bin/sh
exit 0
STUB
  chmod +x "$stubdir/ask_yn"
  run_spell "spells/mud/look" "$TMPDIR"
  assert_success || return 1
  assert_file_contains "$LOOK_RC_FILE" "alias look"
  teardown_stubbed_env
}

test_declines_install_when_rejected() {
  setup_stubbed_env
  cat <<'STUB' >"$stubdir/ask_yn"
#!/bin/sh
exit 1
STUB
  chmod +x "$stubdir/ask_yn"
  run_spell "spells/mud/look" "$TMPDIR"
  assert_success || return 1
  if grep -Fq "alias look" "$LOOK_RC_FILE"; then
    TEST_FAILURE_REASON="rc file unexpectedly updated"
    return 1
  fi
  teardown_stubbed_env
}

run_test_case "prints help" test_help
run_test_case "shows default home description" test_home_default_description
run_test_case "shows other user's home description" test_other_home_description
run_test_case "recognizes root description" test_root_description
run_test_case "uses folder title when attributes missing" test_folder_title_when_attributes_missing
run_test_case "prints enchanted attributes" test_reads_attributes_when_present
run_test_case "installs rc block when approved" test_installs_rc_block_when_approved
run_test_case "skips rc install when declined" test_declines_install_when_rejected
finish_tests
