#!/bin/sh
# Tests for the 'nix-shell-status' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Skip nix rebuild in tests since nixos-rebuild and home-manager aren't available
export WIZARDRY_SKIP_NIX_REBUILD=1
# Skip confirmation prompts in tests
export WIZARDRY_SKIP_CONFIRM=1

test_nix_shell_status_returns_false_when_not_present() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Status should fail when not present
  if "$ROOT_DIR/spells/.imps/sys/nix-shell-status" testspell "$nix_file" 2>/dev/null; then
    TEST_FAILURE_REASON="status should fail when not present"
    return 1
  fi
}

test_nix_shell_status_returns_true_when_present() {
  tmpdir=$(_make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Add the block
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-add" testspell "$nix_file" bash
  
  # Status should succeed when present
  if ! "$ROOT_DIR/spells/.imps/sys/nix-shell-status" testspell "$nix_file" 2>/dev/null; then
    TEST_FAILURE_REASON="status should succeed when present"
    return 1
  fi
}

_run_test_case "nix-shell-status returns false when not present" test_nix_shell_status_returns_false_when_not_present
_run_test_case "nix-shell-status returns true when present" test_nix_shell_status_returns_true_when_present

_finish_tests
