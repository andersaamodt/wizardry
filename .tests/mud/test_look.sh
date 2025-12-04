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

  cat <<'STUB' >"$stubdir/has"
#!/bin/sh
case "$1" in
  ask_yn|colors) exit 1 ;;
  *) command -v "$1" >/dev/null 2>&1 ;;
esac
STUB
  chmod +x "$stubdir/has"

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
}

test_help() {
  run_spell "spells/mud/look" --help
  assert_success && assert_output_contains "Usage: look"
}

test_home_default_description() {
  setup_stubbed_env
  PATH="$stubdir:$PATH" HOME="$HOME" TMPDIR="$TMPDIR" LOOK_RC_FILE="$LOOK_RC_FILE" LOOK_HOME_PATH="$LOOK_HOME_PATH" run_spell "spells/mud/look" "$HOME"
  assert_success || return 1
  assert_output_contains "Your home folder." || return 1
}

test_other_home_description() {
  setup_stubbed_env
  other_home=$(dirname -- "$HOME")/chris
  mkdir -p "$other_home"
  PATH="$stubdir:$PATH" HOME="$HOME" TMPDIR="$TMPDIR" LOOK_RC_FILE="$LOOK_RC_FILE" LOOK_HOME_PATH="$LOOK_HOME_PATH" run_spell "spells/mud/look" "$other_home"
  assert_success || return 1
  assert_output_contains "chris' home folder." || return 1
}

test_root_description() {
  setup_stubbed_env
  PATH="$stubdir:$PATH" HOME="$HOME" TMPDIR="$TMPDIR" LOOK_RC_FILE="$LOOK_RC_FILE" LOOK_HOME_PATH="$LOOK_HOME_PATH" run_spell "spells/mud/look" /
  assert_success || return 1
  assert_output_contains "The root of the filesystem." || return 1
}

run_test_case "prints help" test_help
run_test_case "shows default home description" test_home_default_description
run_test_case "shows other user's home description" test_other_home_description
run_test_case "recognizes root description" test_root_description
finish_tests
