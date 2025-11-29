#!/bin/sh
# Behavioral coverage for forget:
# - prints usage
# - removes a spell from the cast menu
# - fails when spell name is missing
# - fails when memorize helper is missing

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

reset_logs() {
  rm -f "$WIZARDRY_TMPDIR/spellbook.log"
}

test_help() {
  reset_logs
  run_spell "spells/spellcraft/forget" --help
  assert_success && assert_output_contains "Usage:"
}

test_forget_removes_spell() {
  reset_logs
  case_dir=$(make_tempdir)
  store="$case_dir/memorize"
  cat >"$store" <<'SCRIPT'
#!/bin/sh
printf '%s\n' "$*" >>"${WIZARDRY_TMPDIR}/spellbook.log"
SCRIPT
  chmod +x "$store"

  MEMORIZE_SPELL_HELPER="$store" run_spell "spells/spellcraft/forget" myspell

  assert_success
  assert_output_contains "Forgotten: myspell"
  assert_path_exists "$WIZARDRY_TMPDIR/spellbook.log"
  recorded=$(cat "$WIZARDRY_TMPDIR/spellbook.log")
  case "$recorded" in
    "remove myspell") : ;;
    *) TEST_FAILURE_REASON="unexpected spellbook invocation: $recorded"; return 1 ;;
  esac
}

test_forget_requires_name() {
  run_spell "spells/spellcraft/forget"
  assert_failure && assert_error_contains "spell name required"
}

test_forget_fails_when_helper_missing() {
  reset_logs
  missing="$(make_tempdir)/memorize"
  PATH=/usr/bin:/bin MEMORIZE_SPELL_HELPER="$missing" \
    run_spell "spells/spellcraft/forget" myspell
  assert_failure && assert_error_contains "memorize helper is unavailable"
}

run_test_case "forget prints usage" test_help
run_test_case "forget removes spell from cast menu" test_forget_removes_spell
run_test_case "forget requires spell name" test_forget_requires_name
run_test_case "forget fails when helper is missing" test_forget_fails_when_helper_missing

finish_tests
