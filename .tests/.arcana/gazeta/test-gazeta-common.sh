#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_gazeta_common_help() {
  run_spell "spells/.arcana/gazeta/gazeta-common" --help
  assert_success || return 1
  assert_output_contains "Usage: gazeta-common"
}

test_gazeta_common_detects_template_source() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  mkdir -p "$tmp/gazeta/.git"

  run_cmd env GAZETA_DIR="$tmp/gazeta" /bin/sh -c '
    . "$ROOT_DIR/spells/.arcana/gazeta/gazeta-common"
    gazeta_installed
  '
  assert_failure || return 1

  mkdir -p "$tmp/gazeta/pages"
  run_cmd env GAZETA_DIR="$tmp/gazeta" /bin/sh -c '
    . "$ROOT_DIR/spells/.arcana/gazeta/gazeta-common"
    gazeta_installed
  '
  assert_success
}

run_test_case "gazeta-common shows help" test_gazeta_common_help
run_test_case "gazeta-common detects template source" \
  test_gazeta_common_detects_template_source
finish_tests
