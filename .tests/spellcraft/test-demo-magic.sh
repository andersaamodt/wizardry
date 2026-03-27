#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

run_demo_magic() {
  WIZARDRY_DEMO_NO_BWRAP=1 run_spell spells/spellcraft/demo-magic "$@"
}

assert_output_contains_either() {
  first=$1
  second=$2

  case "$OUTPUT" in
    *"$first"*|*"$second"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="expected output to contain '$first' or '$second'"
      return 1
      ;;
  esac
}

assert_output_not_contains() {
  pattern=$1

  case "$OUTPUT" in
    *"$pattern"*)
      TEST_FAILURE_REASON="did not expect output to contain '$pattern'"
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}

test_help() {
  run_spell spells/spellcraft/demo-magic --help
  assert_success || return 1
  assert_output_contains "Usage: demo-magic [LEVEL|all]" || return 1
  assert_output_contains "disposable fixtures" || return 1
  assert_output_contains "Current level range: 0-28" || return 1
}

test_no_sandbox_flag_works_noninteractive() {
  run_cmd env WIZARDRY_DEMO_NO_SANDBOX=1 "$ROOT_DIR/spells/spellcraft/demo-magic" 0
  assert_success || return 1
  assert_output_contains "Disposable fixtures:" || return 1
  assert_output_contains "Level 0: POSIX & Platform Foundation" || return 1
}

test_demo_in_pocket_flag_skips_resandbox() {
  run_cmd "$ROOT_DIR/spells/spellcraft/demo-magic" --demo-in-pocket 0
  assert_success || return 1
  assert_output_contains "Disposable fixtures:" || return 1
  assert_output_contains "Level 0: POSIX & Platform Foundation" || return 1
}

test_default_runs_all_levels() {
  run_demo_magic
  assert_success || return 1
  assert_output_contains "Level 3: Glossary & Parsing" || return 1
  assert_output_contains "Level 5: Extended Attributes" || return 1
  assert_output_contains "xattr round-trip -> mood=calm" || return 1
  assert_output_contains "yaml-to-enchantment -> mood=calm" || return 1
  assert_output_contains "Level 6: Task Priorities" || return 1
  assert_output_contains "get-card ->" || return 1
  assert_output_contains "Level 7: Navigation" || return 1
  assert_output_contains "jump-to-marker ->" || return 1
  assert_output_contains "Level 10: Arcane File Operations" || return 1
  assert_output_contains "jump-trash ->" || return 1
  assert_output_contains "Level 14: Advanced System Tools" || return 1
  assert_output_contains "The spell currently speaking is demo-magic itself." || return 1
  assert_output_contains "Level 15: Divination" || return 1
  assert_output_contains "divination-scroll.txt" || return 1
  assert_output_contains "Level 17: Cryptography" || return 1
  assert_output_contains "hashchant -> 0x" || return 1
  assert_output_contains_either "evoke-hash ->" "evoke-hash skipped:" || return 1
  assert_output_contains "Level 20: Process & System Info (PSI)" || return 1
  assert_output_contains "get-checked -> 1" || return 1
  assert_output_contains "get-checked -> 0" || return 1
  assert_output_contains "Level 24: MUD Administration Menus" || return 1
  assert_output_contains "mud-menu --help -> Usage: . mud-menu" || return 1
  assert_output_contains "Skipped: add-player, mud," || return 1
  assert_output_contains "Skipped: kill-process, update-all, update-wizardry" || return 1
  assert_output_not_contains "Described or held back:" || return 1
  assert_output_contains "Level 28: Web Services & CGI" || return 1
  assert_output_contains "site-status -> built, not serving" || return 1
  assert_output_contains "DEMO_MAGIC_COMPLETE" || return 1
}

run_test_case "demo-magic shows current help and safety model" test_help
run_test_case "demo-magic no-sandbox flag works in non-interactive mode" \
  test_no_sandbox_flag_works_noninteractive
run_test_case "demo-magic internal pocket flag avoids resandbox loops" \
  test_demo_in_pocket_flag_skips_resandbox
run_test_case "demo-magic full run covers live behaviors across levels" test_default_runs_all_levels

finish_tests
