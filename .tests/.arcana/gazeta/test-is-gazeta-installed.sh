#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_is_gazeta_installed_help() {
  run_spell "spells/.arcana/gazeta/is-gazeta-installed" --help
  assert_success || return 1
  assert_output_contains "Usage: is-gazeta-installed"
}

test_is_gazeta_installed_requires_template_source() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  mkdir -p "$tmp/gazeta/.git"

  run_cmd env GAZETA_DIR="$tmp/gazeta" \
    "$ROOT_DIR/spells/.arcana/gazeta/is-gazeta-installed"
  assert_failure || return 1

  mkdir -p "$tmp/gazeta/pages"
  run_cmd env GAZETA_DIR="$tmp/gazeta" \
    "$ROOT_DIR/spells/.arcana/gazeta/is-gazeta-installed"
  assert_success
}

run_test_case "is-gazeta-installed shows help" test_is_gazeta_installed_help
run_test_case "is-gazeta-installed requires template source" \
  test_is_gazeta_installed_requires_template_source
finish_tests
