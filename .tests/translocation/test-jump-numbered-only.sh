#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that jump 0 and jump next cycle through ONLY numbered markers

test_jump_cycles_numbered_markers_only() {
  # Create temp directory for test
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  export WIZARDRY_DIR="$ROOT_DIR"
  export WIZARDRY_TEST_HELPERS_ONLY=1
  export PATH="$WIZARDRY_IMPS_PATH:/bin:/usr/bin"
  mkdir -p "$SPELLBOOK_DIR/.markers"
  
  # Create three numbered markers and one named marker
  mkdir -p "$tmpdir/marker1" "$tmpdir/marker2" "$tmpdir/marker3" "$tmpdir/marker_alpha"
  printf '%s\n' "$tmpdir/marker1" > "$SPELLBOOK_DIR/.markers/1"
  sleep 0.2
  printf '%s\n' "$tmpdir/marker2" > "$SPELLBOOK_DIR/.markers/2"
  sleep 0.2
  printf '%s\n' "$tmpdir/marker3" > "$SPELLBOOK_DIR/.markers/3"
  sleep 0.2
  printf '%s\n' "$tmpdir/marker_alpha" > "$SPELLBOOK_DIR/.markers/alpha"
  
  # Start in tmpdir
  cd "$tmpdir" || return 1
  
  # Most recent marker overall is "alpha" (named)
  # Most recent numbered marker is "3"
  # jump 0 should go to next numbered marker after 3, which is 1
  set -- 0
  . "$ROOT_DIR/spells/translocation/jump-to-marker" >/dev/null 2>&1
  result=$?
  [ $result -eq 0 ] || return 1
  
  current=$(pwd -P | sed 's|//|/|g')
  expected=$(printf '%s' "$tmpdir/marker1" | sed 's|//|/|g')
  [ "$current" = "$expected" ] || return 1
  
  # jump next should go to marker 2
  sleep 0.2
  set -- next
  . "$ROOT_DIR/spells/translocation/jump-to-marker" >/dev/null 2>&1
  result=$?
  [ $result -eq 0 ] || return 1
  
  current=$(pwd -P | sed 's|//|/|g')
  expected=$(printf '%s' "$tmpdir/marker2" | sed 's|//|/|g')
  [ "$current" = "$expected" ] || return 1
  
  # jump 0 should go to marker 3
  sleep 0.2
  set -- 0
  . "$ROOT_DIR/spells/translocation/jump-to-marker" >/dev/null 2>&1
  result=$?
  [ $result -eq 0 ] || return 1
  
  current=$(pwd -P | sed 's|//|/|g')
  expected=$(printf '%s' "$tmpdir/marker3" | sed 's|//|/|g')
  [ "$current" = "$expected" ] || return 1
  
  # jump next should wrap to marker 1
  sleep 0.2
  set -- next
  . "$ROOT_DIR/spells/translocation/jump-to-marker" >/dev/null 2>&1
  result=$?
  [ $result -eq 0 ] || return 1
  
  current=$(pwd -P | sed 's|//|/|g')
  expected=$(printf '%s' "$tmpdir/marker1" | sed 's|//|/|g')
  [ "$current" = "$expected" ]
}

test_can_jump_to_named_marker_directly() {
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  export WIZARDRY_DIR="$ROOT_DIR"
  export WIZARDRY_TEST_HELPERS_ONLY=1
  export PATH="$WIZARDRY_IMPS_PATH:/bin:/usr/bin"
  mkdir -p "$SPELLBOOK_DIR/.markers"
  
  mkdir -p "$tmpdir/marker1" "$tmpdir/marker_alpha"
  printf '%s\n' "$tmpdir/marker1" > "$SPELLBOOK_DIR/.markers/1"
  printf '%s\n' "$tmpdir/marker_alpha" > "$SPELLBOOK_DIR/.markers/alpha"
  
  cd "$tmpdir" || return 1
  
  # Can still jump to named marker directly
  set -- alpha
  . "$ROOT_DIR/spells/translocation/jump-to-marker" >/dev/null 2>&1
  result=$?
  [ $result -eq 0 ] || return 1
  
  current=$(pwd -P | sed 's|//|/|g')
  expected=$(printf '%s' "$tmpdir/marker_alpha" | sed 's|//|/|g')
  [ "$current" = "$expected" ]
}

test_after_named_marker_cycles_numbered() {
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  export WIZARDRY_DIR="$ROOT_DIR"
  export WIZARDRY_TEST_HELPERS_ONLY=1
  export PATH="$WIZARDRY_IMPS_PATH:/bin:/usr/bin"
  mkdir -p "$SPELLBOOK_DIR/.markers"
  
  mkdir -p "$tmpdir/marker1" "$tmpdir/marker2" "$tmpdir/marker_alpha"
  printf '%s\n' "$tmpdir/marker1" > "$SPELLBOOK_DIR/.markers/1"
  sleep 0.2
  printf '%s\n' "$tmpdir/marker2" > "$SPELLBOOK_DIR/.markers/2"
  sleep 0.2
  printf '%s\n' "$tmpdir/marker_alpha" > "$SPELLBOOK_DIR/.markers/alpha"
  
  # Jump to alpha
  cd "$tmpdir" || return 1
  set -- alpha
  . "$ROOT_DIR/spells/translocation/jump-to-marker" >/dev/null 2>&1
  
  # Touch alpha to make it most recent
  sleep 0.2
  touch "$SPELLBOOK_DIR/.markers/alpha"
  
  # Now jump 0 should cycle through numbered markers, not stay at or cycle through alpha
  set -- 0
  . "$ROOT_DIR/spells/translocation/jump-to-marker" >/dev/null 2>&1
  result=$?
  [ $result -eq 0 ] || return 1
  
  current=$(pwd -P | sed 's|//|/|g')
  # Should be at a numbered marker, not alpha
  case "$current" in
    */marker1|*/marker2) return 0 ;;
    */marker_alpha) return 1 ;;
    *) return 1 ;;
  esac
}

run_test_case "jump 0 and next cycle through numbered markers only" test_jump_cycles_numbered_markers_only
run_test_case "can still jump to named marker directly" test_can_jump_to_named_marker_directly
run_test_case "after jumping to named marker, cycling uses numbered only" test_after_named_marker_cycles_numbered

finish_tests
