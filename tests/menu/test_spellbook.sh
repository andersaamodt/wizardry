#!/bin/sh
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/../lib/test_common.sh"

make_stub_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/spellbook.XXXXXX") || exit 1
  printf '%s\n' "$dir"
}

write_spellbook_store_stub() {
  dir=$1
  cat >"$dir/spellbook-store" <<'STUB'
#!/bin/sh
case "$1" in
  list)
    printf '%s' "${SPELLBOOK_STORE_LIST:-}"
    ;;
  remove)
    printf "removed %s\n" "$2"
    ;;
  *) exit 1 ;;
esac
STUB
  chmod +x "$dir/spellbook-store"
}

write_require_command_stub() {
  dir=$1
  cat >"$dir/require-command" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$dir/require-command"
}

write_menu_stub() {
  dir=$1
  cat >"$dir/menu" <<'STUB'
#!/bin/sh
exit ${MENU_EXIT_STATUS:-0}
STUB
  chmod +x "$dir/menu"
}

run_with_stubs() {
  stub_dir=$1
  shift
  PATH="$stub_dir:$PATH" "$@"
}

test_errors_when_helper_missing() {
  stub_dir=$(make_stub_dir)
  PATH="$stub_dir:/usr/bin:/bin" run_spell "spells/menu/spellbook"
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"spellbook-store helper is missing"*) : ;; 
    *) TEST_FAILURE_REASON="helper missing warning not shown"; return 1 ;;
  esac
}

test_lists_entries() {
  stub_dir=$(make_stub_dir)
  write_spellbook_store_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  SPELLBOOK_STORE_LIST=$'foo\tbar\n' run_with_stubs "$stub_dir" run_spell "spells/menu/spellbook" --list
  assert_success && assert_output_contains "foo\tbar"
}

test_forget_removes_entry() {
  stub_dir=$(make_stub_dir)
  write_spellbook_store_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  run_with_stubs "$stub_dir" run_spell "spells/menu/spellbook" --forget phoenix
  assert_success && assert_output_contains "Forgot 'phoenix'"
}

test_empty_spellbook_message() {
  stub_dir=$(make_stub_dir)
  write_spellbook_store_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  write_menu_stub "$stub_dir"
  SPELLBOOK_STORE_LIST="" MENU_EXIT_STATUS=113 run_with_stubs "$stub_dir" run_spell "spells/menu/spellbook"
  assert_success
  assert_output_contains "Your spellbook is empty"
  assert_output_contains "memorize alias"
}

run_test_case "spellbook fails when helper missing" test_errors_when_helper_missing
run_test_case "spellbook lists stored entries" test_lists_entries
run_test_case "spellbook forgets an entry" test_forget_removes_entry
run_test_case "spellbook reports empty spellbook" test_empty_spellbook_message

finish_tests
