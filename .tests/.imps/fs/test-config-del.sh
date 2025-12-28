#!/bin/sh
# Tests for the 'config-del' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_config_del_removes_key() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  printf 'db-host=localhost\ndb-port=5432\n' > "$config"
  
  "$ROOT_DIR/spells/.imps/fs/config-del" "$config" "db-host"
  
  grep -q "db-host" "$config" && {
    TEST_FAILURE_REASON="key was not deleted"
    return 1
  }
  
  # Should preserve other keys
  grep -q "db-port=5432" "$config" || {
    TEST_FAILURE_REASON="other keys were not preserved"
    return 1
  }
}

test_config_del_missing_key_succeeds() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  printf 'db-host=localhost\n' > "$config"
  
  run_spell spells/.imps/fs/config-del "$config" "missing-key"
  assert_success
}

test_config_del_missing_file_succeeds() {
  run_spell spells/.imps/fs/config-del "/nonexistent/config" "db-host"
  assert_success
}

test_config_del_rejects_invalid_key() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  touch "$config"
  
  run_spell spells/.imps/fs/config-del "$config" "invalid key"
  assert_failure
  assert_error_contains "invalid key format"
}

test_config_del_requires_file_arg() {
  run_spell spells/.imps/fs/config-del
  assert_failure
  assert_error_contains "file path required"
}

test_config_del_requires_key_arg() {
  tmpdir=$(make_tempdir)
  config="$tmpdir/config"
  touch "$config"
  
  run_spell spells/.imps/fs/config-del "$config"
  assert_failure
  assert_error_contains "key required"
}

run_test_case "config-del removes key" test_config_del_removes_key
run_test_case "config-del missing key succeeds" test_config_del_missing_key_succeeds
run_test_case "config-del missing file succeeds" test_config_del_missing_file_succeeds
run_test_case "config-del rejects invalid key" test_config_del_rejects_invalid_key
run_test_case "config-del requires file arg" test_config_del_requires_file_arg
run_test_case "config-del requires key arg" test_config_del_requires_key_arg

finish_tests
