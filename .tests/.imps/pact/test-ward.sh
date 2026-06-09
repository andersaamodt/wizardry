#!/bin/sh
# Behavioral cases for ward:
# - validates labels
# - rejects forged status rows
# - enforces path containment
# - allowlists release URLs

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

ward_validates_labels() {
  run_spell "spells/.imps/pact/ward" safe-label good-name_1.2
  assert_success || return 1
  run_spell "spells/.imps/pact/ward" safe-label ../escape
  assert_failure || return 1
}

ward_rejects_status_row_forgery() {
  forged='ok
status=bad'
  run_spell "spells/.imps/pact/ward" status-row-safe "$forged"
  assert_failure || return 1
}

ward_enforces_path_containment() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/root/sub" "$tmpdir/other"
  run_spell "spells/.imps/pact/ward" path-contained "$tmpdir/root/sub/file" "$tmpdir/root"
  assert_success || return 1
  run_spell "spells/.imps/pact/ward" path-contained "$tmpdir/other/file" "$tmpdir/root"
  assert_failure || return 1
}

ward_allowlists_release_urls() {
  run_spell "spells/.imps/pact/ward" release-url-allowlisted \
    https://github.com/example/project/releases/download/v1/tool \
    https://github.com/example/project/releases/download/
  assert_success || return 1
  run_spell "spells/.imps/pact/ward" release-url-allowlisted \
    https://evil.example/tool \
    https://github.com/example/project/releases/download/
  assert_failure || return 1
}

run_test_case "ward validates labels" ward_validates_labels
run_test_case "ward rejects status row forgery" ward_rejects_status_row_forgery
run_test_case "ward enforces path containment" ward_enforces_path_containment
run_test_case "ward allowlists release URLs" ward_allowlists_release_urls

finish_tests
