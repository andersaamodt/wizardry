#!/bin/sh
# Test delete-site spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_delete_site_help() {
  run_spell spells/web/delete-site --help
  assert_success
  assert_output_contains "Usage:"
}

test_delete_site_rejects_path_shaped_site_name() {
  skip-if-compiled || return $?

  tmpdir=$(make_tempdir)
  sites_dir="$tmpdir/sites"
  escape_dir="$tmpdir/escape"
  mkdir -p "$sites_dir" "$escape_dir"
  printf '%s\n' keep > "$escape_dir/keep"

  WIZARDRY_SITES_DIR="$sites_dir" run_cmd sh -c \
    "printf 'y\n' | '$ROOT_DIR/spells/web/delete-site' ../escape"

  assert_failure || return 1
  assert_error_contains "invalid site name" || return 1
  if [ ! -f "$escape_dir/keep" ]; then
    TEST_FAILURE_REASON="delete-site removed a directory outside WIZARDRY_SITES_DIR"
    return 1
  fi
}

run_test_case "delete-site --help" test_delete_site_help
run_test_case "delete-site rejects path-shaped site names" test_delete_site_rejects_path_shaped_site_name

finish_tests
