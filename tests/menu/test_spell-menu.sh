#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - spell-menu lists stored spells without opening a menu when --list is used
# - spell-menu exits gracefully when no spells are stored
# - spell-menu feeds stored spells into the menu and honors escape status

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

make_stub_spellbook() {
  tmp=$1
  alias_name=$2
  command_text=$3
  cat >"$tmp/spellbook-store" <<SH
#!/bin/sh
if [ "\$1" = list ]; then
  alias_name="$alias_name"
  command_text="$command_text"
  if [ -n "\$alias_name" ]; then
    printf '%s\t%s\n' "\$alias_name" "\$command_text"
  fi
fi
SH
  chmod +x "$tmp/spellbook-store"
}

make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
exit 113
SH
  chmod +x "$tmp/menu"
}

make_stub_require() {
  tmp=$1
  cat >"$tmp/require-command" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$tmp/require-command"
}

test_spell_menu_lists_stored_spells() {
  tmp=$(make_tempdir)
  make_stub_spellbook "$tmp" fire "cast fire"
  PATH="$tmp:$PATH" run_cmd env SPELLBOOK_STORE="$tmp/spellbook-store" "$ROOT_DIR/spells/menu/spell-menu" --list
  assert_success && assert_output_contains "$(printf 'fire\tcast fire')"
}

test_spell_menu_prints_empty_message() {
  tmp=$(make_tempdir)
  make_stub_spellbook "$tmp" "" ""
  make_stub_require "$tmp"
  PATH="$tmp:$PATH" run_cmd env SPELLBOOK_STORE="$tmp/spellbook-store" "$ROOT_DIR/spells/menu/spell-menu"
  assert_success && assert_output_contains "No spells are available to cast."
}

test_spell_menu_sends_entries_to_menu() {
  tmp=$(make_tempdir)
  make_stub_spellbook "$tmp" fizz "cast fizz"
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  PATH="$tmp:$PATH" run_cmd env SPELLBOOK_STORE="$tmp/spellbook-store" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/spell-menu"
  assert_success
  if [ ! -f "$tmp/log" ]; then
    TEST_FAILURE_REASON="menu was not invoked"
    return 1
  fi
  args=$(cat "$tmp/log")
  case "$args" in
    *"Cast a Spell:"*"fizz – cast fizz%cast fizz"*"Exit%kill -2"* ) : ;; 
    *) TEST_FAILURE_REASON="menu did not receive stored spells"; return 1 ;;
  esac
}

run_test_case "spell-menu lists stored spells" test_spell_menu_lists_stored_spells
run_test_case "spell-menu exits when no stored spells" test_spell_menu_prints_empty_message
run_test_case "spell-menu feeds spells into menu" test_spell_menu_sends_entries_to_menu
finish_tests
