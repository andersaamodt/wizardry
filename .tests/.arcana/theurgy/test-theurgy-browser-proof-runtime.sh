#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

browser_proof_spells_show_help() {
  for spell in check-theurgy-browser-proof-runtime install-theurgy-browser-proof-runtime theurgy-browser-proof-runtime-status; do
    run_spell "spells/.arcana/theurgy/$spell" --help
    assert_success || return 1
  done
}

browser_proof_check_reports_missing_installer() {
  home=$(make_tempdir)
  run_cmd env THEURGY_HOME="$home/theurgy" "$ROOT_DIR/spells/.arcana/theurgy/check-theurgy-browser-proof-runtime"
  assert_success || return 1
  assert-output-contains 'status=bad'
}

browser_proof_check_reports_available_installer() {
  home=$(make_tempdir)
  mkdir -p "$home/theurgy/spells"
  : > "$home/theurgy/spells/install-theurgy-browser-proof-runtime"
  chmod +x "$home/theurgy/spells/install-theurgy-browser-proof-runtime"
  run_cmd env THEURGY_HOME="$home/theurgy" "$ROOT_DIR/spells/.arcana/theurgy/check-theurgy-browser-proof-runtime"
  assert_success || return 1
  assert-output-contains 'status=ok'
}

browser_proof_status_is_human_readable() {
  home=$(make_tempdir)
  run_cmd env THEURGY_HOME="$home/theurgy" "$ROOT_DIR/spells/.arcana/theurgy/theurgy-browser-proof-runtime-status"
  assert_success || return 1
  assert-output-contains 'not installed'
}

run_test_case "Theurgy browser proof spells show help" browser_proof_spells_show_help
run_test_case "browser proof check reports a missing installer" browser_proof_check_reports_missing_installer
run_test_case "browser proof check reports an available installer" browser_proof_check_reports_available_installer
run_test_case "browser proof status is human readable" browser_proof_status_is_human_readable
finish_tests
