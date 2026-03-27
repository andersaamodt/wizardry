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
  assert_output_contains "Level 28: Web Services & CGI" || return 1
  assert_output_contains "site-status -> built, not serving" || return 1
  assert_output_contains "DEMO_MAGIC_COMPLETE" || return 1
}

test_level_5_runs_full_xattr_roundtrip() {
  run_demo_magic 5
  assert_success || return 1
  assert_output_contains "Level 5: Extended Attributes" || return 1
  assert_output_contains "xattr round-trip -> mood=calm" || return 1
  assert_output_contains "yaml-to-enchantment -> mood=calm" || return 1
  assert_output_contains "disenchant -> attribute cleared" || return 1
  assert_output_contains "Live casts: 4/4" || return 1
}

test_level_6_uses_safe_priority_lookup() {
  run_demo_magic 6
  assert_success || return 1
  assert_output_contains "Level 6: Task Priorities" || return 1
  assert_output_contains "get-card ->" || return 1
  assert_output_contains "reprioritization stays descriptive" || return 1
}

test_level_7_navigation_is_live() {
  run_demo_magic 7
  assert_success || return 1
  assert_output_contains "Level 7: Navigation" || return 1
  assert_output_contains "Marked location hearth" || return 1
  assert_output_contains "go-up -> cd \"../..\"" || return 1
  assert_output_contains "jump-to-marker ->" || return 1
}

test_level_10_arcane_operations_stay_in_fixture_space() {
  run_demo_magic 10
  assert_success || return 1
  assert_output_contains "Level 10: Arcane File Operations" || return 1
  assert_output_contains "read-magic -> sigil=oak" || return 1
  assert_output_contains "project notes.md" || return 1
  assert_output_contains "jump-trash ->" || return 1
}

test_level_14_marks_self_reference_without_overwriting() {
  run_demo_magic 14
  assert_success || return 1
  assert_output_contains "Level 14: Advanced System Tools" || return 1
  assert_output_contains "The spell currently speaking is demo-magic itself." || return 1
  assert_output_contains "spark" || return 1
}

test_level_15_divination_reads_fixture_magic() {
  run_demo_magic 15
  assert_success || return 1
  assert_output_contains "Level 15: Divination" || return 1
  assert_output_contains "detect-magic:" || return 1
  assert_output_contains "divination-scroll.txt" || return 1
  assert_output_contains "detect-rc-file:" || return 1
  assert_output_contains "identify-room:" || return 1
}

test_level_17_uses_real_crypto_behaviors() {
  run_demo_magic 17
  assert_success || return 1
  assert_output_contains "Level 17: Cryptography" || return 1
  assert_output_contains "hash -> 0x" || return 1
  assert_output_contains "hashchant -> 0x" || return 1
  assert_output_contains_either "evoke-hash ->" "evoke-hash held back:" || return 1
}

test_level_24_uses_mud_menu_help_surface() {
  run_demo_magic 24
  assert_success || return 1
  assert_output_contains "Level 24: MUD Administration Menus" || return 1
  assert_output_contains "mud-menu --help -> Usage: . mud-menu" || return 1
  assert_output_contains "Described or held back: add-player, mud," || return 1
}

test_level_20_shows_task_state_transitions() {
  run_demo_magic 20
  assert_success || return 1
  assert_output_contains "Level 20: Process & System Info (PSI)" || return 1
  assert_output_contains "get-checked -> 1" || return 1
  assert_output_contains "get-checked -> 0" || return 1
}

run_test_case "demo-magic shows current help and safety model" test_help
run_test_case "demo-magic no-sandbox flag works in non-interactive mode" test_no_sandbox_flag_works_noninteractive
run_test_case "demo-magic internal pocket flag avoids resandbox loops" test_demo_in_pocket_flag_skips_resandbox
run_test_case "demo-magic default run reaches the current highest level" test_default_runs_all_levels
run_test_case "demo-magic level 5 performs the xattr roundtrip" test_level_5_runs_full_xattr_roundtrip
run_test_case "demo-magic level 6 uses safe priority lookup" test_level_6_uses_safe_priority_lookup
run_test_case "demo-magic level 7 replays disposable navigation" test_level_7_navigation_is_live
run_test_case "demo-magic level 10 keeps file operations inside fixtures" test_level_10_arcane_operations_stay_in_fixture_space
run_test_case "demo-magic level 14 makes self-reference explicit" test_level_14_marks_self_reference_without_overwriting
run_test_case "demo-magic level 15 divines fixture-local enchantments" test_level_15_divination_reads_fixture_magic
run_test_case "demo-magic level 17 uses real crypto behaviors" test_level_17_uses_real_crypto_behaviors
run_test_case "demo-magic level 24 uses mud-menu help without miscounting mud" test_level_24_uses_mud_menu_help_surface
run_test_case "demo-magic level 20 shows checked and unchecked states" test_level_20_shows_task_state_transitions

finish_tests
