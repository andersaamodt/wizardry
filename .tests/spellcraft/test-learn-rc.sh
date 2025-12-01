#!/bin/sh
# Behavioral cases (derived from --help):
# - learn-rc prints usage
# - learn-rc manages shell rc file snippets with wizardry sentinels

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/spellcraft/learn-rc" --help
  assert_success && assert_output_contains "Usage: learn-rc"
}

test_missing_args() {
  run_spell "spells/spellcraft/learn-rc"
  assert_failure && assert_error_contains "Usage: learn-rc"
}

test_rejects_invalid_name() {
  run_spell "spells/spellcraft/learn-rc" --rc-file "$WIZARDRY_TMPDIR/rc" --spell "bad name" add <<'EOF'
echo hi
EOF
  assert_failure && assert_error_contains "spell names may contain only"
}

test_adds_inline_spell() {
  rc="$WIZARDRY_TMPDIR/inline_rc"
  run_spell "spells/spellcraft/learn-rc" --rc-file "$rc" --spell summon add <<'EOF'
export HELLO=WORLD
EOF
  assert_success
  assert_file_contains "$rc" "export HELLO=WORLD # wizardry: summon"
}

test_adds_and_readds_block_spell_idempotently() {
  rc="$WIZARDRY_TMPDIR/block_rc"
  run_spell "spells/spellcraft/learn-rc" --rc-file "$rc" --spell portal add <<'EOF'
echo first
echo second
EOF
  assert_success
  first="$(cat "$rc")"

  run_spell "spells/spellcraft/learn-rc" --rc-file "$rc" --spell portal add <<'EOF'
echo first
echo second
EOF
  assert_success
  second="$(cat "$rc")"
  [ "$first" = "$second" ] || { TEST_FAILURE_REASON="expected idempotent block add"; return 1; }
  assert_file_contains "$rc" "# wizardry: portal begin lines=2"
  assert_file_contains "$rc" "# wizardry: portal end"
}

test_remove_reports_missing_file() {
  missing="$WIZARDRY_TMPDIR/absent_rc"
  run_spell "spells/spellcraft/learn-rc" --rc-file "$missing" --spell phantom remove
  assert_failure && assert_error_contains "cannot remove from missing file"
}

test_remove_cleans_block() {
  rc="$WIZARDRY_TMPDIR/cleanup_rc"
  run_spell "spells/spellcraft/learn-rc" --rc-file "$rc" --spell vanish add <<'EOF'
echo vanish
echo more
EOF
  assert_success
  run_spell "spells/spellcraft/learn-rc" --rc-file "$rc" --spell vanish remove
  assert_success
  [ ! -s "$rc" ] || { TEST_FAILURE_REASON="expected file empty after remove"; return 1; }
}

test_status_reflects_presence() {
  rc="$WIZARDRY_TMPDIR/status_rc"
  run_spell "spells/spellcraft/learn-rc" --rc-file "$rc" --spell statuser status
  assert_failure

  run_spell "spells/spellcraft/learn-rc" --rc-file "$rc" --spell statuser add <<'EOF'
echo status
EOF
  assert_success
  run_spell "spells/spellcraft/learn-rc" --rc-file "$rc" --spell statuser status
  assert_success
}

test_requires_spell_and_action() {
  # Missing spell name
  run_spell "spells/spellcraft/learn-rc" --rc-file "$WIZARDRY_TMPDIR/rc" add </dev/null
  assert_failure && assert_error_contains "Usage:"
  
  # Missing action
  run_spell "spells/spellcraft/learn-rc" --rc-file "$WIZARDRY_TMPDIR/rc" --spell test </dev/null
  assert_failure && assert_error_contains "Usage:"
}

test_unknown_option() {
  run_spell "spells/spellcraft/learn-rc" --unknown-flag </dev/null
  assert_failure && assert_error_contains "unknown option"
}

test_unexpected_argument() {
  run_spell "spells/spellcraft/learn-rc" --rc-file "$WIZARDRY_TMPDIR/rc" --spell test add extra_arg </dev/null
  assert_failure && assert_error_contains "unexpected argument"
}

run_test_case "learn-rc prints usage" test_help
run_test_case "learn-rc errors without required arguments" test_missing_args
run_test_case "learn-rc rejects invalid spell names" test_rejects_invalid_name
run_test_case "learn-rc adds inline spell content" test_adds_inline_spell
run_test_case "learn-rc adds blocks idempotently" test_adds_and_readds_block_spell_idempotently
run_test_case "learn-rc fails to remove missing files" test_remove_reports_missing_file
run_test_case "learn-rc removes previously added blocks" test_remove_cleans_block
run_test_case "learn-rc status tracks presence" test_status_reflects_presence
run_test_case "learn-rc requires spell and action" test_requires_spell_and_action
run_test_case "learn-rc rejects unknown options" test_unknown_option
run_test_case "learn-rc rejects unexpected arguments" test_unexpected_argument
finish_tests
