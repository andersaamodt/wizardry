#!/bin/sh
# Tests for the 'disambiguate' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_disambiguate_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/disambiguate" ]
}

test_disambiguate_no_args_succeeds() {
  run_spell spells/.imps/lex/disambiguate
  assert_success || return 1
}

test_disambiguate_runs_single_command() {
  run_spell spells/.imps/lex/disambiguate echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

test_disambiguate_finds_wizardry_spell_portably() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/wizardry/spells/test" "$tmp/spellbook"

  cat > "$tmp/wizardry/spells/test/hello" <<'EOF'
#!/bin/sh
printf 'wizardry spell ran: [%s]\n' "$*"
EOF
  chmod +x "$tmp/wizardry/spells/test/hello"

  WIZARDRY_DIR="$tmp/wizardry" SPELLBOOK_DIR="$tmp/spellbook" \
    run_spell spells/.imps/lex/disambiguate hello arg

  assert_success || return 1
  assert_output_contains "wizardry spell ran: [arg]" || return 1
}

test_disambiguate_handles_colon_in_spell_path() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/wizardry/spells/a:b" "$tmp/spellbook"

  cat > "$tmp/wizardry/spells/a:b/hello" <<'EOF'
#!/bin/sh
printf 'colon spell ran: [%s]\n' "$*"
EOF
  chmod +x "$tmp/wizardry/spells/a:b/hello"

  WIZARDRY_DIR="$tmp/wizardry" SPELLBOOK_DIR="$tmp/spellbook" \
    run_spell spells/.imps/lex/disambiguate hello arg

  assert_success || return 1
  assert_output_contains "colon spell ran: [arg]" || return 1
}

test_disambiguate_rejects_path_shaped_command_names() {
  tmp=$(make_tempdir)
  spellbook="$tmp/spellbook"
  mkdir -p "$spellbook/.disambiguations"
  printf '%s\n' "/missing-command" > "$spellbook/escape"

  SPELLBOOK_DIR="$spellbook" run_spell spells/.imps/lex/disambiguate ../escape

  assert_failure || return 1
  assert_error_contains "invalid command name" || return 1
  if [ ! -f "$spellbook/escape" ]; then
    TEST_FAILURE_REASON="disambiguate removed a file outside .disambiguations"
    return 1
  fi
}

run_test_case "disambiguate is executable" test_disambiguate_is_executable
run_test_case "disambiguate with no args succeeds" test_disambiguate_no_args_succeeds
run_test_case "disambiguate runs single command" test_disambiguate_runs_single_command
run_test_case "disambiguate finds wizardry spell portably" test_disambiguate_finds_wizardry_spell_portably
run_test_case "disambiguate handles colon in spell path" test_disambiguate_handles_colon_in_spell_path
run_test_case "disambiguate rejects path-shaped command names" test_disambiguate_rejects_path_shaped_command_names

finish_tests
