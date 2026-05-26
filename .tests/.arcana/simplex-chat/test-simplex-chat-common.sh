#!/bin/sh
# Behavioral coverage for simplex-chat-common.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/simplex-chat/simplex-chat-common"

test_simplex_chat_common_exists() {
  [ -f "$ROOT_DIR/$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_simplex_chat_common_executable() {
  [ -x "$ROOT_DIR/$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_simplex_chat_common_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

test_simplex_chat_common_supports_asset_name_override() {
  run_cmd env ROOT_DIR="$ROOT_DIR" WIZARDRY_SIMPLEX_ASSET_NAME="custom-simplex-asset" /bin/sh -c '
    . "$ROOT_DIR/spells/.arcana/simplex-chat/simplex-chat-common"
    simplex_chat_asset_name
  '
  assert_success || return 1
  assert_output_contains "custom-simplex-asset" || return 1
}

test_simplex_chat_common_rejects_multiline_config_values() {
  tmpdir=$(make_tempdir)
  config_file="$tmpdir/install.conf"
  run_cmd env ROOT_DIR="$ROOT_DIR" CONFIG_FILE="$config_file" /bin/sh -c '
    . "$ROOT_DIR/spells/.arcana/simplex-chat/simplex-chat-common"
    simplex_chat_config_set "$CONFIG_FILE" version "$(printf "line1\nline2")"
  '
  assert_status 2 || return 1
  assert_error_contains "must be one line" || return 1
}

run_test_case "simplex-chat-common exists" test_simplex_chat_common_exists
run_test_case "simplex-chat-common is executable" test_simplex_chat_common_executable
run_test_case "simplex-chat-common --help is callable" test_simplex_chat_common_help_callable
run_test_case "simplex-chat-common supports asset name override" \
  test_simplex_chat_common_supports_asset_name_override
run_test_case "simplex-chat-common rejects multiline config values" \
  test_simplex_chat_common_rejects_multiline_config_values

finish_tests
