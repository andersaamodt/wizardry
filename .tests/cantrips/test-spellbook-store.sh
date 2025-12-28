#!/bin/sh
# Behavior cases from --help: manage aliases in the spellbook store.
# - Adds or updates entries when provided a name and command.
# - Lists stored entries in name<TAB>command format.
# - Removes existing entries or fails for unknown names.
# - Reports the spellbook file path and respects custom locations.
# - Rejects invalid names, commands, or argument counts.

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

tabbed() {
  printf 'portal\t%s' "$1"
}

spellbook_env() {
  dir=$(mktemp -d "${WIZARDRY_TMPDIR}/spellbook.XXXXXX")
  printf '%s' "WIZARDRY_SPELLBOOK_FILE=$dir/book"
}

run_store() {
  env_var=$1
  shift
  run_cmd env "$env_var" "$ROOT_DIR/spells/cantrips/spellbook-store" "$@"
}

normalize_output() {
  printf '%s' "$OUTPUT" | tr '\n' '|'
}

# adds and lists entries
adds_and_lists_entries() {
  env_var=$(spellbook_env)
  run_store "$env_var" add portal "echo jump"
  [ "$STATUS" -eq 0 ] || return 1

  run_store "$env_var" list
  [ "$STATUS" -eq 0 ] || return 1
  expected=$(tabbed "echo jump")
  case "$(normalize_output)" in
    "$expected"|"$expected|") : ;;
    *) TEST_FAILURE_REASON="unexpected list output: $OUTPUT"; return 1 ;;
  esac
}

# updates existing entries
updates_existing_entry() {
  env_var=$(spellbook_env)
  run_store "$env_var" add portal "echo jump"
  run_store "$env_var" add portal "echo stay"
  run_store "$env_var" list
  expected=$(tabbed "echo stay")
  case "$(normalize_output)" in
    "$expected"|"$expected|") : ;;
    *) TEST_FAILURE_REASON="expected updated command"; return 1 ;;
  esac
}

# removes entries and errors for missing names
removes_entries_and_errors_when_missing() {
  env_var=$(spellbook_env)
  run_store "$env_var" add portal "echo jump"
  run_store "$env_var" remove portal
  [ "$STATUS" -eq 0 ] || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="remove should be silent"; return 1; }

  run_store "$env_var" remove portal
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected failure for missing"; return 1; }
}

# prints configured spellbook path
prints_spellbook_path() {
  env_var=$(spellbook_env)
  file=${env_var#*=}
  run_store "$env_var" path
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "$file" ] || { TEST_FAILURE_REASON="unexpected path output"; return 1; }
}

# rejects invalid arguments
rejects_invalid_args() {
  env_var=$(spellbook_env)
  run_store "$env_var" add "bad name" "echo x"
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected invalid name failure"; return 1; }

  run_store "$env_var" add portal ""
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected empty command failure"; return 1; }

  run_store "$env_var" list extra
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected usage failure"; return 1; }
}

run_test_case "adds and lists entries" adds_and_lists_entries
run_test_case "updates existing entry" updates_existing_entry
run_test_case "removes entries and errors when missing" removes_entries_and_errors_when_missing
run_test_case "prints spellbook path" prints_spellbook_path
run_test_case "rejects invalid arguments" rejects_invalid_args

shows_help() {
  run_spell spells/cantrips/spellbook-store --help
  true
}

run_test_case "spellbook-store shows help" shows_help


# Test via source-then-invoke pattern  
