#!/bin/sh
# Tests for the 'mud-defaults' imp

# Locate the repository root so we can source test-bootstrap
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_mud_defaults_exists() {
  mud_defaults_path="$test_root/spells/.imps/mud/mud-defaults"
  [ -f "$mud_defaults_path" ] && [ -x "$mud_defaults_path" ]
}

test_mud_defaults_parse_enabled_returns_1() {
  run_spell spells/.imps/mud/mud-defaults parse-enabled
  assert_success
  [ "$OUTPUT" = "1" ] || { TEST_FAILURE_REASON="expected 1 but got $OUTPUT"; return 1; }
}

test_mud_defaults_mud_enabled_returns_1() {
  run_spell spells/.imps/mud/mud-defaults mud-enabled
  assert_success
  [ "$OUTPUT" = "1" ] || { TEST_FAILURE_REASON="expected 1 but got $OUTPUT"; return 1; }
}

test_mud_defaults_cd_look_returns_1() {
  run_spell spells/.imps/mud/mud-defaults cd-look
  assert_success
  [ "$OUTPUT" = "1" ] || { TEST_FAILURE_REASON="expected 1 but got $OUTPUT"; return 1; }
}

test_mud_defaults_avatar_returns_0() {
  run_spell spells/.imps/mud/mud-defaults avatar
  assert_success
  [ "$OUTPUT" = "0" ] || { TEST_FAILURE_REASON="expected 0 but got $OUTPUT"; return 1; }
}

test_mud_defaults_touch_hook_returns_0() {
  run_spell spells/.imps/mud/mud-defaults touch-hook
  assert_success
  [ "$OUTPUT" = "0" ] || { TEST_FAILURE_REASON="expected 0 but got $OUTPUT"; return 1; }
}

test_mud_defaults_unknown_feature_returns_0() {
  # Unknown features should default to disabled (0) for safety
  run_spell spells/.imps/mud/mud-defaults unknown-feature
  assert_success
  [ "$OUTPUT" = "0" ] || { TEST_FAILURE_REASON="expected 0 for unknown feature but got $OUTPUT"; return 1; }
}

test_mud_defaults_no_argument_fails() {
  # Should fail if no argument provided
  run_spell spells/.imps/mud/mud-defaults
  assert_failure
}

test_mud_defaults_empty_argument_fails() {
  # Should fail if empty argument provided
  run_spell spells/.imps/mud/mud-defaults ""
  assert_failure
}

test_mud_defaults_returns_only_0_or_1() {
  # Test that all known features return only 0 or 1 (no other values)
  for feature in parse-enabled mud-enabled cd-look avatar touch-hook; do
    run_spell spells/.imps/mud/mud-defaults "$feature"
    assert_success
    case "$OUTPUT" in
      0|1) : ;;
      *) TEST_FAILURE_REASON="$feature returned invalid value: $OUTPUT"; return 1 ;;
    esac
  done
}

test_mud_defaults_consistent_with_balance() {
  # Verify the balanced defaults match our design:
  # Enabled: parse-enabled, mud-enabled, cd-look
  # Disabled: avatar, touch-hook
  
  # Check enabled features
  for feature in parse-enabled mud-enabled cd-look; do
    run_spell spells/.imps/mud/mud-defaults "$feature"
    assert_success
    [ "$OUTPUT" = "1" ] || { 
      TEST_FAILURE_REASON="$feature should be enabled by default but got $OUTPUT"
      return 1
    }
  done
  
  # Check disabled features
  for feature in avatar touch-hook; do
    run_spell spells/.imps/mud/mud-defaults "$feature"
    assert_success
    [ "$OUTPUT" = "0" ] || { 
      TEST_FAILURE_REASON="$feature should be disabled by default but got $OUTPUT"
      return 1
    }
  done
}

run_test_case "mud-defaults imp exists and is executable" test_mud_defaults_exists
run_test_case "mud-defaults parse-enabled returns 1" test_mud_defaults_parse_enabled_returns_1
run_test_case "mud-defaults mud-enabled returns 1" test_mud_defaults_mud_enabled_returns_1
run_test_case "mud-defaults cd-look returns 1" test_mud_defaults_cd_look_returns_1
run_test_case "mud-defaults avatar returns 0" test_mud_defaults_avatar_returns_0
run_test_case "mud-defaults touch-hook returns 0" test_mud_defaults_touch_hook_returns_0
run_test_case "mud-defaults unknown feature returns 0" test_mud_defaults_unknown_feature_returns_0
run_test_case "mud-defaults no argument fails" test_mud_defaults_no_argument_fails
run_test_case "mud-defaults empty argument fails" test_mud_defaults_empty_argument_fails
run_test_case "mud-defaults returns only 0 or 1" test_mud_defaults_returns_only_0_or_1
run_test_case "mud-defaults consistent with balanced design" test_mud_defaults_consistent_with_balance

finish_tests
