#!/bin/sh
# Tests for the 'on' and 'os' imps

. "${0%/*}/../test_common.sh"

test_os_outputs_something() {
  run_spell spells/.imps/os
  assert_success
  # Output should be one of the known identifiers
  case "$OUTPUT" in
    mac|linux|debian|nixos|arch|fedora|unknown) : ;;
    *) TEST_FAILURE_REASON="unexpected os output: $OUTPUT"; return 1 ;;
  esac
}

test_on_linux() {
  # This test runs on Linux CI, so 'on linux' should succeed
  run_spell spells/.imps/on linux
  # If we're on Linux, this should succeed
  kernel=$(uname -s 2>/dev/null || echo unknown)
  if [ "$kernel" = "Linux" ]; then
    assert_success
  else
    assert_failure
  fi
}

test_on_debian() {
  run_spell spells/.imps/on debian
  if [ -f /etc/debian_version ]; then
    assert_success
  else
    assert_failure
  fi
}

test_on_mac_fails_on_linux() {
  kernel=$(uname -s 2>/dev/null || echo unknown)
  if [ "$kernel" = "Linux" ]; then
    run_spell spells/.imps/on mac
    assert_failure
  fi
  return 0
}

test_on_unknown_platform_fails() {
  run_spell spells/.imps/on unknownplatform123
  assert_failure
}

run_test_case "os outputs valid identifier" test_os_outputs_something
run_test_case "on linux matches Linux kernel" test_on_linux
run_test_case "on debian matches debian systems" test_on_debian
run_test_case "on mac fails on Linux" test_on_mac_fails_on_linux
run_test_case "on unknown platform fails" test_on_unknown_platform_fails

finish_tests
