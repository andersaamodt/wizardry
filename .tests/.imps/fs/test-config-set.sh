#!/bin/sh
# Tests for the 'config-set' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_config_set_creates_file() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  config="$tmpdir/config"
  
  "$ROOT_DIR/spells/.imps/fs/config-set" "$config" "db-host" "localhost"
  
  [ -f "$config" ] || {
    TEST_FAILURE_REASON="config file was not created"
    return 1
  }
}

test_config_set_creates_parent_dirs() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  config="$tmpdir/subdir/deep/config"
  
  "$ROOT_DIR/spells/.imps/fs/config-set" "$config" "db-host" "localhost"
  
  [ -f "$config" ] || {
    TEST_FAILURE_REASON="config file was not created with parent directories"
    return 1
  }
}

test_config_set_adds_new_key() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  config="$tmpdir/config"
  
  "$ROOT_DIR/spells/.imps/fs/config-set" "$config" "db-host" "localhost"
  
  grep -q "^db-host=localhost$" "$config" || {
    TEST_FAILURE_REASON="key was not added to config"
    return 1
  }
}

test_config_set_preserves_other_keys() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  config="$tmpdir/config"
  printf 'key1=value1\nkey2=value2\n' > "$config"
  
  "$ROOT_DIR/spells/.imps/fs/config-set" "$config" "key2" "newvalue"
  
  grep -q "^key1=value1$" "$config" || {
    TEST_FAILURE_REASON="other keys were not preserved"
    return 1
  }
  
  grep -q "^key2=newvalue$" "$config" || {
    TEST_FAILURE_REASON="key was not updated"
    return 1
  }
}

test_config_set_handles_equals_in_value() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  config="$tmpdir/config"
  
  "$ROOT_DIR/spells/.imps/fs/config-set" "$config" "conn-string" "host=localhost;port=5432"
  
  grep -q "^conn-string=host=localhost;port=5432$" "$config" || {
    TEST_FAILURE_REASON="value with equals was not handled correctly"
    return 1
  }
}

test_config_set_rejects_newline_in_value() {
  tmpdir=$(_make_tempdir)
  config="$tmpdir/config"
  
  _run_spell spells/.imps/fs/config-set "$config" "key" "value
with newline"
  _assert_failure
  _assert_error_contains "cannot contain newlines"
}

test_config_set_rejects_invalid_key() {
  tmpdir=$(_make_tempdir)
  config="$tmpdir/config"
  
  _run_spell spells/.imps/fs/config-set "$config" "invalid key" "value"
  _assert_failure
  _assert_error_contains "invalid key format"
}

test_config_set_requires_file_arg() {
  _run_spell spells/.imps/fs/config-set
  _assert_failure
  _assert_error_contains "file path required"
}

test_config_set_requires_key_arg() {
  tmpdir=$(_make_tempdir)
  config="$tmpdir/config"
  
  _run_spell spells/.imps/fs/config-set "$config"
  _assert_failure
  _assert_error_contains "key required"
}

test_config_set_allows_empty_value() {
  tmpdir=$(_make_tempdir)
  config="$tmpdir/config"
  
  _run_spell spells/.imps/fs/config-set "$config" "key"
  _assert_success
  
  grep -q "^key=$" "$config" || {
    TEST_FAILURE_REASON="empty value was not set correctly"
    return 1
  }
}

_run_test_case "config-set creates file" test_config_set_creates_file
_run_test_case "config-set creates parent dirs" test_config_set_creates_parent_dirs
_run_test_case "config-set adds new key" test_config_set_adds_new_key
_run_test_case "config-set preserves other keys" test_config_set_preserves_other_keys
_run_test_case "config-set handles equals in value" test_config_set_handles_equals_in_value
_run_test_case "config-set rejects newline in value" test_config_set_rejects_newline_in_value
_run_test_case "config-set rejects invalid key" test_config_set_rejects_invalid_key
_run_test_case "config-set requires file arg" test_config_set_requires_file_arg
_run_test_case "config-set requires key arg" test_config_set_requires_key_arg
_run_test_case "config-set allows empty value" test_config_set_allows_empty_value

_finish_tests
