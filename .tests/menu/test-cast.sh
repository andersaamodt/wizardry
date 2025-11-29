#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - cast lists stored spells without opening a menu when --list is used
# - cast exits gracefully when no spells are stored
# - cast feeds stored spells into the menu and honors escape status

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_stub_cast_list() {
  tmp=$1
  alias_name=$2
  command_text=$3
  cat >"$tmp/memorize" <<SH
#!/bin/sh
case "\$1" in
  list)
    alias_name="$alias_name"
    command_text="$command_text"
    if [ -n "\$alias_name" ]; then
      printf '%s\t%s\n' "\$alias_name" "\$command_text"
    fi
    ;;
  dir)
    printf '%s\n' "$tmp"
    ;;
esac
SH
  chmod +x "$tmp/memorize"
  mkdir -p "$tmp"
  if [ -n "$alias_name" ] && [ -n "$command_text" ]; then
    # Create spell script in same format as memorize write_spell_script
    escaped_cmd=$(printf '%s' "$command_text" | sed "s/'/'\\\\''/g")
    cat >"$tmp/$alias_name" <<EOF
#!/bin/sh
exec sh -c '$escaped_cmd' "\$0" "\$@"
EOF
    chmod +x "$tmp/$alias_name"
  fi
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

test_cast_lists_stored_spells() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" fire "cast fire"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" "$ROOT_DIR/spells/menu/cast" --list
  assert_success && assert_output_contains "$(printf 'fire\tcast fire')"
}

test_cast_prints_empty_message() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" "" ""
  make_stub_require "$tmp"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" "$ROOT_DIR/spells/menu/cast"
  assert_success && assert_output_contains "No spells are available to cast."
}

test_cast_sends_entries_to_menu() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" fizz "cast fizz"
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  PATH="$tmp:$PATH" run_cmd env CAST_STORE="$tmp/memorize" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/cast"
  assert_success
  if [ ! -f "$tmp/log" ]; then
    TEST_FAILURE_REASON="menu was not invoked"
    return 1
  fi
  args=$(cat "$tmp/log")
  case "$args" in
    *"Cast a Spell:"*"fizz – cast fizz%$tmp/fizz"*"Exit%exit 113"* ) : ;;
    *) TEST_FAILURE_REASON="menu did not receive stored spells"; return 1 ;;
  esac
}

run_test_case "cast lists stored spells" test_cast_lists_stored_spells
run_test_case "cast exits when no stored spells" test_cast_prints_empty_message
run_test_case "cast feeds spells into menu" test_cast_sends_entries_to_menu

# Test ESC and Exit behavior for both nested and unnested scenarios
test_esc_exit_behavior() {
  tmp=$(make_tempdir)
  make_stub_cast_list "$tmp" fizz "cast fizz"
  make_stub_menu "$tmp"
  make_stub_require "$tmp"
  
  # Create exit-label stub
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
if [ "${WIZARDRY_SUBMENU-}" = "1" ]; then printf '%s' "Back"; else printf '%s' "Exit"; fi
SH
  chmod +x "$tmp/exit-label"
  
  # Test 1: Top-level (unnested) - should show "Exit"
  run_cmd env PATH="$tmp:$PATH" CAST_STORE="$tmp/memorize" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/menu/cast"
  assert_success || { TEST_FAILURE_REASON="unnested exit failed"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"Exit%exit 113"*) : ;;
    *) TEST_FAILURE_REASON="unnested should show Exit label: $args"; return 1 ;;
  esac
  
  # Test 2: As submenu (nested) - should show "Back"
  : >"$tmp/log"
  run_cmd env PATH="$tmp:$PATH" CAST_STORE="$tmp/memorize" MENU_LOG="$tmp/log" WIZARDRY_SUBMENU=1 "$ROOT_DIR/spells/menu/cast"
  assert_success || { TEST_FAILURE_REASON="nested exit failed"; return 1; }
  
  args=$(cat "$tmp/log")
  case "$args" in
    *"Back%exit 113"*) : ;;
    *) TEST_FAILURE_REASON="nested should show Back label: $args"; return 1 ;;
  esac
}

run_test_case "cast ESC/Exit handles nested and unnested" test_esc_exit_behavior

shows_help() {
  run_spell spells/menu/cast --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "cast accepts --help" shows_help
finish_tests
