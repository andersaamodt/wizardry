#!/bin/sh
# Ensure test-bootstrap exposes expected testing primitives

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_exports_find_repo_root() {
  root=$(_find_repo_root)
  [ -n "$root" ] && [ -d "$root/.tests" ] && [ -d "$root/spells" ]
}

test_exports_run_spell() {
  _run_spell spells/.imps/out/ok
  _assert_success
}

_run_test_case "test-bootstrap finds repository root" test_exports_find_repo_root
_run_test_case "test-bootstrap exports _run_spell helper" test_exports_run_spell

_finish_tests
