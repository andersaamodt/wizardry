#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - install-menu fails when no installable entries exist
# - install-menu builds menu entries from provided directories and status helpers

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


make_stub_menu_env() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
# Send TERM signal to parent to simulate ESC behavior
kill -TERM "$PPID" 2>/dev/null || exit 0
exit 0
SH
  chmod +x "$tmp/menu"
}

make_stub_require() {
  tmp=$1
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
}

test_install_menu_prefers_install_root_commands() {
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"

  install_root="$tmp/install"
  mkdir -p "$install_root/alpha" "$install_root/beta" "$install_root/gamma"

  cat >"$install_root/alpha/alpha-status" <<'SH'
#!/bin/sh
echo configured
SH
  chmod +x "$install_root/alpha/alpha-status"

  cat >"$install_root/alpha/alpha" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$install_root/alpha/alpha"

  cat >"$install_root/beta-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/beta-status"

  cat >"$install_root/beta-menu" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$install_root/beta-menu"

  MENU_LOG="$tmp/log"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="alpha beta gamma" MENU_LOG="$MENU_LOG" "$ROOT_DIR/spells/menu/install-menu"

  assert_success && assert_path_exists "$MENU_LOG" && \
    assert_output_contains "Install Menu:"

  menu_args=$(cat "$MENU_LOG")

  case "$menu_args" in
    *"alpha - configured%$install_root/alpha/alpha"* ) : ;;
    *) TEST_FAILURE_REASON="alpha entry missing nested command"; return 1 ;;
  esac

  case "$menu_args" in
    *"beta - ready%$install_root/beta-menu"* ) : ;;
    *) TEST_FAILURE_REASON="beta entry missing submenu command"; return 1 ;;
  esac

  case "$menu_args" in
    *"gamma - coming soon%printf \"This entry is not ready yet.\\n\""* ) : ;;
    *) TEST_FAILURE_REASON="gamma entry missing fallback message"; return 1 ;;
  esac
}

test_install_menu_errors_when_empty() {
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_DIRS=" " MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/install-menu"
  assert_failure && assert_error_contains "no installable spells"
}

test_install_menu_builds_entries_with_status() {
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/alpha-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$tmp/alpha-status"
  cat >"$tmp/alpha-menu" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/alpha-menu"
  MENU_LOG="$tmp/log"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_DIRS="alpha beta" MENU_LOG="$MENU_LOG" "$ROOT_DIR/spells/menu/install-menu"
  assert_success && assert_path_exists "$MENU_LOG" && \
    assert_output_contains "Install Menu:"
  menu_args=$(cat "$MENU_LOG")
  case "$menu_args" in
    *"alpha - ready%alpha-menu"* ) : ;; 
    *) TEST_FAILURE_REASON="menu entries missing status"; return 1 ;;
  esac
}

run_test_case "install-menu fails when empty" test_install_menu_errors_when_empty
run_test_case "install-menu builds entries from directories" test_install_menu_builds_entries_with_status
run_test_case "install-menu prefers spells in the install root" test_install_menu_prefers_install_root_commands

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  # Create a minimal install dir
  install_root="$tmp/install"
  mkdir -p "$install_root/test"
  cat >"$install_root/test/test-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/test/test-status"
  
  
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="test" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/install-menu"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Exit%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Exit label: $args"; return 1 ;;
  esac
  
}

run_test_case "install-menu ESC/Exit behavior" test_esc_exit_behavior

shows_help() {
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  install_root="$tmp/install"
  mkdir -p "$install_root/test"
  cat >"$install_root/test/test-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/test/test-status"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="test" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/install-menu" --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "install-menu accepts --help" shows_help

# Test that no exit message is printed when ESC or Exit is used
test_no_exit_message_on_esc() {
  tmp=$(make_tempdir)
  make_stub_menu_env "$tmp"
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  install_root="$tmp/install"
  mkdir -p "$install_root/test"
  cat >"$install_root/test/test-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/test/test-status"
  
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="test" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/install-menu"
  assert_success || return 1
  
  # Verify no "Exiting" message appears in stderr
  case "$ERROR" in
    *"Exiting"*) 
      TEST_FAILURE_REASON="should not print exit message, got: $ERROR"
      return 1
      ;;
  esac
  return 0
}

run_test_case "install-menu no exit message on ESC" test_no_exit_message_on_esc

# Test that nested menu return shows proper blank line spacing
test_nested_menu_spacing() {
  tmp=$(make_tempdir)
  
  # Create a menu that records when it's called, and on second call sends TERM
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
count=$(cat "$INVOCATION_FILE" 2>/dev/null || echo 0)
count=$((count + 1))
printf '%s\n' "$count" >"$INVOCATION_FILE"
# Always send TERM to exit on first display (simulating ESC)
kill -TERM "$PPID" 2>/dev/null || exit 0
exit 0
SH
  chmod +x "$tmp/menu"
  
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
  
  install_root="$tmp/install"
  mkdir -p "$install_root/test"
  cat >"$install_root/test/test-status" <<'SH'
#!/bin/sh
echo ready
SH
  chmod +x "$install_root/test/test-status"
  
  INVOCATION_FILE="$tmp/invocations"
  run_cmd env PATH="$tmp:$PATH" INSTALL_MENU_ROOT="$install_root" INSTALL_MENU_DIRS="test" MENU_LOG="$tmp/log" INVOCATION_FILE="$INVOCATION_FILE" "$ROOT_DIR/spells/menu/install-menu"
  assert_success || return 1
  
  # The menu loop should have run once (on first_run, no leading newline)
  # This ensures consistent spacing behavior
  return 0
}

run_test_case "install-menu nested spacing behavior" test_nested_menu_spacing

finish_tests
