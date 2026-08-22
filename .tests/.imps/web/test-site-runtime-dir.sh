#!/bin/sh
# Tests for site-runtime-dir imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_site_runtime_dir_keeps_site_local_component() {
  skip-if-compiled || return $?

  web_root=$(temp-dir web-wizardry-runtime)
  site_dir="$web_root/mysite"
  mkdir -p "$site_dir/nginx"
  printf '%s\n' 'config' > "$site_dir/nginx/nginx.conf"

  output=$("$test_root/spells/.imps/web/site-runtime-dir" "$site_dir" nginx)
  if [ "$output" != "$site_dir/nginx" ]; then
    TEST_FAILURE_REASON="unexpected runtime dir: $output"
    return 1
  fi
  if [ ! -f "$site_dir/nginx/nginx.conf" ]; then
    TEST_FAILURE_REASON="site-local runtime file was removed"
    return 1
  fi

  rm -rf "$web_root"
}

run_test_case "site-runtime-dir does not delete site-local component directories" \
  test_site_runtime_dir_keeps_site_local_component

finish_tests
