#!/bin/sh
# Tests for the 'config-del' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_config_del_removes_key() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
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
  tmpdir=$(_make_tempdir)
  config="$tmpdir/config"
  printf 'db-host=localhost\n' > "$config"
  
  _run_spell spells/.imps/fs/config-del "$config" "missing-key"
  _assert_success
}

test_config_del_missing_file_succeeds() {
  _run_spell spells/.imps/fs/config-del "/nonexistent/config" "db-host"
  _assert_success
}

test_config_del_rejects_invalid_key() {
  tmpdir=$(_make_tempdir)
  config="$tmpdir/config"
  touch "$config"
  
  _run_spell spells/.imps/fs/config-del "$config" "invalid key"
  _assert_failure
  _assert_error_contains "invalid key format"
}

test_config_del_requires_file_arg() {
  _run_spell spells/.imps/fs/config-del
  _assert_failure
  _assert_error_contains "file path required"
}

test_config_del_requires_key_arg() {
  tmpdir=$(_make_tempdir)
  config="$tmpdir/config"
  touch "$config"
  
  _run_spell spells/.imps/fs/config-del "$config"
  _assert_failure
  _assert_error_contains "key required"
}

_run_test_case "config-del removes key" test_config_del_removes_key
_run_test_case "config-del missing key succeeds" test_config_del_missing_key_succeeds
_run_test_case "config-del missing file succeeds" test_config_del_missing_file_succeeds
_run_test_case "config-del rejects invalid key" test_config_del_rejects_invalid_key
_run_test_case "config-del requires file arg" test_config_del_requires_file_arg
_run_test_case "config-del requires key arg" test_config_del_requires_key_arg

_finish_tests
