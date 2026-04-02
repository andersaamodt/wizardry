#!/bin/sh
# Behavioral coverage for install-nostril-arcana spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/nostr/install-nostril-arcana"

test_install_nostril_arcana_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_install_nostril_arcana_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_install_nostril_arcana_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "install-nostril-arcana spell exists" test_install_nostril_arcana_exists
run_test_case "install-nostril-arcana spell is executable" test_install_nostril_arcana_executable
run_test_case "install-nostril-arcana spell --help is callable" test_install_nostril_arcana_help_callable

finish_tests
