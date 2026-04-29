#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_upload_image_exists() {
  [ -x "spells/.imps/cgi/upload-image" ]
}

test_upload_image_sanitizes_hostile_filename() {
  skip-if-compiled || return $?

  upload_tmp=$(temp-dir upload-image-test)
  QUERY_STRING='filename=%3Cscript%3Ealert(1)%3C%2Fscript%3E.svg' \
    TMPDIR="$upload_tmp" run_cmd spells/.imps/cgi/upload-image
  assert_success || return 1

  if printf '%s' "$OUTPUT" | grep -F '<script>alert(1)</script>' >/dev/null 2>&1; then
    TEST_FAILURE_REASON="upload-image echoed raw script tag in HTML"
    rm -rf "$upload_tmp"
    return 1
  fi
  if find "$upload_tmp/wizardry-uploads" -type f -name '*<*' -o -name '*>*' 2>/dev/null | grep . >/dev/null 2>&1; then
    TEST_FAILURE_REASON="upload-image created a file with HTML delimiter characters"
    rm -rf "$upload_tmp"
    return 1
  fi

  rm -rf "$upload_tmp"
}

run_test_case "upload-image is executable" test_upload_image_exists
run_test_case "upload-image sanitizes hostile filename" \
  test_upload_image_sanitizes_hostile_filename
finish_tests
