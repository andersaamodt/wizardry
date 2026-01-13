#!/bin/sh
# Tests for the 'config-get' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_config_get_returns_value() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  printf 'db-host=localhost\n' > "$config"
  
  run_spell spells/.imps/fs/config-get "$config" "db-host"
  assert_success
  assert_output_contains "localhost"
}

test_config_get_missing_file_returns_empty() {
  run_spell spells/.imps/fs/config-get "/nonexistent/config" "db-host"
  assert_success
  [ -z "$OUTPUT" ] || {
    TEST_FAILURE_REASON="expected empty output for missing file, got: $OUTPUT"
    return 1
  }
}

test_config_get_missing_key_returns_empty() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  printf 'db-host=localhost\n' > "$config"
  
  run_spell spells/.imps/fs/config-get "$config" "missing-key"
  [ -z "$OUTPUT" ] || {
    TEST_FAILURE_REASON="expected empty output for missing key, got: $OUTPUT"
    return 1
  }
}

test_config_get_handles_equals_in_value() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  printf 'conn-string=host=localhost;port=5432\n' > "$config"
  
  run_spell spells/.imps/fs/config-get "$config" "conn-string"
  assert_success
  assert_output_contains "host=localhost;port=5432"
}

test_config_get_requires_file_arg() {
  run_spell spells/.imps/fs/config-get
  assert_failure
  assert_error_contains "file path required"
}

test_config_get_requires_key_arg() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  touch "$config"
  
  run_spell spells/.imps/fs/config-get "$config"
  assert_failure
  assert_error_contains "key required"
}

test_config_get_rejects_invalid_key() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  touch "$config"
  
  run_spell spells/.imps/fs/config-get "$config" "invalid key"
  assert_failure
  assert_error_contains "invalid key format"
}

run_test_case "config-get returns value" test_config_get_returns_value
run_test_case "config-get missing file returns empty" test_config_get_missing_file_returns_empty
run_test_case "config-get missing key returns empty" test_config_get_missing_key_returns_empty
run_test_case "config-get handles equals in value" test_config_get_handles_equals_in_value
run_test_case "config-get requires file arg" test_config_get_requires_file_arg
run_test_case "config-get requires key arg" test_config_get_requires_key_arg
run_test_case "config-get rejects invalid key" test_config_get_rejects_invalid_key

finish_tests
