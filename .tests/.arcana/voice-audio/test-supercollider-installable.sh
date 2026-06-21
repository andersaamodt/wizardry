#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_supercollider_spells_show_help() {
  for spell in install-supercollider uninstall-supercollider is-supercollider-installed; do
    run_cmd "$ROOT_DIR/spells/.arcana/voice-audio/$spell" --help
    assert_success || return 1
  done
}

test_supercollider_installers_do_not_call_homebrew() {
  if grep -q 'brew ' "$ROOT_DIR/spells/.arcana/voice-audio/install-supercollider" "$ROOT_DIR/spells/.arcana/voice-audio/uninstall-supercollider"; then
    TEST_FAILURE_REASON="SuperCollider installers should not call Homebrew"
    return 1
  fi
}

run_test_case "SuperCollider spells show help" test_supercollider_spells_show_help
run_test_case "SuperCollider installers do not call Homebrew" test_supercollider_installers_do_not_call_homebrew

finish_tests
