#!/bin/sh
# Test stub-launchctl imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_stub() {
  tmpdir=$(make_tempdir)
  stub_launchctl "$tmpdir"
  [ -x "$tmpdir/launchctl" ]
}

test_stub_tracks_load_and_unload() {
  tmpdir=$(make_tempdir)
  stub_launchctl "$tmpdir"
  export LAUNCHCTL_STATE_DIR="$tmpdir/state"
  mkdir -p "$tmpdir/plists"
  plist="$tmpdir/plists/org.wizardry.web.mysite.plist"
  : > "$plist"

  "$tmpdir/launchctl" load -w "$plist"
  grep -q '^org.wizardry.web.mysite$' "$tmpdir/state/loaded"

  "$tmpdir/launchctl" unload -w "$plist"
  if grep -q '^org.wizardry.web.mysite$' "$tmpdir/state/loaded" 2>/dev/null; then
    return 1
  fi
}

test_stub_tracks_enable_disable_state() {
  tmpdir=$(make_tempdir)
  stub_launchctl "$tmpdir"
  export LAUNCHCTL_STATE_DIR="$tmpdir/state"

  "$tmpdir/launchctl" disable "system/org.wizardry.web.mysite"
  "$tmpdir/launchctl" print-disabled system | grep -q '"org.wizardry.web.mysite" => true'

  "$tmpdir/launchctl" enable "system/org.wizardry.web.mysite"
  if "$tmpdir/launchctl" print-disabled system | grep -q '"org.wizardry.web.mysite" => true'; then
    return 1
  fi
}

run_test_case "stub-launchctl creates executable" test_creates_stub
run_test_case "stub-launchctl tracks load and unload" test_stub_tracks_load_and_unload
run_test_case "stub-launchctl tracks enable and disable state" \
  test_stub_tracks_enable_disable_state

finish_tests
