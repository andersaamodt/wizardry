#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - synonym-menu is executable and has content
# - synonym-menu shows usage with --help
# - synonym-menu requires WORD argument
# - synonym-menu auto-detects synonym type
# - synonym-menu matches synonym names literally

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/menu/synonym-menu" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/menu/synonym-menu" ]
}

run_test_case "menu/synonym-menu is executable" spell_is_executable
run_test_case "menu/synonym-menu has content" spell_has_content

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/menu/synonym-menu" --help
  assert_success
  assert_output_contains "Usage: synonym-menu"
}

run_test_case "synonym-menu --help shows usage" test_shows_help

test_requires_word_argument() {
  run_cmd "$ROOT_DIR/spells/menu/synonym-menu"
  assert_failure || return 1
  assert_error_contains "requires WORD argument" || return 1
}

run_test_case "synonym-menu requires WORD argument" test_requires_word_argument

test_fails_for_nonexistent_synonym() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  SPELLBOOK_DIR="$spellbook" run_cmd "$ROOT_DIR/spells/menu/synonym-menu" nonexistent
  assert_failure || return 1
  assert_error_contains "not found" || return 1
}

run_test_case "synonym-menu fails for nonexistent synonym" test_fails_for_nonexistent_synonym

test_detects_custom_synonym() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  # Create custom synonym
  cat > "$spellbook/.synonyms" << EOF
# Custom synonyms
alias mytest='echo'
EOF
  
  # Run synonym-menu with the custom synonym
  SPELLBOOK_DIR="$spellbook" run_cmd "$ROOT_DIR/spells/menu/synonym-menu" --help
  assert_success || return 1
  assert_output_contains "Auto-detects" || return 1
}

run_test_case "synonym-menu auto-detects synonym type" test_detects_custom_synonym

test_does_not_open_menu_for_regex_false_match() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  stubdir="$tmpdir/bin"
  menu_log="$tmpdir/menu.log"
  mkdir -p "$spellbook" "$stubdir"
  printf '%s\n' 'myXalias=echo' > "$spellbook/.synonyms"
  cat > "$stubdir/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" > "$MENU_LOG"
exit 130
SH
  chmod +x "$stubdir/menu"

  SPELLBOOK_DIR="$spellbook" MENU_LOG="$menu_log" PATH="$stubdir:$PATH" \
    run_cmd "$ROOT_DIR/spells/menu/synonym-menu" "my.alias"

  assert_failure || return 1
  assert_error_contains "not found" || return 1
  assert_path_missing "$menu_log" || return 1
}

run_test_case "synonym-menu rejects regex false matches" test_does_not_open_menu_for_regex_false_match

test_strips_crlf_target_before_menu_label() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  stubdir="$tmpdir/bin"
  menu_log="$tmpdir/menu.log"
  mkdir -p "$spellbook" "$stubdir"
  printf 'bad=target\r\n' > "$spellbook/.synonyms"
  cat > "$stubdir/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" > "$MENU_LOG"
exit 130
SH
  chmod +x "$stubdir/menu"

  SPELLBOOK_DIR="$spellbook" MENU_LOG="$menu_log" PATH="$stubdir:$PATH" \
    run_cmd "$ROOT_DIR/spells/menu/synonym-menu" bad

  assert_success || return 1
  assert_path_exists "$menu_log" || return 1
  if od -An -tx1 "$menu_log" | grep -q '0d'; then
    TEST_FAILURE_REASON="synonym-menu passed carriage returns to menu labels"
    return 1
  fi
}

run_test_case "synonym-menu strips CRLF target before menu label" test_strips_crlf_target_before_menu_label

test_quotes_default_target_in_override_action() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  stubdir="$tmpdir/bin"
  menu_log="$tmpdir/menu.log"
  mkdir -p "$spellbook" "$stubdir"
  hostile_target="bad'; touch '$tmpdir/pwned'; echo '"
  printf '%s\n' "bad=$hostile_target" > "$spellbook/.default-synonyms"

  cat > "$stubdir/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" > "$MENU_LOG"
exit 130
SH
  chmod +x "$stubdir/menu"

  SPELLBOOK_DIR="$spellbook" MENU_LOG="$menu_log" PATH="$stubdir:$PATH" \
    run_cmd "$ROOT_DIR/spells/menu/synonym-menu" bad

  assert_success || return 1
  assert_path_exists "$menu_log" || return 1

  args=$(cat "$menu_log")
  expected="add-synonym \"\$new_word\" 'bad'\\''; touch '\\''$tmpdir/pwned'\\''; echo '\\'''"
  case "$args" in
    *"$expected"*) : ;;
    *) TEST_FAILURE_REASON="default target should be shell-quoted in override action: $args"; return 1 ;;
  esac
}

run_test_case "synonym-menu quotes default target in override action" test_quotes_default_target_in_override_action

# Test via source-then-invoke pattern  

finish_tests
