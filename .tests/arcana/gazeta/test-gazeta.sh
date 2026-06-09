#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_gazeta_status_reports_not_installed() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  run_cmd env GAZETA_DIR="$tmp/missing" \
    "$ROOT_DIR/spells/.arcana/gazeta/gazeta-status"
  assert_success || return 1
  assert_output_contains "not installed"
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

test_install_gazeta_rejects_non_git_path() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  mkdir -p "$tmp/gazeta"

  run_cmd env GAZETA_DIR="$tmp/gazeta" \
    "$ROOT_DIR/spells/.arcana/gazeta/install-gazeta"
  assert_failure || return 1
  assert_error_contains "exists and is not a git repository"
}

run_test_case "gazeta-status reports not installed" \
  test_gazeta_status_reports_not_installed
run_test_case "is-gazeta-installed requires template source" \
  test_is_gazeta_installed_requires_template_source
run_test_case "install-gazeta rejects non-git path" \
  test_install_gazeta_rejects_non_git_path

finish_tests
