#!/bin/sh
# Test find-repo-root imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_finds_root() {
  root=$(_find_repo_root)
  [ -n "$root" ] && [ -d "$root/spells" ] && [ -d "$root/.tests" ]
}

test_root_has_spells() {
  root=$(_find_repo_root)
  [ -d "$root/spells/.imps" ]
}

_run_test_case "find-repo-root locates repository root" test_finds_root
_run_test_case "find-repo-root returns path with spells directory" test_root_has_spells

_finish_tests
