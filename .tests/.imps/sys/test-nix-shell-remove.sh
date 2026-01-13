#!/bin/sh
# Tests for the 'nix-shell-remove' imp

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

test_nix_shell_remove_clears_block() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Add shell init code
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-add" testspell "$nix_file" bash
  
  # Verify it was added
  if ! grep -q "wizardry: testspell" "$nix_file"; then
    TEST_FAILURE_REASON="block was not added"
    return 1
  fi
  
  # Remove it
  "$ROOT_DIR/spells/.imps/sys/nix-shell-remove" testspell "$nix_file"
  
  # Verify it was removed
  if grep -q "wizardry: testspell" "$nix_file"; then
    TEST_FAILURE_REASON="block was not removed"
    return 1
  fi
}

test_nix_shell_remove_is_idempotent() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Remove on non-existent block should succeed (no-op)
  if ! "$ROOT_DIR/spells/.imps/sys/nix-shell-remove" testspell "$nix_file" 2>/dev/null; then
    TEST_FAILURE_REASON="remove should succeed even when block not present"
    return 1
  fi
}

run_test_case "nix-shell-remove clears block" test_nix_shell_remove_clears_block
run_test_case "nix-shell-remove is idempotent" test_nix_shell_remove_is_idempotent

finish_tests
