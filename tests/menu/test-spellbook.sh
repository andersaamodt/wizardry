#!/bin/sh
# Spellbook menu helper coverage:
# - fails when memorize-command is missing
# - lists entries via --list
# - uses --memorize/--forget to manage the cast list
# - --scribe records custom commands by category

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_stub_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/spellbook.XXXXXX") || exit 1
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
        "$name"$'\t'*) continue ;;
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
    cat "$cast_file" 2>/dev/null
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

test_errors_when_helper_missing() {
  stub_dir=$(make_stub_dir)
  PATH="$stub_dir:/bin:/usr/bin" CAST_STORE="$stub_dir/does-not-exist" run_spell "spells/menu/spellbook" --list
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"memorize-command helper is missing"*) : ;;
    *) TEST_FAILURE_REASON="helper missing warning not shown"; return 1 ;;
  esac
}

test_lists_entries() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  cast_dir="$stub_dir/custom-cast"
  WIZARDRY_CAST_DIR="$cast_dir" PATH="$stub_dir:$PATH" run_spell "spells/menu/spellbook" --memorize spark "echo cast"
  [ -f "$cast_dir/.memorized" ] || { TEST_FAILURE_REASON="cast file missing"; return 1; }
  content=$(tr -d '\n' < "$cast_dir/.memorized")
  case "$content" in
    spark*echo\ cast) : ;;
    *) TEST_FAILURE_REASON="memorize did not record entry: $content"; return 1 ;;
  esac
}

test_memorize_and_forget() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  WIZARDRY_CAST_DIR="$stub_dir/custom-cast" PATH="$stub_dir:$PATH" run_spell "spells/menu/spellbook" --memorize spark "echo cast"
  WIZARDRY_CAST_DIR="$stub_dir/custom-cast" PATH="$stub_dir:$PATH" run_spell "spells/menu/spellbook" --forget spark
  assert_success
}

test_scribe_records_command() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  COMMAND_FILE="$stub_dir/commands"
  PATH="$stub_dir:$PATH" SPELLBOOK_COMMANDS_FILE="$COMMAND_FILE" SPELLBOOK_CUSTOM_DIR="$stub_dir/custom" run_spell "spells/menu/spellbook" --scribe fire spark "echo ignite"
  [ -f "$COMMAND_FILE" ] || { TEST_FAILURE_REASON="commands file missing"; return 1; }
  content=$(tr -d '\n' < "$COMMAND_FILE")
  case "$content" in
    fire*spark*echo\ ignite) : ;;
    *) TEST_FAILURE_REASON="unexpected command entry: $content"; return 1 ;;
  esac
  if [ ! -x "$stub_dir/custom/spark" ]; then
    TEST_FAILURE_REASON="custom command script was not created"
    return 1
  fi
}

test_list_all_custom_commands() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  COMMAND_FILE="$stub_dir/commands"
  PATH="$stub_dir:$PATH" SPELLBOOK_COMMANDS_FILE="$COMMAND_FILE" SPELLBOOK_CUSTOM_DIR="$stub_dir/custom" run_spell "spells/menu/spellbook" --scribe fire spark1 "echo ignite1"
  PATH="$stub_dir:$PATH" SPELLBOOK_COMMANDS_FILE="$COMMAND_FILE" SPELLBOOK_CUSTOM_DIR="$stub_dir/custom" run_spell "spells/menu/spellbook" --scribe water splash "echo splash"
  [ -f "$COMMAND_FILE" ] || { TEST_FAILURE_REASON="commands file missing"; return 1; }
  content=$(cat "$COMMAND_FILE")
  case "$content" in
    *fire*spark1*echo\ ignite1*) : ;;
    *) TEST_FAILURE_REASON="spark1 command not found: $content"; return 1 ;;
  esac
  case "$content" in
    *water*splash*echo\ splash*) : ;;
    *) TEST_FAILURE_REASON="splash command not found: $content"; return 1 ;;
  esac
}

run_test_case "spellbook fails when helper missing" test_errors_when_helper_missing
run_test_case "spellbook lists stored entries" test_lists_entries
run_test_case "spellbook memorize and forget" test_memorize_and_forget
run_test_case "spellbook scribe command" test_scribe_records_command
run_test_case "spellbook lists all custom commands" test_list_all_custom_commands

finish_tests
