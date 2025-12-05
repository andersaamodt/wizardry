#!/bin/sh
# Tests for the 'detect-trash' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
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


test_detect_trash_outputs_path() {
  run_spell spells/.imps/menu/detect-trash
  assert_success || return 1
  # Should output a non-empty path
  [ -n "$OUTPUT" ] || { TEST_FAILURE_REASON="should output trash path"; return 1; }
}

test_detect_trash_macos_path() {
  stub=$(make_tempdir)
  # Create uname stub for macOS detection
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Darwin\n'
STUB
  chmod +x "$stub/uname"

  # Run detect-trash with custom HOME by wrapping in a shell script
  run_cmd sh -c "
    HOME='/Users/testuser'
    export HOME
    PATH='$stub:/bin:/usr/bin'
    export PATH
    '$ROOT_DIR/spells/.imps/menu/detect-trash'
  "
  assert_success || return 1
  assert_output_contains "/Users/testuser/.Trash" || return 1
}

test_detect_trash_linux_path() {
  stub=$(make_tempdir)
  # Create uname stub for Linux detection
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$stub/uname"

  # Run detect-trash with custom HOME by wrapping in a shell script
  run_cmd sh -c "
    HOME='/home/testuser'
    export HOME
    PATH='$stub:/bin:/usr/bin'
    export PATH
    '$ROOT_DIR/spells/.imps/menu/detect-trash'
  "
  assert_success || return 1
  assert_output_contains "/home/testuser/.local/share/Trash/files" || return 1
}

test_detect_trash_xdg_override() {
  stub=$(make_tempdir)
  # Create uname stub for Linux detection
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$stub/uname"

  # Run detect-trash with custom HOME and XDG_DATA_HOME
  run_cmd sh -c "
    HOME='/home/testuser'
    XDG_DATA_HOME='/custom/data'
    export HOME XDG_DATA_HOME
    PATH='$stub:/bin:/usr/bin'
    export PATH
    '$ROOT_DIR/spells/.imps/menu/detect-trash'
  "
  assert_success || return 1
  assert_output_contains "/custom/data/Trash/files" || return 1
}

test_detect_trash_unsupported_os() {
  stub=$(make_tempdir)
  # Create uname stub for unknown OS
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'FreeBSD\n'
STUB
  chmod +x "$stub/uname"
  link_tools "$stub" sh printf

  run_cmd sh -c "
    PATH='$stub'
    export PATH
    '$ROOT_DIR/spells/.imps/menu/detect-trash'
  "
  assert_failure || return 1
  assert_error_contains "unsupported operating system" || return 1
}

run_test_case "detect-trash outputs path" test_detect_trash_outputs_path
run_test_case "detect-trash returns macOS path" test_detect_trash_macos_path
run_test_case "detect-trash returns Linux path" test_detect_trash_linux_path
run_test_case "detect-trash respects XDG_DATA_HOME" test_detect_trash_xdg_override
run_test_case "detect-trash fails on unsupported OS" test_detect_trash_unsupported_os

finish_tests
