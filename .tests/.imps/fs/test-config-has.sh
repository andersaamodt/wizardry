#!/bin/sh
# Tests for the 'config-has' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_config_has_finds_existing_key() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  printf 'db-host=localhost\n' > "$config"
  
  run_spell spells/.imps/fs/config-has "$config" "db-host"
  assert_success
}

test_config_has_missing_key_fails() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  printf 'db-host=localhost\n' > "$config"
  
  run_spell spells/.imps/fs/config-has "$config" "missing-key"
  assert_failure
}

test_config_has_missing_file_fails() {
  run_spell spells/.imps/fs/config-has "/nonexistent/config" "db-host"
  assert_failure
}

test_config_has_rejects_invalid_key() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  touch "$config"
  
  run_spell spells/.imps/fs/config-has "$config" "invalid key"
  assert_failure
  assert_error_contains "invalid key format"
}

test_config_has_requires_file_arg() {
  run_spell spells/.imps/fs/config-has
  assert_failure
  assert_error_contains "file path required"
}

test_config_has_requires_key_arg() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  touch "$config"
  
  run_spell spells/.imps/fs/config-has "$config"
  assert_failure
  assert_error_contains "key required"
}

run_test_case "config-has finds existing key" test_config_has_finds_existing_key
run_test_case "config-has missing key fails" test_config_has_missing_key_fails
run_test_case "config-has missing file fails" test_config_has_missing_file_fails
run_test_case "config-has rejects invalid key" test_config_has_rejects_invalid_key
run_test_case "config-has requires file arg" test_config_has_requires_file_arg
run_test_case "config-has requires key arg" test_config_has_requires_key_arg

finish_tests
