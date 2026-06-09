#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_install_gazeta_help() {
  run_spell "spells/.arcana/gazeta/install-gazeta" --help
  assert_success || return 1
  assert_output_contains "Usage: install-gazeta"
}

test_install_gazeta_rejects_non_git_path() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  mkdir -p "$tmp/gazeta"

  run_cmd env GAZETA_DIR="$tmp/gazeta" \
    "$ROOT_DIR/spells/.arcana/gazeta/install-gazeta"
  assert_failure || return 1
  assert_error_contains "exists and is not a git repository"
}

run_test_case "install-gazeta shows help" test_install_gazeta_help
run_test_case "install-gazeta rejects non-git path" \
  test_install_gazeta_rejects_non_git_path
finish_tests
