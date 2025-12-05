#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - shutdown-menu requires the menu dependency
# - shutdown-menu forwards shutdown/restart actions to the menu
# - shutdown-menu includes optional Sleep and Hibernate when available

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


make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -TERM "$PPID" 2>/dev/null || exit 0; exit 0
SH
  chmod +x "$tmp/menu"
}

make_stub_require() {
  tmp=$1
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
printf '%s %s\n' "$1" "$2" >>"$REQUIRE_LOG"
exit 0
SH
  chmod +x "$tmp/require-command"
}

test_shutdown_menu_checks_requirements() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" REQUIRE_LOG="$tmp/req" "$ROOT_DIR/spells/menu/shutdown-menu"
  assert_success && assert_path_exists "$tmp/req"
}

test_shutdown_menu_includes_core_actions() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Back"
SH
  chmod +x "$tmp/exit-label"
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/shutdown-menu"
  assert_success
  args=$(cat "$tmp/log")
  # Logout command varies: loginctl terminate-user on systemd, pkill -TERM otherwise
  case "$args" in
    *"Restart / Shutdown:"*"Restart%sudo shutdown -r +0"*"Shutdown%sudo shutdown -h +0"*"Logout%loginctl terminate-user"*"Force restart%sudo reboot -f"*"Force shutdown%sudo poweroff -f"*"Force logout%pkill -KILL"*'Back%kill -TERM $PPID' ) : ;;
    *"Restart / Shutdown:"*"Restart%sudo shutdown -r +0"*"Shutdown%sudo shutdown -h +0"*"Logout%pkill -TERM"*"Force restart%sudo reboot -f"*"Force shutdown%sudo poweroff -f"*"Force logout%pkill -KILL"*'Back%kill -TERM $PPID' ) : ;;
    *) TEST_FAILURE_REASON="expected shutdown actions missing: $args"; return 1 ;;
  esac
}

run_test_case "shutdown-menu requires menu dependency" test_shutdown_menu_checks_requirements
run_test_case "shutdown-menu passes shutdown actions to menu" test_shutdown_menu_includes_core_actions

# Test ESC and Exit behavior - menu exits properly when escape status returned
test_esc_exit_behavior() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Back"
SH
  chmod +x "$tmp/exit-label"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/shutdown-menu"
  assert_success || { TEST_FAILURE_REASON="menu should exit successfully on escape"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *'Back%kill -TERM $PPID') : ;;
    *) TEST_FAILURE_REASON="menu should show Back label: $args"; return 1 ;;
  esac
}

run_test_case "shutdown-menu ESC/Exit behavior" test_esc_exit_behavior

# Test kernel-level fallback detection for sleep when can-suspend unavailable
test_sleep_kernel_fallback() {
  # Skip test if /sys/power/state doesn't exist (non-Linux or no power management)
  if [ ! -r /sys/power/state ]; then
    return 0
  fi
  
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Back"
SH
  chmod +x "$tmp/exit-label"
  
  # Create a stub systemctl that returns "Unknown command verb" for can-suspend
  # but still exists and works for other commands (simulates NixOS behavior)
  cat >"$tmp/systemctl" <<'SH'
#!/bin/sh
case "$1" in
  can-suspend|can-hibernate)
    printf '%s\n' "Unknown command verb '$1'" >&2
    exit 1
    ;;
  *)
    # Allow other systemctl commands to succeed (e.g., suspend, hibernate)
    exit 0
    ;;
esac
SH
  chmod +x "$tmp/systemctl"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/shutdown-menu"
  assert_success || return 1
  
  args=$(cat "$tmp/log")
  # Sleep should still be present if kernel supports it (mem in /sys/power/state)
  if grep -qw mem /sys/power/state 2>/dev/null; then
    case "$args" in
      *"Sleep%sudo systemctl suspend"*) : ;;
      *) TEST_FAILURE_REASON="Sleep should be detected via kernel fallback when can-suspend fails: $args"; return 1 ;;
    esac
  fi
}

run_test_case "shutdown-menu uses kernel fallback for sleep detection" test_sleep_kernel_fallback

# Test kernel-level fallback detection for hibernate when can-hibernate unavailable
test_hibernate_kernel_fallback() {
  # Skip test if /sys/power/state doesn't exist (non-Linux or no power management)
  if [ ! -r /sys/power/state ]; then
    return 0
  fi
  
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Back"
SH
  chmod +x "$tmp/exit-label"
  
  # Create a stub systemctl that returns "Unknown command verb" for can-hibernate
  # but still works for other commands (simulates NixOS behavior)
  cat >"$tmp/systemctl" <<'SH'
#!/bin/sh
case "$1" in
  can-suspend|can-hibernate)
    printf '%s\n' "Unknown command verb '$1'" >&2
    exit 1
    ;;
  *)
    # Allow other systemctl commands to succeed (e.g., suspend, hibernate)
    exit 0
    ;;
esac
SH
  chmod +x "$tmp/systemctl"
  
  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/shutdown-menu"
  assert_success || return 1
  
  args=$(cat "$tmp/log")
  # Hibernate should still be present if kernel supports it (disk in /sys/power/state)
  if grep -qw disk /sys/power/state 2>/dev/null; then
    case "$args" in
      *"Hibernate%sudo systemctl hibernate"*) : ;;
      *) TEST_FAILURE_REASON="Hibernate should be detected via kernel fallback when can-hibernate fails: $args"; return 1 ;;
    esac
  fi
}

run_test_case "shutdown-menu uses kernel fallback for hibernate detection" test_hibernate_kernel_fallback

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/menu/shutdown-menu" --help
  assert_success
  assert_output_contains "Usage: shutdown-menu"
}

run_test_case "shutdown-menu --help shows usage" test_shows_help

finish_tests
