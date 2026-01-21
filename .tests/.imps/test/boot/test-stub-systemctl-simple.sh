#!/bin/sh
# Test stub-systemctl-simple imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_systemctl_simple "$tmpdir"
  [ -x "$tmpdir/systemctl" ]
}

test_stub_handles_daemon_reload() {
  tmpdir=$(make_tempdir)
  stub_systemctl_simple "$tmpdir"
  export SYSTEMCTL_STATE_DIR="$tmpdir/state"
  "$tmpdir/systemctl" daemon-reload
  [ -f "$tmpdir/state/daemon-reload" ]
  grep -q "reloaded" "$tmpdir/state/daemon-reload"
}

run_test_case "stub-systemctl-simple creates executable" test_creates_stub
run_test_case "stub-systemctl-simple handles daemon-reload" test_stub_handles_daemon_reload

finish_tests
