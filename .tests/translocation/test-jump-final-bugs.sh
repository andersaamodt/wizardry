#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Bug 1: "jump to location" should find jump-to-location synonym (longest match)
test_jump_to_location_multi_word() {
  # Create temporary markers for testing
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  mkdir -p "$SPELLBOOK_DIR/.markers"
  
  # Create marker directories (use .markers/ format, not .marker.X)
  mkdir -p "$tmpdir/marker1"
  printf '%s\n' "$tmpdir/marker1" > "$SPELLBOOK_DIR/.markers/1"
  
  # Regenerate glosses to pick up environment
  eval "$(WIZARDRY_DIR="$ROOT_DIR" "$ROOT_DIR/spells/.wizardry/generate-glosses" --quiet)"
  
  # Source invoke-thesaurus to get synonyms
  WIZARDRY_DIR="$ROOT_DIR" . "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus"
  
  # Test: jump to location should work via synonym
  # This tests longest-match parsing
  cd "$tmpdir" || return 1
  jump to location >/dev/null 2>&1
  result=$?
  
  # Should succeed (synonym resolves to jump-to-marker)
  [ $result -eq 0 ] || return 1
  
  # Should have changed to marker1 directory
  current=$(pwd -P)
  expected="$tmpdir/marker1"
  # Normalize both paths for comparison
  current_norm=$(printf '%s' "$current" | sed 's|//|/|g')
  expected_norm=$(printf '%s' "$expected" | sed 's|//|/|g')
  [ "$current_norm" = "$expected_norm" ]
}

# Bug 2: jump-to-location should work as alias (hyphenated synonym)
test_jump_to_location_alias() {
  # Create temporary markers for testing
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  mkdir -p "$SPELLBOOK_DIR/.markers"
  
  # Create marker directory (use .markers/ format)
  mkdir -p "$tmpdir/marker1"
  printf '%s\n' "$tmpdir/marker1" > "$SPELLBOOK_DIR/.markers/1"
  
  # Regenerate glosses with hyphenated alias support
  eval "$(WIZARDRY_DIR="$ROOT_DIR" "$ROOT_DIR/spells/.wizardry/generate-glosses" --quiet)"
  
  # Source invoke-thesaurus to get synonyms (including aliases)
  WIZARDRY_DIR="$ROOT_DIR" . "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus"
  
  # Test 1: Verify alias exists with correct expansion
  alias_def=$(alias jump-to-location 2>/dev/null || printf '')
  case "$alias_def" in
    *"jump to marker"*)
      # Alias exists and expands correctly
      ;;
    *)
      # Alias missing or wrong
      return 1
      ;;
  esac
  
  # Test 2: The alias expands to "jump to marker" which should work via first-word gloss
  # (Aliases don't always expand in function contexts, so test the expansion directly)
  cd "$tmpdir" || return 1
  jump to marker >/dev/null 2>&1
  result=$?
  
  # Should succeed
  [ $result -eq 0 ] || return 1
  
  # Should have changed to marker1 directory
  current=$(pwd -P)
  expected="$tmpdir/marker1"
  # Normalize both paths for comparison
  current_norm=$(printf '%s' "$current" | sed 's|//|/|g')
  expected_norm=$(printf '%s' "$expected" | sed 's|//|/|g')
  [ "$current_norm" = "$expected_norm" ]
}

# Bug 3: jump-trash when already in trash should work (not crash)
test_jump_trash_when_in_trash() {
  # Get trash directory
  if command -v detect-trash >/dev/null 2>&1; then
    trash_path=$(detect-trash)
  else
    # Inline detection
    kernel=$(uname -s 2>/dev/null || printf 'unknown')
    case "$kernel" in
    Darwin) trash_path="$HOME/.Trash" ;;
    *)
      xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
      trash_path="$xdg_data/Trash/files"
      ;;
    esac
  fi
  
  # Ensure trash exists
  mkdir -p "$trash_path" 2>/dev/null || return 0  # Skip if can't create
  
  # Move to trash
  cd "$trash_path" || return 1
  
  # Regenerate glosses
  eval "$(WIZARDRY_DIR="$ROOT_DIR" "$ROOT_DIR/spells/.wizardry/generate-glosses" --quiet)"
  
  # Test: jump-trash when already in trash should not crash
  OUTPUT=$(jump trash 2>&1)
  result=$?
  
  # Should succeed (return 0)
  [ $result -eq 0 ] || return 1
  
  # Should report already in trash
  case "$OUTPUT" in
    *"already in the trash"*) return 0 ;;
    *) return 1 ;;
  esac
}

run_test_case "jump to location multi-word works" test_jump_to_location_multi_word
run_test_case "jump-to-location works as alias" test_jump_to_location_alias
run_test_case "jump-trash when in trash does not crash" test_jump_trash_when_in_trash

finish_tests
