#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_file_info_exists() {
  [ -x "spells/.imps/cgi/file-info" ]
}

test_file_info_sanitizes_hostile_filename() {
  skip-if-compiled || return $?

  sites_dir=$(temp-dir file-info-sites)
  QUERY_STRING='name=%3Cimg%20src%3Dx%20onerror%3Dalert(1)%3E.txt' \
    WIZARDRY_SITE_NAME=testsite WIZARDRY_SITES_DIR="$sites_dir" \
    run_cmd spells/.imps/cgi/file-info
  assert_success || return 1

  if printf '%s' "$OUTPUT" | grep -F '<img src=x onerror=alert(1)>' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="file-info echoed raw image tag in HTML"
    rm -rf "$sites_dir"
    return 1
  fi
  if find "$sites_dir/.sitedata/testsite/uploads" -type f -name '*<*' -o -name '*>*' 2>/dev/null | grep . >/dev/null 2>&1; then
    TEST_FAILURE_REASON="file-info created a file with HTML delimiter characters"
    rm -rf "$sites_dir"
    return 1
  fi

  rm -rf "$sites_dir"
}

run_test_case "file-info is executable" test_file_info_exists
run_test_case "file-info sanitizes hostile filename" \
  test_file_info_sanitizes_hostile_filename
finish_tests
