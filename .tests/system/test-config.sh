#!/bin/sh
# Comprehensive tests for config spell (wraps config-get, config-set, config-has, config-del imps)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# === config set tests ===

test_config_set_creates_file() {
  skip-if-compiled || return $?
  _run_cmd sh -c '
    tmpdir=$(mktemp -d) &&
    '"$ROOT_DIR"'/spells/system/config set "$tmpdir/config" "key1" "value1" &&
    [ -f "$tmpdir/config" ] &&
    grep -q "key1=value1" "$tmpdir/config" &&
    rm -rf "$tmpdir" &&
    printf "ok"
  '
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_config_set_updates_existing_key() {
  skip-if-compiled || return $?
  _run_cmd sh -c '
    tmpdir=$(mktemp -d) &&
    printf "key1=old\nkey2=keep\n" > "$tmpdir/config" &&
    '"$ROOT_DIR"'/spells/system/config set "$tmpdir/config" "key1" "new" &&
    grep -q "key1=new" "$tmpdir/config" &&
    grep -q "key2=keep" "$tmpdir/config" &&
    ! grep -q "key1=old" "$tmpdir/config" &&
    rm -rf "$tmpdir" &&
    printf "ok"
  '
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_config_set_handles_equals_in_value() {
  skip-if-compiled || return $?
  _run_cmd sh -c '
    tmpdir=$(mktemp -d) &&
    '"$ROOT_DIR"'/spells/system/config set "$tmpdir/config" "key1" "a=b=c" &&
    grep -q "key1=a=b=c" "$tmpdir/config" &&
    rm -rf "$tmpdir" &&
    printf "ok"
  '
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_config_set_rejects_invalid_key_chars() {
  skip-if-compiled || return $?
  _run_cmd "$ROOT_DIR/spells/.imps/fs/config-set" "/tmp/x" "key with spaces" "value"
  _assert_failure || return 1
  _assert_error_contains "invalid key format" || return 1
}

test_config_set_rejects_key_with_equals() {
  skip-if-compiled || return $?
  _run_cmd "$ROOT_DIR/spells/.imps/fs/config-set" "/tmp/x" "key=bad" "value"
  _assert_failure || return 1
  _assert_error_contains "key cannot contain =" || return 1
}

test_config_set_rejects_newline_in_value() {
  skip-if-compiled || return $?
  # Run directly, not through _run_cmd sandbox
  output=$(sh "$ROOT_DIR/spells/system/config" set "/tmp/x" "key1" "line1
line2" 2>&1)
  exit_code=$?
  
  if [ "$exit_code" -eq 0 ]; then
    TEST_FAILURE_REASON="Expected failure but got success"
    return 1
  fi
  
  case "$output" in
    *"cannot contain newlines"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="Error message missing 'cannot contain newlines': $output"
      return 1
      ;;
  esac
}

# === config-get tests ===

test_config_get_retrieves_value() {
  skip-if-compiled || return $?
  _run_cmd sh -c '
    tmpdir=$(mktemp -d) &&
    printf "key1=value1\nkey2=value2\n" > "$tmpdir/config" &&
    '"$ROOT_DIR"'/spells/.imps/fs/config-get "$tmpdir/config" "key1" &&
    rm -rf "$tmpdir"
  '
  _assert_success || return 1
  _assert_output_contains "value1" || return 1
}

test_config_get_handles_equals_in_value() {
  skip-if-compiled || return $?
  _run_cmd sh -c '
    tmpdir=$(mktemp -d) &&
    printf "key1=a=b=c\n" > "$tmpdir/config" &&
    '"$ROOT_DIR"'/spells/.imps/fs/config-get "$tmpdir/config" "key1" &&
    rm -rf "$tmpdir"
  '
  _assert_success || return 1
  _assert_output_contains "a=b=c" || return 1
}

test_config_get_returns_empty_for_missing_file() {
  skip-if-compiled || return $?
  _run_cmd "$ROOT_DIR/spells/.imps/fs/config-get" "/tmp/nonexistent-$$.config" "key1"
  _assert_success || return 1
  [ -z "$OUTPUT" ] || return 1
}

test_config_get_rejects_invalid_key() {
  skip-if-compiled || return $?
  _run_cmd "$ROOT_DIR/spells/.imps/fs/config-get" "/tmp/x" "bad key"
  _assert_failure || return 1
  _assert_error_contains "invalid key format" || return 1
}

# === config-has tests ===

test_config_has_returns_true_when_exists() {
  skip-if-compiled || return $?
  _run_cmd sh -c '
    tmpdir=$(mktemp -d) &&
    printf "key1=value1\n" > "$tmpdir/config" &&
    '"$ROOT_DIR"'/spells/.imps/fs/config-has "$tmpdir/config" "key1" &&
    rm -rf "$tmpdir" &&
    printf "ok"
  '
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_config_has_returns_false_when_missing() {
  skip-if-compiled || return $?
  _run_cmd sh -c '
    tmpdir=$(mktemp -d) &&
    printf "key1=value1\n" > "$tmpdir/config" &&
    '"$ROOT_DIR"'/spells/.imps/fs/config-has "$tmpdir/config" "key2"
    result=$?
    rm -rf "$tmpdir"
    exit $result
  '
  _assert_failure || return 1
}

test_config_has_returns_false_for_missing_file() {
  skip-if-compiled || return $?
  _run_cmd "$ROOT_DIR/spells/.imps/fs/config-has" "/tmp/nonexistent-$$.config" "key1"
  _assert_failure || return 1
}

# === config-del tests ===

test_config_del_removes_key() {
  skip-if-compiled || return $?
  _run_cmd sh -c '
    tmpdir=$(mktemp -d) &&
    printf "key1=value1\nkey2=value2\n" > "$tmpdir/config" &&
    '"$ROOT_DIR"'/spells/system/config del "$tmpdir/config" "key1" &&
    grep -q "key2=value2" "$tmpdir/config" &&
    ! grep -q "key1" "$tmpdir/config" &&
    rm -rf "$tmpdir" &&
    printf "ok"
  '
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_config_del_handles_missing_file() {
  skip-if-compiled || return $?
  _run_cmd "$ROOT_DIR/spells/.imps/fs/config-del" "/tmp/nonexistent-$$.config" "key1"
  _assert_success || return 1
}

# === Edge case tests ===

test_config_roundtrip_special_chars() {
  skip-if-compiled || return $?
  _run_cmd sh -c '
    tmpdir=$(mktemp -d) &&
    val="!@#\$%^&*()[]{}|;:,./<>?\\\\" &&
    '"$ROOT_DIR"'/spells/.imps/fs/config-set "$tmpdir/config" "key1" "$val" &&
    result=$('"$ROOT_DIR"'/spells/.imps/fs/config-get "$tmpdir/config" "key1") &&
    [ "$result" = "$val" ] &&
    rm -rf "$tmpdir" &&
    printf "ok"
  '
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

test_config_many_keys() {
  skip-if-compiled || return $?
  _run_cmd sh -c '
    tmpdir=$(mktemp -d) &&
    i=1 &&
    while [ "$i" -le 20 ]; do
      '"$ROOT_DIR"'/spells/.imps/fs/config-set "$tmpdir/config" "key$i" "value$i" || exit 1
      i=$((i + 1))
    done &&
    i=1 &&
    while [ "$i" -le 20 ]; do
      v=$('"$ROOT_DIR"'/spells/.imps/fs/config-get "$tmpdir/config" "key$i") || exit 1
      [ "$v" = "value$i" ] || exit 1
      i=$((i + 1))
    done &&
    rm -rf "$tmpdir" &&
    printf "ok"
  '
  _assert_success || return 1
  _assert_output_contains "ok" || return 1
}

# Run all tests
_run_test_case "config-set creates file" test_config_set_creates_file
_run_test_case "config-set updates existing key" test_config_set_updates_existing_key
_run_test_case "config-set handles equals in value" test_config_set_handles_equals_in_value
_run_test_case "config-set rejects invalid key chars" test_config_set_rejects_invalid_key_chars
_run_test_case "config-set rejects key with equals" test_config_set_rejects_key_with_equals
_run_test_case "config-set rejects newline in value" test_config_set_rejects_newline_in_value

_run_test_case "config-get retrieves value" test_config_get_retrieves_value
_run_test_case "config-get handles equals in value" test_config_get_handles_equals_in_value
_run_test_case "config-get returns empty for missing file" test_config_get_returns_empty_for_missing_file
_run_test_case "config-get rejects invalid key" test_config_get_rejects_invalid_key

_run_test_case "config-has returns true when exists" test_config_has_returns_true_when_exists
_run_test_case "config-has returns false when missing" test_config_has_returns_false_when_missing
_run_test_case "config-has returns false for missing file" test_config_has_returns_false_for_missing_file

_run_test_case "config-del removes key" test_config_del_removes_key
_run_test_case "config-del handles missing file" test_config_del_handles_missing_file

_run_test_case "config roundtrip with special chars" test_config_roundtrip_special_chars
_run_test_case "config handles many keys (20)" test_config_many_keys


# Test via source-then-invoke pattern  
