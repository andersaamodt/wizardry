#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_site_runtime_dir_keeps_non_git_sites_local() {
  tmpdir=$(make_tempdir)
  site_dir="$tmpdir/sites/demo"
  mkdir -p "$site_dir"

  runtime_dir=$(HOME="$tmpdir/home" sh "$test_root/spells/.imps/web/site-runtime-dir" "$site_dir" nginx)
  [ "$runtime_dir" = "$site_dir/nginx" ] || {
    TEST_FAILURE_REASON="non-git site runtime dir should stay inside the site checkout"
    rm -rf "$tmpdir"
    return 1
  }

  rm -rf "$tmpdir"
}

test_site_runtime_dir_moves_git_runtime_state_to_xdg() {
  tmpdir=$(make_tempdir)
  test_home="$tmpdir/home"
  site_dir="$test_home/git/demo"
  mkdir -p "$site_dir/nginx"
  printf '%s\n' legacy > "$site_dir/nginx/error.log"

  runtime_dir=$(HOME="$test_home" sh "$test_root/spells/.imps/web/site-runtime-dir" "$site_dir" nginx)
  status=$?
  [ "$status" -eq 0 ] || {
    TEST_FAILURE_REASON="site-runtime-dir should succeed for git workspace checkouts"
    rm -rf "$tmpdir"
    return 1
  }

  case "$runtime_dir" in
    "$test_home"/.local/state/wizardry/web-sites/*/.runtime/demo/nginx) ;;
    *)
      TEST_FAILURE_REASON="git workspace runtime dir should move under XDG state"
      rm -rf "$tmpdir"
      return 1
      ;;
  esac

  [ -f "$runtime_dir/error.log" ] || {
    TEST_FAILURE_REASON="legacy nginx runtime files should migrate into XDG state"
    rm -rf "$tmpdir"
    return 1
  }
  [ ! -e "$site_dir/nginx/error.log" ] || {
    TEST_FAILURE_REASON="repo-local nginx runtime files should be removed after migration"
    rm -rf "$tmpdir"
    return 1
  }

  rm -rf "$tmpdir"
}

run_test_case "site-runtime-dir keeps non-git sites local" test_site_runtime_dir_keeps_non_git_sites_local
run_test_case "site-runtime-dir redirects git site runtime state into XDG with migration" test_site_runtime_dir_moves_git_runtime_state_to_xdg
finish_tests
