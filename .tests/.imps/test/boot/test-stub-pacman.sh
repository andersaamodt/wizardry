#!/bin/sh
# Test stub-pacman imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  fixture=$(_make_fixture)
  _stub_pacman "$fixture"
  [ -x "$fixture/bin/pacman" ]
}

test_stub_logs_invocations() {
  fixture=$(_make_fixture)
  _stub_pacman "$fixture"
  export PACMAN_LOG="$fixture/log/pacman.log"
  "$fixture/bin/pacman" --noconfirm -Sy git
  [ -f "$PACMAN_LOG" ] && grep -q "pacman --noconfirm -Sy git" "$PACMAN_LOG"
}

_run_test_case "stub-pacman creates executable" test_creates_stub
_run_test_case "stub-pacman logs invocations" test_stub_logs_invocations

_finish_tests
