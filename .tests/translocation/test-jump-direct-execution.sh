#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that hyphenated spell commands work as aliases (don't crash terminal)
# These should expand to space-separated forms and source correctly

test_jump_to_marker_alias_generated() {
  # Regenerate glosses to create aliases
  eval "$(WIZARDRY_DIR="$ROOT_DIR" "$ROOT_DIR/spells/.wizardry/generate-glosses" --quiet)"
  
  # Source invoke-thesaurus to get aliases
  WIZARDRY_DIR="$ROOT_DIR" . "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus"
  
  # Test: Verify jump-to-marker alias exists and expands to space-separated form
  # Note: In non-interactive bash, we can't test alias expansion directly
  # But we can verify the alias definition is correct
  alias_def=$(alias jump-to-marker 2>/dev/null || printf '')
  case "$alias_def" in
    *"jump to marker"*)
      # Alias exists and expands correctly
      return 0
      ;;
    *)
      # Alias missing or wrong - this is the bug
      return 1
      ;;
  esac
}

test_jump_trash_alias_generated() {
  # Regenerate glosses to create aliases
  eval "$(WIZARDRY_DIR="$ROOT_DIR" "$ROOT_DIR/spells/.wizardry/generate-glosses" --quiet)"
  
  # Source invoke-thesaurus
  WIZARDRY_DIR="$ROOT_DIR" . "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus"
  
  # Test: Verify jump-trash alias exists and expands to space-separated form
  alias_def=$(alias jump-trash 2>/dev/null || printf '')
  case "$alias_def" in
    *"jump trash"*)
      # Alias exists and expands correctly
      return 0
      ;;
    *)
      # Alias missing or wrong - this is the bug
      return 1
      ;;
  esac
}

test_space_separated_forms_work() {
  # Create temporary markers for testing
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir"
  mkdir -p "$SPELLBOOK_DIR/.markers"
  
  # Create marker directory
  mkdir -p "$tmpdir/marker1"
  printf '%s\n' "$tmpdir/marker1" > "$SPELLBOOK_DIR/.markers/1"
  
  # Get trash directory
  if command -v detect-trash >/dev/null 2>&1; then
    trash_path=$(detect-trash)
  else
    kernel=$(uname -s 2>/dev/null || printf 'unknown')
    case "$kernel" in
    Darwin) trash_path="$HOME/.Trash" ;;
    *)
      xdg_data="${XDG_DATA_HOME:-$HOME/.local/share}"
      trash_path="$xdg_data/Trash/files"
      ;;
    esac
  fi
  mkdir -p "$trash_path" 2>/dev/null || return 0  # Skip if can't create
  
  # Regenerate glosses
  eval "$(WIZARDRY_DIR="$ROOT_DIR" "$ROOT_DIR/spells/.wizardry/generate-glosses" --quiet)"
  
  # Test 1: jump to marker works (what the alias expands to)
  cd "$tmpdir" || return 1
  OUTPUT=$(jump to marker 2>&1)
  result=$?
  [ $result -eq 0 ] || return 1
  
  # Should have changed to marker1 directory
  current=$(pwd -P | sed 's|//|/|g')
  expected=$(printf '%s' "$tmpdir/marker1" | sed 's|//|/|g')
  [ "$current" = "$expected" ] || return 1
  
  # Test 2: jump trash works (what the alias expands to)
  OUTPUT=$(jump trash 2>&1)
  result=$?
  [ $result -eq 0 ] || return 1
  
  # Should be in trash now
  current=$(pwd -P | sed 's|//|/|g')
  trash_resolved=$(cd "$trash_path" && pwd -P | sed 's|//|/|g')
  [ "$current" = "$trash_resolved" ]
}

run_test_case "jump-to-marker alias is generated correctly" test_jump_to_marker_alias_generated
run_test_case "jump-trash alias is generated correctly" test_jump_trash_alias_generated
run_test_case "space-separated forms work (what aliases expand to)" test_space_separated_forms_work

finish_tests
