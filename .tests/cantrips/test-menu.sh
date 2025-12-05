#!/bin/sh
# Behavioral cases (derived from --help):
# - menu checks that required helpers exist before trying to draw
# - menu fails fast when no controlling terminal is available

set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


menu_requires_all_helpers() {
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" run_cmd env PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" "$ROOT_DIR/spells/cantrips/menu" "Menu" "Item%echo hi"
  assert_failure || return 1
  assert_error_contains "The menu spell needs 'fathom-cursor' to place the menu." || return 1
}

menu_reports_missing_tty() {
  stub_dir=$(make_tempdir)
  for helper in fathom-cursor fathom-terminal move-cursor await-keypress cursor-blink stty; do
    printf '#!/bin/sh\nexit 0\n' >"$stub_dir/$helper"
    chmod +x "$stub_dir/$helper"
  done

  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$stub_dir:/bin:/usr/bin" run_cmd env PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$stub_dir:/bin:/usr/bin" AWAIT_KEYPRESS_DEVICE="$stub_dir/fake-tty" \
    "$ROOT_DIR/spells/cantrips/menu" "Menu" "Item%echo hi"
  assert_failure || return 1
  assert_error_contains "menu: unable to access controlling terminal" || return 1
}

run_test_case "menu requires helper spells" menu_requires_all_helpers
run_test_case "menu reports missing controlling terminal" menu_reports_missing_tty

# Test --start-selection argument - Issue #198
# When --start-selection 2 is passed, pressing enter should select the second item
menu_respects_start_selection() {
  stub_dir=$(make_tempdir)
  
  # Create a fake TTY for testing
  touch "$stub_dir/fake-tty"
  chmod 600 "$stub_dir/fake-tty"
  
  # Create stubs for all required helper commands
  cat >"$stub_dir/fathom-cursor" <<'STUB'
#!/bin/sh
case $1 in
  -y) printf '1\n' ;;
  -x) printf '1\n' ;;
  *) printf '1 1\n' ;;
esac
STUB
  chmod +x "$stub_dir/fathom-cursor"
  
  cat >"$stub_dir/fathom-terminal" <<'STUB'
#!/bin/sh
case $1 in
  -w) printf '80\n' ;;
  -h) printf '24\n' ;;
  *) printf '80 24\n' ;;
esac
STUB
  chmod +x "$stub_dir/fathom-terminal"
  
  cat >"$stub_dir/move-cursor" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/move-cursor"
  
  # await-keypress returns "enter" immediately
  cat >"$stub_dir/await-keypress" <<'STUB'
#!/bin/sh
printf 'enter\n'
STUB
  chmod +x "$stub_dir/await-keypress"
  
  cat >"$stub_dir/cursor-blink" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/cursor-blink"
  
  cat >"$stub_dir/stty" <<'STUB'
#!/bin/sh
case $1 in
  -g) printf 'saved-state\n' ;;
  *) exit 0 ;;
esac
STUB
  chmod +x "$stub_dir/stty"
  
  # Run menu with --start-selection 2 and press enter immediately
  # Should execute the second item's command (printf second)
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$stub_dir:/bin:/usr/bin" run_cmd env \
    PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$stub_dir:/bin:/usr/bin" \
    AWAIT_KEYPRESS_DEVICE="$stub_dir/fake-tty" \
    "$ROOT_DIR/spells/cantrips/menu" --start-selection 2 "Test:" \
    "First%printf first" \
    "Second%printf second" \
    "Third%printf third"
  
  assert_success || return 1
  # The second item should have been selected since --start-selection 2
  case "$OUTPUT" in
    *second*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="expected 'second' in output but got: $OUTPUT"
      return 1
      ;;
  esac
}

run_test_case "menu respects --start-selection (Issue #198)" menu_respects_start_selection

# Test that highlighted items strip ANSI codes from labels
# This ensures the highlight color (CYAN) overrides embedded colors (like YELLOW)
menu_highlight_strips_ansi_codes() {
  stub_dir=$(make_tempdir)
  
  # Create a fake TTY for testing
  touch "$stub_dir/fake-tty"
  chmod 600 "$stub_dir/fake-tty"
  
  # Create stubs for all required helper commands
  cat >"$stub_dir/fathom-cursor" <<'STUB'
#!/bin/sh
case $1 in
  -y) printf '1\n' ;;
  -x) printf '1\n' ;;
  *) printf '1 1\n' ;;
esac
STUB
  chmod +x "$stub_dir/fathom-cursor"
  
  cat >"$stub_dir/fathom-terminal" <<'STUB'
#!/bin/sh
case $1 in
  -w) printf '80\n' ;;
  -h) printf '24\n' ;;
  *) printf '80 24\n' ;;
esac
STUB
  chmod +x "$stub_dir/fathom-terminal"
  
  cat >"$stub_dir/move-cursor" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/move-cursor"
  
  # await-keypress returns "enter" immediately
  cat >"$stub_dir/await-keypress" <<'STUB'
#!/bin/sh
printf 'enter\n'
STUB
  chmod +x "$stub_dir/await-keypress"
  
  cat >"$stub_dir/cursor-blink" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub_dir/cursor-blink"
  
  cat >"$stub_dir/stty" <<'STUB'
#!/bin/sh
case $1 in
  -g) printf 'saved-state\n' ;;
  *) exit 0 ;;
esac
STUB
  chmod +x "$stub_dir/stty"
  
  # Create an ANSI-colored label with ESC[33m (yellow) embedded
  # The output should NOT contain the yellow ANSI code (ESC[33m) for the highlighted item
  # but SHOULD contain the highlight color (ESC[36m = cyan)
  yellow_code=$(printf '\033[33m')
  reset_code=$(printf '\033[0m')
  
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$stub_dir:/bin:/usr/bin" run_cmd env \
    PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:$stub_dir:/bin:/usr/bin" \
    AWAIT_KEYPRESS_DEVICE="$stub_dir/fake-tty" \
    TERM=xterm \
    "$ROOT_DIR/spells/cantrips/menu" "Test:" \
    "${yellow_code}ColoredItem${reset_code}%printf selected"
  
  assert_success || return 1
  
  # Verify the command executed (item was selectable)
  case "$OUTPUT" in
    *selected*)
      : # good
      ;;
    *)
      TEST_FAILURE_REASON="expected 'selected' in output"
      return 1
      ;;
  esac
  
  # The highlighted row should NOT contain the yellow escape code
  # because the menu should strip it when highlighting
  case "$OUTPUT" in
    *"${yellow_code}"*)
      TEST_FAILURE_REASON="output should not contain yellow ANSI code in highlighted row"
      return 1
      ;;
  esac
  
  return 0
}

run_test_case "menu highlight strips ANSI codes from labels" menu_highlight_strips_ansi_codes

finish_tests
