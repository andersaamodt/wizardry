#!/bin/sh
# Behavioral coverage for uninstall-btcpay spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/uninstall-btcpay"

test_uninstall_btcpay_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_uninstall_btcpay_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_uninstall_btcpay_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "uninstall-btcpay spell exists" test_uninstall_btcpay_exists
run_test_case "uninstall-btcpay spell is executable" test_uninstall_btcpay_executable
run_test_case "uninstall-btcpay spell --help is callable" test_uninstall_btcpay_help_callable

finish_tests
