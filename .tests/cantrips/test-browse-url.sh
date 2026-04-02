#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/cantrips/browse-url --help
  assert_success || return 1
  assert_output_contains "Usage: browse-url URL" || return 1
}

test_rejects_missing_url() {
  run_spell spells/cantrips/browse-url
  assert_failure || return 1
  assert_error_contains "requires exactly one URL argument" || return 1
}

test_rejects_non_http_url() {
  run_spell spells/cantrips/browse-url ftp://example.com
  assert_failure || return 1
  assert_error_contains "must start with http:// or https://" || return 1
}

test_opens_url_on_macos() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)

  cat >"$tmp/open" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >"$BROWSE_URL_LOG"
SH
  chmod +x "$tmp/open"

  cat >"$tmp/uname" <<'SH'
#!/bin/sh
printf '%s\n' "Darwin"
SH
  chmod +x "$tmp/uname"

  BROWSE_URL_LOG="$tmp/log" run_cmd env PATH="$tmp:$PATH" \
    "$ROOT_DIR/spells/cantrips/browse-url" "http://localhost:8080"
  assert_success || return 1
  assert_path_exists "$tmp/log" || return 1
  grep -q "http://localhost:8080" "$tmp/log" || {
    TEST_FAILURE_REASON="open did not receive expected URL"
    return 1
  }
}

run_test_case "browse-url shows help" test_help
run_test_case "browse-url requires a URL" test_rejects_missing_url
run_test_case "browse-url rejects non-http URLs" test_rejects_non_http_url
run_test_case "browse-url opens URLs on macOS" test_opens_url_on_macos

finish_tests
