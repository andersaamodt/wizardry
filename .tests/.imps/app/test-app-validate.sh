#!/bin/sh
# Test app-validate imp

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_validate_requires_path() {
  run_spell "spells/.imps/app/app-validate"
  assert_failure || return 1
  assert_error_contains "requires app path" || return 1
}

test_validate_rejects_missing_dir() {
  run_spell "spells/.imps/app/app-validate" "/nonexistent/path"
  assert_failure || return 1
  assert_error_contains "not found" || return 1
}

test_validate_rejects_missing_index() {
  workdir=$(make_tempdir)
  mkdir -p "$workdir/testapp"
  
  run_spell "spells/.imps/app/app-validate" "$workdir/testapp"
  assert_failure || return 1
  assert_error_contains "index.html not found" || return 1
}

test_validate_accepts_valid_app() {
  workdir=$(make_tempdir)
  mkdir -p "$workdir/testapp"
  printf '<html></html>\n' > "$workdir/testapp/index.html"
  
  run_spell "spells/.imps/app/app-validate" "$workdir/testapp"
  assert_success || return 1
}

run_test_case "app-validate requires path" test_validate_requires_path
run_test_case "app-validate rejects missing directory" test_validate_rejects_missing_dir
run_test_case "app-validate rejects missing index.html" test_validate_rejects_missing_index
run_test_case "app-validate accepts valid app" test_validate_accepts_valid_app

finish_tests
