#!/bin/sh
# Tests for the 'nix-rebuild' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_nix_rebuild_skips_when_disabled() {
  # Test that WIZARDRY_SKIP_NIX_REBUILD=1 causes immediate success
  WIZARDRY_SKIP_NIX_REBUILD=1 _run_spell spells/.imps/sys/nix-rebuild
  _assert_success || return 1
}

test_nix_rebuild_runs_home_manager() {
  skip-if-compiled || return $?
  stub=$(_make_tempdir)
  
  # Create home-manager stub that logs its invocation
  home_manager_log="$stub/home-manager.log"
  cat >"$stub/home-manager" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$home_manager_log"
exit 0
STUB
  chmod +x "$stub/home-manager"
  
  _link_tools "$stub" sh printf test command
  
  # Run nix-rebuild - should find and run home-manager
  PATH="$stub:$WIZARDRY_TEST_MINIMAL_PATH" _run_spell spells/.imps/sys/nix-rebuild
  _assert_success || return 1
  
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
  skip-if-compiled || return $?
  stub=$(_make_tempdir)
  _link_tools "$stub" sh printf test
  
  # Create a 'command' stub that always returns failure (simulates tools not found)
  cat >"$stub/command" <<'STUB'
#!/bin/sh
exit 1
STUB
  chmod +x "$stub/command"
  
  # Run nix-rebuild with no home-manager or nixos-rebuild available
  PATH="$stub:$WIZARDRY_TEST_MINIMAL_PATH" _run_spell spells/.imps/sys/nix-rebuild
  _assert_failure || return 1
  _assert_error_contains "could not be automatically rebuilt" || return 1
}

_run_test_case "nix-rebuild skips when WIZARDRY_SKIP_NIX_REBUILD=1" test_nix_rebuild_skips_when_disabled
_run_test_case "nix-rebuild runs home-manager switch" test_nix_rebuild_runs_home_manager
_run_test_case "nix-rebuild reports failure when no tools available" test_nix_rebuild_reports_failure_when_no_tools

_finish_tests
