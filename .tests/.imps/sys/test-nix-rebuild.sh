#!/bin/sh
# Tests for the 'nix-rebuild' imp

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


test_nix_rebuild_skips_when_disabled() {
  # Test that WIZARDRY_SKIP_NIX_REBUILD=1 causes immediate success
  WIZARDRY_SKIP_NIX_REBUILD=1 run_spell spells/.imps/sys/nix-rebuild
  assert_success || return 1
}

test_nix_rebuild_runs_home_manager() {
  stub=$(make_tempdir)
  
  # Create home-manager stub that logs its invocation
  home_manager_log="$stub/home-manager.log"
  cat >"$stub/home-manager" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$home_manager_log"
exit 0
STUB
  chmod +x "$stub/home-manager"
  
  link_tools "$stub" sh printf test command
  
  # Run nix-rebuild - should find and run home-manager
  PATH="$stub:/bin:/usr/bin" run_spell spells/.imps/sys/nix-rebuild
  assert_success || return 1
  
  # Check that home-manager switch was called
  if [ -f "$home_manager_log" ]; then
    if grep -q "switch" "$home_manager_log"; then
      return 0
    fi
    TEST_FAILURE_REASON="home-manager was not called with 'switch': $(cat "$home_manager_log")"
    return 1
  fi
  TEST_FAILURE_REASON="home-manager was not called"
  return 1
}

test_nix_rebuild_reports_failure_when_no_tools() {
  stub=$(make_tempdir)
  link_tools "$stub" sh printf test
  
  # Create a 'command' stub that always returns failure (simulates tools not found)
  cat >"$stub/command" <<'STUB'
#!/bin/sh
exit 1
STUB
  chmod +x "$stub/command"
  
  # Run nix-rebuild with no home-manager or nixos-rebuild available
  PATH="$stub:/bin:/usr/bin" run_spell spells/.imps/sys/nix-rebuild
  assert_failure || return 1
  assert_error_contains "could not be automatically rebuilt" || return 1
}

run_test_case "nix-rebuild skips when WIZARDRY_SKIP_NIX_REBUILD=1" test_nix_rebuild_skips_when_disabled
run_test_case "nix-rebuild runs home-manager switch" test_nix_rebuild_runs_home_manager
run_test_case "nix-rebuild reports failure when no tools available" test_nix_rebuild_reports_failure_when_no_tools

finish_tests
