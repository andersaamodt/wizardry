#!/bin/sh
# Tests for the 'shell-rc' imp

. "${0%/*}/../../test-common.sh"

test_shell_rc_finds_bashrc() {
  # Test shell-rc directly without sandbox since it relies on HOME
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir"
  touch "$tmpdir/.bashrc"
  
  result=$(HOME="$tmpdir" "$ROOT_DIR/spells/.imps/sys/shell-rc" 2>&1) || {
    TEST_FAILURE_REASON="shell-rc failed: $result"
    return 1
  }
  case "$result" in
    *".bashrc"*) return 0 ;;
    *) TEST_FAILURE_REASON="expected .bashrc in output, got: $result"; return 1 ;;
  esac
}

test_shell_rc_finds_zshrc() {
  # Create a temporary home directory with only .zshrc file
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir"
  touch "$tmpdir/.zshrc"
  
  result=$(HOME="$tmpdir" "$ROOT_DIR/spells/.imps/sys/shell-rc" 2>&1) || {
    TEST_FAILURE_REASON="shell-rc failed: $result"
    return 1
  }
  case "$result" in
    *".zshrc"*) return 0 ;;
    *) TEST_FAILURE_REASON="expected .zshrc in output, got: $result"; return 1 ;;
  esac
}

test_shell_rc_prefers_bashrc_over_zshrc() {
  # Create a temporary home directory with both files
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir"
  touch "$tmpdir/.bashrc"
  touch "$tmpdir/.zshrc"
  
  result=$(HOME="$tmpdir" "$ROOT_DIR/spells/.imps/sys/shell-rc" 2>&1) || {
    TEST_FAILURE_REASON="shell-rc failed: $result"
    return 1
  }
  # Should prefer .bashrc (first in the list)
  case "$result" in
    *".bashrc"*) return 0 ;;
    *) TEST_FAILURE_REASON="expected .bashrc in output, got: $result"; return 1 ;;
  esac
}

test_shell_rc_finds_profile() {
  # Create a temporary home directory with only .profile file
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir"
  touch "$tmpdir/.profile"
  
  result=$(HOME="$tmpdir" "$ROOT_DIR/spells/.imps/sys/shell-rc" 2>&1) || {
    TEST_FAILURE_REASON="shell-rc failed: $result"
    return 1
  }
  case "$result" in
    *".profile"*) return 0 ;;
    *) TEST_FAILURE_REASON="expected .profile in output, got: $result"; return 1 ;;
  esac
}

test_shell_rc_fails_without_rc_file() {
  # Create an empty temporary home directory
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir"
  
  if HOME="$tmpdir" "$ROOT_DIR/spells/.imps/sys/shell-rc" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="expected failure when no rc file exists"
    return 1
  fi
  return 0
}

test_shell_rc_fails_without_home() {
  # Unset HOME should fail
  if env -u HOME "$ROOT_DIR/spells/.imps/sys/shell-rc" >/dev/null 2>&1; then
    TEST_FAILURE_REASON="expected failure when HOME is unset"
    return 1
  fi
  return 0
}

run_test_case "shell-rc finds .bashrc" test_shell_rc_finds_bashrc
run_test_case "shell-rc finds .zshrc" test_shell_rc_finds_zshrc
run_test_case "shell-rc prefers .bashrc over .zshrc" test_shell_rc_prefers_bashrc_over_zshrc
run_test_case "shell-rc finds .profile" test_shell_rc_finds_profile
run_test_case "shell-rc fails without rc file" test_shell_rc_fails_without_rc_file
run_test_case "shell-rc fails without HOME" test_shell_rc_fails_without_home

finish_tests
