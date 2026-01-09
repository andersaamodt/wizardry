#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test jump next and jump 0 cycling behavior

test_jump_next_with_no_markers() {
  # Create temp directory for test
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Source spells directly since we can't generate glosses in test
  OUTPUT=$(. "$ROOT_DIR/spells/translocation/jump-to-marker" next 2>&1)
  result=$?
  
  # Should fail gracefully (not exit 0)
  [ $result -ne 0 ] || return 1
  
  # Error message should be helpful, not "No marker '' found"
  case "$OUTPUT" in
    *"No marker '' found"*)
      # Bug: empty marker name in error message
      return 1
      ;;
    *"No markers"*)
      # Correct: helpful error message
      return 0
      ;;
    *)
      # Unexpected output
      return 1
      ;;
  esac
}

test_jump_0_with_no_markers() {
  # Create temp directory for test
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Source spell directly
  OUTPUT=$(. "$ROOT_DIR/spells/translocation/jump-to-marker" 0 2>&1)
  result=$?
  
  # Should fail gracefully
  [ $result -ne 0 ] || return 1
  
  # Error message should be helpful
  case "$OUTPUT" in
    *"No marker '' found"*)
      # Bug: empty marker name
      return 1
      ;;
    *"No markers"*)
      # Correct: helpful error
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

test_jump_next_cycles_through_markers() {
  # Create temp directory for test
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  export WIZARDRY_DIR="$ROOT_DIR"
  export WIZARDRY_TEST_HELPERS_ONLY=1
  export PATH="$WIZARDRY_IMPS_PATH:/bin:/usr/bin"
  mkdir -p "$SPELLBOOK_DIR/.markers"
  
  # Create three marker directories
  mkdir -p "$tmpdir/marker1" "$tmpdir/marker2" "$tmpdir/marker3"
  printf '%s\n' "$tmpdir/marker1" > "$SPELLBOOK_DIR/.markers/1"
  printf '%s\n' "$tmpdir/marker2" > "$SPELLBOOK_DIR/.markers/2"
  printf '%s\n' "$tmpdir/marker3" > "$SPELLBOOK_DIR/.markers/3"
  
  # Touch marker files in order to set mtime (most recent = 3)
  sleep 0.1; touch "$SPELLBOOK_DIR/.markers/1"
  sleep 0.1; touch "$SPELLBOOK_DIR/.markers/2"
  sleep 0.1; touch "$SPELLBOOK_DIR/.markers/3"
  
  # Start in tmpdir
  cd "$tmpdir" || return 1
  
  # Test: jump next should cycle from marker 3 (most recent) to marker 1 (next in sequence)
  . "$ROOT_DIR/spells/translocation/jump-to-marker" next >/dev/null 2>&1
  result=$?
  [ $result -eq 0 ] || return 1
  
  # Should be in marker1 directory now
  current=$(pwd -P | sed 's|//|/|g')
  expected=$(printf '%s' "$tmpdir/marker1" | sed 's|//|/|g')
  [ "$current" = "$expected" ] || return 1
  
  # Now marker 1 is most recent, so next should go to marker 2
  sleep 0.1
  . "$ROOT_DIR/spells/translocation/jump-to-marker" next >/dev/null 2>&1
  result=$?
  [ $result -eq 0 ] || return 1
  
  current=$(pwd -P | sed 's|//|/|g')
  expected=$(printf '%s' "$tmpdir/marker2" | sed 's|//|/|g')
  [ "$current" = "$expected" ]
}

test_jump_0_same_as_jump_next() {
  # Create temp directory for test
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  export WIZARDRY_DIR="$ROOT_DIR"
  export WIZARDRY_TEST_HELPERS_ONLY=1
  export PATH="$WIZARDRY_IMPS_PATH:/bin:/usr/bin"
  mkdir -p "$SPELLBOOK_DIR/.markers"
  
  # Create two marker directories
  mkdir -p "$tmpdir/marker1" "$tmpdir/marker2"
  printf '%s\n' "$tmpdir/marker1" > "$SPELLBOOK_DIR/.markers/1"
  printf '%s\n' "$tmpdir/marker2" > "$SPELLBOOK_DIR/.markers/2"
  
  # Touch marker files (most recent = 2)
  sleep 0.1; touch "$SPELLBOOK_DIR/.markers/1"
  sleep 0.1; touch "$SPELLBOOK_DIR/.markers/2"
  
  cd "$tmpdir" || return 1
  
  # Test: jump 0 should behave same as jump next
  . "$ROOT_DIR/spells/translocation/jump-to-marker" 0 >/dev/null 2>&1
  result=$?
  [ $result -eq 0 ] || return 1
  
  # Should be in marker1 (next after marker 2)
  current=$(pwd -P | sed 's|//|/|g')
  expected=$(printf '%s' "$tmpdir/marker1" | sed 's|//|/|g')
  [ "$current" = "$expected" ]
}

run_test_case "jump next with no markers gives helpful error" test_jump_next_with_no_markers
run_test_case "jump 0 with no markers gives helpful error" test_jump_0_with_no_markers
run_test_case "jump next cycles through markers correctly" test_jump_next_cycles_through_markers
run_test_case "jump 0 same as jump next" test_jump_0_same_as_jump_next

finish_tests
