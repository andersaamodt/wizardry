#!/bin/sh
# Behavioral coverage for webcam arcana menu.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/webcam/webcam-menu"

test_webcam_menu_exists() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="missing executable spell: $target"
    return 1
  }
}

test_webcam_menu_help() {
  run_spell "$target" --help
  assert_success && assert_output_contains "Usage:"
}

run_test_case "webcam-menu exists" test_webcam_menu_exists
run_test_case "webcam-menu help" test_webcam_menu_help

finish_tests
