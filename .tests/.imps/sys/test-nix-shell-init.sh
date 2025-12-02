#!/bin/sh
# Tests for the 'nix-shell-init' imp

. "${0%/*}/../../test-common.sh"

# Skip nix rebuild in tests since nixos-rebuild and home-manager aren't available
export WIZARDRY_SKIP_NIX_REBUILD=1

test_nix_shell_init_help() {
  run_spell "spells/.imps/sys/nix-shell-init" --help
  assert_success
  assert_error_contains "Usage:"
}

test_nix_shell_init_add_creates_block() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Add shell init code
  result=$(printf 'source "/path/to/spell"' | HOME="$tmpdir" "$ROOT_DIR/spells/.imps/sys/nix-shell-init" add --shell bash --name testspell --file "$nix_file" 2>&1) || {
    TEST_FAILURE_REASON="nix-shell-init add failed: $result"
    return 1
  }
  
  # Verify the file contains the expected content
  if ! grep -q "programs.bash.initExtra" "$nix_file"; then
    TEST_FAILURE_REASON="expected programs.bash.initExtra in file"
    return 1
  fi
  if ! grep -q "wizardry: testspell" "$nix_file"; then
    TEST_FAILURE_REASON="expected wizardry-shell marker in file"
    return 1
  fi
  if ! grep -q 'source "/path/to/spell"' "$nix_file"; then
    TEST_FAILURE_REASON="expected source command in file"
    return 1
  fi
}

test_nix_shell_init_add_is_idempotent() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Add shell init code twice
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-init" add --shell bash --name testspell --file "$nix_file"
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-init" add --shell bash --name testspell --file "$nix_file"
  
  # Count markers - should be exactly 3 (opening line, content line, closing line)
  # Each line is marked with #wizardry: NAME for clean removal
  marker_count=$(grep -c "wizardry: testspell" "$nix_file" || printf '0')
  if [ "$marker_count" -ne 3 ]; then
    TEST_FAILURE_REASON="expected exactly 3 markers (idempotent), found $marker_count"
    return 1
  fi
}

test_nix_shell_init_status_returns_correct_result() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Status should fail when not present
  if "$ROOT_DIR/spells/.imps/sys/nix-shell-init" status --shell bash --name testspell --file "$nix_file" 2>/dev/null; then
    TEST_FAILURE_REASON="status should fail when not present"
    return 1
  fi
  
  # Add the block
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-init" add --shell bash --name testspell --file "$nix_file"
  
  # Status should succeed when present
  if ! "$ROOT_DIR/spells/.imps/sys/nix-shell-init" status --shell bash --name testspell --file "$nix_file" 2>/dev/null; then
    TEST_FAILURE_REASON="status should succeed when present"
    return 1
  fi
}

test_nix_shell_init_remove_clears_block() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Add shell init code
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-init" add --shell bash --name testspell --file "$nix_file"
  
  # Verify it was added
  if ! grep -q "wizardry: testspell" "$nix_file"; then
    TEST_FAILURE_REASON="block was not added"
    return 1
  fi
  
  # Remove it
  "$ROOT_DIR/spells/.imps/sys/nix-shell-init" remove --shell bash --name testspell --file "$nix_file"
  
  # Verify it was removed
  if grep -q "wizardry: testspell" "$nix_file"; then
    TEST_FAILURE_REASON="block was not removed"
    return 1
  fi
}

test_nix_shell_init_zsh_uses_correct_option() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Add shell init code for zsh
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-init" add --shell zsh --name testspell --file "$nix_file"
  
  # Verify it uses programs.zsh.initExtra
  if ! grep -q "programs.zsh.initExtra" "$nix_file"; then
    TEST_FAILURE_REASON="expected programs.zsh.initExtra for zsh shell"
    return 1
  fi
}

test_nix_shell_init_creates_file_if_missing() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/subdir/test.nix"
  
  # File doesn't exist yet
  printf 'source "/path/to/spell"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-init" add --shell bash --name testspell --file "$nix_file"
  
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

test_nix_shell_init_multiline_code() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Add multi-line shell init code
  printf 'if [ -f "/path/to/spell" ]; then\n  source "/path/to/spell"\nfi' | "$ROOT_DIR/spells/.imps/sys/nix-shell-init" add --shell bash --name testspell --file "$nix_file"
  
  # Verify multi-line content is present
  if ! grep -q 'source "/path/to/spell"' "$nix_file"; then
    TEST_FAILURE_REASON="multi-line content not found"
    return 1
  fi
}

test_nix_shell_init_requires_action() {
  if "$ROOT_DIR/spells/.imps/sys/nix-shell-init" --name test --file /tmp/test.nix 2>/dev/null; then
    TEST_FAILURE_REASON="should fail without action"
    return 1
  fi
  return 0
}

test_nix_shell_init_requires_name() {
  if printf 'test' | "$ROOT_DIR/spells/.imps/sys/nix-shell-init" add --file /tmp/test.nix 2>/dev/null; then
    TEST_FAILURE_REASON="should fail without --name"
    return 1
  fi
  return 0
}

test_nix_shell_init_requires_file() {
  if printf 'test' | "$ROOT_DIR/spells/.imps/sys/nix-shell-init" add --name test 2>/dev/null; then
    TEST_FAILURE_REASON="should fail without --file"
    return 1
  fi
  return 0
}

run_test_case "nix-shell-init shows help" test_nix_shell_init_help
run_test_case "nix-shell-init add creates block" test_nix_shell_init_add_creates_block
run_test_case "nix-shell-init add is idempotent" test_nix_shell_init_add_is_idempotent
run_test_case "nix-shell-init status returns correct result" test_nix_shell_init_status_returns_correct_result
run_test_case "nix-shell-init remove clears block" test_nix_shell_init_remove_clears_block
run_test_case "nix-shell-init zsh uses correct option" test_nix_shell_init_zsh_uses_correct_option
run_test_case "nix-shell-init creates file if missing" test_nix_shell_init_creates_file_if_missing
run_test_case "nix-shell-init handles multiline code" test_nix_shell_init_multiline_code
run_test_case "nix-shell-init requires action" test_nix_shell_init_requires_action
run_test_case "nix-shell-init requires name" test_nix_shell_init_requires_name
run_test_case "nix-shell-init requires file" test_nix_shell_init_requires_file

test_nix_shell_init_escapes_special_chars() {
  tmpdir=$(make_tempdir)
  nix_file="$tmpdir/test.nix"
  
  # Create minimal nix file
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_file"
  
  # Add shell code with special characters that need escaping
  # The ${ needs to be escaped as ''${ in nix '' strings
  printf 'echo "${HOME}/test"' | "$ROOT_DIR/spells/.imps/sys/nix-shell-init" add --shell bash --name escapespell --file "$nix_file"
  
  # Verify the file is valid (the escaping worked)
  if ! grep -q "wizardry: escapespell" "$nix_file"; then
    TEST_FAILURE_REASON="spell was not added"
    return 1
  fi
  
  # The original shell code should be preserved (with escaping)
  if ! grep -q 'HOME' "$nix_file"; then
    TEST_FAILURE_REASON="shell code content not found"
    return 1
  fi
}

run_test_case "nix-shell-init escapes special chars" test_nix_shell_init_escapes_special_chars

finish_tests
