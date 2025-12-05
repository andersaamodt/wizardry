#!/bin/sh
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


spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/core/core-menu" ]
}

core_menu_lists_dependencies() {
  tmp=$(make_tempdir)

  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"$MENU_LOG"
SH
  chmod +x "$tmp/menu"

  cat >"$tmp/colors" <<'SH'
#!/bin/sh
BOLD=''
CYAN=''
RESET=''
SH
  chmod +x "$tmp/colors"

  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
echo "$@" >>"${REQUIRE_LOG:?}"
exit 0
SH
  chmod +x "$tmp/require-command"

  ln -s /bin/sh "$tmp/sh"
  ln -s /usr/bin/dirname "$tmp/dirname"
  ln -s /bin/grep "$tmp/grep"
  ln -s /bin/cat "$tmp/cat"

  MENU_LOG="$tmp/log" run_cmd env PATH="$tmp:/bin:/usr/bin" MENU_LOOP_LIMIT=1 MENU_LOG="$tmp/log" COLORS_BIN="$tmp/colors" MENU_BIN="$tmp/menu" \
    "$ROOT_DIR/spells/install/core/core-menu"

  assert_success || return 1
  assert_path_exists "$tmp/log" || return 1
  log=$(cat "$tmp/log")

  platform=$(uname -s 2>/dev/null || printf 'unknown')
  case "$platform" in
    Darwin)
      case "$log" in
        *"Install Bubblewrap"* ) TEST_FAILURE_REASON="bubblewrap should be skipped on Darwin"; return 1 ;;
        *) : ;;
      esac
      ;;
    *)
      case "$log" in
        *"Install Bubblewrap"* ) : ;;
        *) TEST_FAILURE_REASON="missing bubblewrap entry"; return 1 ;;
      esac
      ;;
  esac

  case "$log" in
    *"Install all"* ) : ;;
    *) TEST_FAILURE_REASON="missing install all entry"; return 1 ;;
  esac
}

essential_commands_show_status_not_uninstall() {
  tmp=$(make_tempdir)

  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"$MENU_LOG"
SH
  chmod +x "$tmp/menu"

  cat >"$tmp/colors" <<'SH'
#!/bin/sh
BOLD=''
CYAN=''
RESET=''
SH
  chmod +x "$tmp/colors"

  ln -s /bin/sh "$tmp/sh"
  ln -s /usr/bin/dirname "$tmp/dirname"
  ln -s /bin/grep "$tmp/grep"
  ln -s /bin/cat "$tmp/cat"

  # dd, stty, tput are essential and should show "- installed" or "- not installed"
  # instead of "Uninstall dd"
  MENU_LOG="$tmp/log" run_cmd env PATH="$tmp:/bin:/usr/bin" MENU_LOOP_LIMIT=1 MENU_LOG="$tmp/log" COLORS_BIN="$tmp/colors" MENU_BIN="$tmp/menu" \
    "$ROOT_DIR/spells/install/core/core-menu"

  assert_success || return 1
  assert_path_exists "$tmp/log" || return 1
  log=$(cat "$tmp/log")

  # Essential commands should NOT have "Uninstall" option
  case "$log" in
    *"Uninstall dd"* ) TEST_FAILURE_REASON="dd should not have Uninstall option"; return 1 ;;
    *) : ;;
  esac
  case "$log" in
    *"Uninstall stty"* ) TEST_FAILURE_REASON="stty should not have Uninstall option"; return 1 ;;
    *) : ;;
  esac
  case "$log" in
    *"Uninstall tput"* ) TEST_FAILURE_REASON="tput should not have Uninstall option"; return 1 ;;
    *) : ;;
  esac

  # Essential commands should show status with " - installed" or " - not installed"
  # dd is typically installed on all systems
  case "$log" in
    *"dd - installed"*|*"dd - not installed"* ) : ;;
    *) TEST_FAILURE_REASON="dd should show '- installed' or '- not installed' status"; return 1 ;;
  esac

  # stty is typically installed on all systems
  case "$log" in
    *"stty - installed"*|*"stty - not installed"* ) : ;;
    *) TEST_FAILURE_REASON="stty should show '- installed' or '- not installed' status"; return 1 ;;
  esac

  # tput is typically installed on all systems
  case "$log" in
    *"tput - installed"*|*"tput - not installed"* ) : ;;
    *) TEST_FAILURE_REASON="tput should show '- installed' or '- not installed' status"; return 1 ;;
  esac
}

run_test_case "install/core/core-menu is executable" spell_is_executable
run_test_case "core menu lists install targets" core_menu_lists_dependencies
run_test_case "essential commands show status not uninstall" essential_commands_show_status_not_uninstall

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/install/core/core-menu" --help
  assert_success
  assert_output_contains "Usage: core-menu"
}

run_test_case "core-menu --help shows usage" test_shows_help

finish_tests
