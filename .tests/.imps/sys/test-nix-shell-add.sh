#!/bin/sh
# Tests for the 'nix-shell-add' imp

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

test_nix_shell_add_creates_block() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Add shell init code
  result=$(printf 'source "/path/to/spell"' | HOME="$tmpdir" "$ROOT_DIR/spells/.imps/sys/nix-shell-add" testspell "$nix_file" bash 2>&1) || {
    TEST_FAILURE_REASON="nix-shell-add failed: $result"
    return 1
  }
  
  # Verify the file contains the expected content
  if ! grep -q "programs.bash.initExtra" "$nix_file"; then
    TEST_FAILURE_REASON="expected programs.bash.initExtra in file"
    return 1
  fi
  if ! grep -q "wizardry: testspell" "$nix_file"; then
    TEST_FAILURE_REASON="expected wizardry marker in file"
    return 1
  fi
  if ! grep -q 'source "/path/to/spell"' "$nix_file"; then
    TEST_FAILURE_REASON="expected source command in file"
    return 1
  fi
}

test_nix_shell_add_is_idempotent() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Add shell init code twice
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-add" testspell "$nix_file" bash
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-add" testspell "$nix_file" bash
  
  # Count markers - should be exactly 1 (only content line is marked, not opening/closing syntax)
  marker_count=$(grep -c "wizardry: testspell" "$nix_file" || printf '0')
  if [ "$marker_count" -ne 1 ]; then
    TEST_FAILURE_REASON="expected exactly 1 marker (only content line), found $marker_count"
    return 1
  fi
}

test_nix_shell_add_zsh_uses_correct_option() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Add shell init code for zsh
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-add" testspell "$nix_file" zsh
  
  # Verify it uses programs.zsh.initExtra
  if ! grep -q "programs.zsh.initExtra" "$nix_file"; then
    TEST_FAILURE_REASON="expected programs.zsh.initExtra for zsh shell"
    return 1
  fi
}

test_nix_shell_add_creates_file_if_missing() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/subdir/test.nix"
  
  # File doesn't exist yet
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-add" testspell "$nix_file" bash
  
  # Verify file was created with proper structure
  if [ ! -f "$nix_file" ]; then
    TEST_FAILURE_REASON="file was not created"
    return 1
  fi
  if ! grep -q "{ config, pkgs" "$nix_file"; then
    TEST_FAILURE_REASON="file missing nix header"
    return 1
  fi
}

test_nix_shell_add_requires_name() {
  skip-if-compiled || return $?
  if printf 'test' | "$ROOT_DIR/spells/.imps/sys/nix-shell-add" "" /tmp/test.nix 2>/dev/null; then
    TEST_FAILURE_REASON="should fail without name"
    return 1
  fi
  return 0
}

test_nix_shell_add_requires_file() {
  skip-if-compiled || return $?
  if printf 'test' | "$ROOT_DIR/spells/.imps/sys/nix-shell-add" test "" 2>/dev/null; then
    TEST_FAILURE_REASON="should fail without file"
    return 1
  fi
  return 0
}

run_test_case "nix-shell-add creates block" test_nix_shell_add_creates_block
run_test_case "nix-shell-add is idempotent" test_nix_shell_add_is_idempotent
run_test_case "nix-shell-add zsh uses correct option" test_nix_shell_add_zsh_uses_correct_option
run_test_case "nix-shell-add creates file if missing" test_nix_shell_add_creates_file_if_missing
run_test_case "nix-shell-add requires name" test_nix_shell_add_requires_name
run_test_case "nix-shell-add requires file" test_nix_shell_add_requires_file

finish_tests
