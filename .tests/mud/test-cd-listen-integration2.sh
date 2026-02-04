#!/bin/sh
# Integration test for cd-listen with relative paths (user's exact scenario)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_cd_then_relative_path() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/sites"
  
  # Set up environment like user's
  export PATH="$test_root/spells/mud:$test_root/spells/.imps/sys:$test_root/spells/.imps/out:$test_root/spells/.arcana/mud:$PATH"
  export SPELLBOOK_DIR="$tmpdir"
  export MUD_PLAYER="TestUser"
  export HOME="$tmpdir"
  
  # Enable cd-listen
  echo "cd-listen=1" > "$SPELLBOOK_DIR/.mud"
  
  # Source cd hook
  . "$test_root/spells/.arcana/mud/load-cd-hook"
  
  # User's exact scenario: cd ~ then cd sites
  cd ~ || return 1
  sleep 1
  
  cd sites || return 1
  sleep 2
  
  # Check if listener started
  listener_count=$(pgrep -f "tail -f.*sites/.log" 2>/dev/null | wc -l)
  
  # Clean up tail processes
  tail_pids=$(pgrep -f "tail -f.*$tmpdir" 2>/dev/null || true)
  for pid in $tail_pids; do
    [ -n "$pid" ] && kill "$pid" 2>/dev/null || true
  done
  
  # Verify listener was running
  [ "$listener_count" -gt 0 ] || return 1
}

run_test_case "cd ~ then cd sites starts listener" test_cd_then_relative_path

finish_tests
