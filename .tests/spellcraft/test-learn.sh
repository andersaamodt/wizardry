#!/bin/sh
# Behavioral cases (derived from --help):
# - learn prints usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/spellcraft/learn" --help
  assert_success && assert_error_contains "Usage: learn"
}

test_missing_args() {
  run_spell "spells/spellcraft/learn"
  assert_failure && assert_error_contains "Usage: learn"
}

test_rejects_invalid_name() {
  run_spell "spells/spellcraft/learn" --rc-file "$WIZARDRY_TMPDIR/rc" --spell "bad name" add <<'EOF'
echo hi
EOF
  assert_failure && assert_error_contains "spell names may contain only"
}

test_adds_inline_spell() {
  rc="$WIZARDRY_TMPDIR/inline_rc"
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell summon add <<'EOF'
export HELLO=WORLD
EOF
  assert_success
  assert_file_contains "$rc" "export HELLO=WORLD # wizardry: summon"
}

test_adds_and_readds_block_spell_idempotently() {
  rc="$WIZARDRY_TMPDIR/block_rc"
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell portal add <<'EOF'
echo first
echo second
EOF
  assert_success
  first="$(cat "$rc")"

  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell portal add <<'EOF'
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
  run_spell "spells/spellcraft/learn" --rc-file "$missing" --spell phantom remove
  assert_failure && assert_error_contains "cannot remove from missing file"
}

test_remove_cleans_block() {
  rc="$WIZARDRY_TMPDIR/cleanup_rc"
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell vanish add <<'EOF'
echo vanish
echo more
EOF
  assert_success
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell vanish remove
  assert_success
  [ ! -s "$rc" ] || { TEST_FAILURE_REASON="expected file empty after remove"; return 1; }
}

test_status_reflects_presence() {
  rc="$WIZARDRY_TMPDIR/status_rc"
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell statuser status
  assert_failure

  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell statuser add <<'EOF'
echo status
EOF
  assert_success
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell statuser status
  assert_success
}

run_test_case "learn prints usage" test_help
run_test_case "learn errors without required arguments" test_missing_args
run_test_case "learn rejects invalid spell names" test_rejects_invalid_name
run_test_case "learn adds inline spell content" test_adds_inline_spell
run_test_case "learn adds blocks idempotently" test_adds_and_readds_block_spell_idempotently
run_test_case "learn fails to remove missing files" test_remove_reports_missing_file
run_test_case "learn removes previously added blocks" test_remove_cleans_block
run_test_case "learn status tracks presence" test_status_reflects_presence
finish_tests
