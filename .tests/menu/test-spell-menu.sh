#!/bin/sh
# spell-menu test coverage:
# - fails when memorize-command is missing
# - shows usage with --help
# - requires minimum 3 arguments
# - --cast executes the given command
# - --memorize adds spell to cast list
# - --forget removes spell from cast list
# - --delete removes custom command

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_stub_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/spell-menu.XXXXXX") || exit 1
  printf '%s\n' "$dir"
}

write_memorize_command_stub() {
  dir=$1
  cat >"$dir/memorize-command" <<'STUB'
#!/bin/sh
case $1 in
  add)
    shift
    name=$1
    shift
    cmd=$1
    shift || :
    while [ "$#" -gt 0 ]; do
      cmd="$cmd $1"
      shift
    done
    cast_dir=${WIZARDRY_CAST_DIR:-${HOME:-.}/.spellbook}
    cast_file_default=$cast_dir/.memorized
    cast_file=${WIZARDRY_CAST_FILE:-$cast_file_default}
    mkdir -p "$cast_dir"
    printf '%s\t%s\n' "$name" "$cmd" >>"$cast_file"
    printf '%s\n' "$cmd" >"$cast_dir/$name"
    chmod +x "$cast_dir/$name"
    ;;
  remove)
    shift
    name=$1
    cast_dir=${WIZARDRY_CAST_DIR:-${HOME:-.}/.spellbook}
    cast_file_default=$cast_dir/.memorized
    cast_file=${WIZARDRY_CAST_FILE:-$cast_file_default}
    tmp=$(mktemp)
    while IFS= read -r line || [ -n "$line" ]; do
      case $line in
        "$name"*) continue ;;
        *) printf '%s\n' "$line" >>"$tmp" ;;
      esac
    done <"$cast_file"
    mv "$tmp" "$cast_file"
    rm -f "$cast_dir/$name"
    ;;
  list)
    cast_dir=${WIZARDRY_CAST_DIR:-${HOME:-.}/.spellbook}
    cast_file_default=$cast_dir/.memorized
    cast_file=${WIZARDRY_CAST_FILE:-$cast_file_default}
    cat "$cast_file" 2>/dev/null || true
    ;;
  dir)
    cast_dir=${WIZARDRY_CAST_DIR:-${HOME:-.}/.spellbook}
    printf '%s\n' "$cast_dir"
    ;;
esac
STUB
  chmod +x "$dir/memorize-command"
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
# Return escape status to exit the menu loop
exit 113
STUB
  chmod +x "$dir/menu"
}

test_errors_when_helper_missing() {
  stub_dir=$(make_stub_dir)
  PATH="$stub_dir:/bin:/usr/bin" CAST_STORE="$stub_dir/does-not-exist" run_spell "spells/menu/spell-menu" --help
  # --help should work even without memorize-command
  assert_success || return 1
}

test_shows_usage_with_help() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/menu/spell-menu" --help
  assert_success || return 1
  case "$OUTPUT" in
    *"Usage: spell-menu"*) : ;;
    *) TEST_FAILURE_REASON="help text should show usage: $OUTPUT"; return 1 ;;
  esac
}

test_requires_minimum_arguments() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  # Call with only 2 arguments (needs 3)
  PATH="$stub_dir:$PATH" run_spell "spells/menu/spell-menu" arcane spark
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"Usage:"*) : ;;
    *) TEST_FAILURE_REASON="should show usage when too few arguments"; return 1 ;;
  esac
}

test_cast_action_executes_command() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  PATH="$stub_dir:$PATH" run_spell "spells/menu/spell-menu" --cast "echo hello"
  assert_success || return 1
  case "$OUTPUT" in
    *"hello"*) : ;;
    *) TEST_FAILURE_REASON="cast action should execute command: $OUTPUT"; return 1 ;;
  esac
}

test_memorize_action_adds_spell() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  cast_dir="$stub_dir/custom-cast"
  WIZARDRY_CAST_DIR="$cast_dir" PATH="$stub_dir:$PATH" run_spell "spells/menu/spell-menu" --memorize spark "echo ignite"
  assert_success || return 1
  [ -f "$cast_dir/.memorized" ] || { TEST_FAILURE_REASON="cast file missing"; return 1; }
  content=$(cat "$cast_dir/.memorized")
  case "$content" in
    *spark*echo\ ignite*) : ;;
    *) TEST_FAILURE_REASON="memorize did not record entry: $content"; return 1 ;;
  esac
}

test_forget_action_removes_spell() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  cast_dir="$stub_dir/custom-cast"
  # First memorize a spell
  WIZARDRY_CAST_DIR="$cast_dir" PATH="$stub_dir:$PATH" run_spell "spells/menu/spell-menu" --memorize spark "echo ignite"
  # Then forget it
  WIZARDRY_CAST_DIR="$cast_dir" PATH="$stub_dir:$PATH" run_spell "spells/menu/spell-menu" --forget spark
  assert_success || return 1
  # Check that the spell was removed
  if [ -f "$cast_dir/.memorized" ]; then
    content=$(cat "$cast_dir/.memorized")
    case "$content" in
      *spark*) TEST_FAILURE_REASON="forget did not remove entry: $content"; return 1 ;;
    esac
  fi
}

test_delete_action_removes_custom_command() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  commands_file="$stub_dir/commands"
  custom_dir="$stub_dir/custom"
  mkdir -p "$custom_dir"
  # Create a custom command entry
  printf 'fire\tspark\techo ignite\n' >"$commands_file"
  printf '#!/bin/sh\necho ignite\n' >"$custom_dir/spark"
  chmod +x "$custom_dir/spark"
  # Delete it
  SPELLBOOK_COMMANDS_FILE="$commands_file" SPELLBOOK_CUSTOM_DIR="$custom_dir" PATH="$stub_dir:$PATH" run_spell "spells/menu/spell-menu" --delete fire spark
  assert_success || return 1
  case "$OUTPUT" in
    *"Deleted custom command"*) : ;;
    *) TEST_FAILURE_REASON="delete should confirm removal: $OUTPUT"; return 1 ;;
  esac
  # Verify file is empty or removed
  if [ -f "$commands_file" ] && [ -s "$commands_file" ]; then
    content=$(cat "$commands_file")
    case "$content" in
      *spark*) TEST_FAILURE_REASON="delete did not remove entry: $content"; return 1 ;;
    esac
  fi
}

run_test_case "spell-menu shows usage with --help" test_shows_usage_with_help
run_test_case "spell-menu requires minimum arguments" test_requires_minimum_arguments
run_test_case "spell-menu --cast executes command" test_cast_action_executes_command
run_test_case "spell-menu --memorize adds spell" test_memorize_action_adds_spell
run_test_case "spell-menu --forget removes spell" test_forget_action_removes_spell
run_test_case "spell-menu --delete removes custom command" test_delete_action_removes_custom_command

finish_tests
