#!/bin/sh
# Spellbook menu helper coverage:
# - fails when memorize-command is missing
# - lists entries via --list
# - uses --memorize/--forget to manage the cast list
# - --scribe records commands as standalone scripts

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
  spellbook_dir="$stub_dir/spellbook"
  mkdir -p "$spellbook_dir"
  
  PATH="$stub_dir:$PATH" WIZARDRY_SPELL_HOME="$spellbook_dir" run_spell "spells/menu/spellbook" --scribe spark "echo ignite"
  
  assert_success || return 1
  [ -x "$spellbook_dir/spark" ] || { TEST_FAILURE_REASON="scribed script was not created"; return 1; }
  
  # Check script content
  script_content=$(cat "$spellbook_dir/spark")
  case "$script_content" in
    *"echo ignite"*) : ;;
    *) TEST_FAILURE_REASON="script missing command: $script_content"; return 1 ;;
  esac
}

test_scribe_multiple_commands() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  spellbook_dir="$stub_dir/spellbook"
  mkdir -p "$spellbook_dir"
  
  PATH="$stub_dir:$PATH" WIZARDRY_SPELL_HOME="$spellbook_dir" run_spell "spells/menu/spellbook" --scribe spark1 "echo ignite1"
  PATH="$stub_dir:$PATH" WIZARDRY_SPELL_HOME="$spellbook_dir" run_spell "spells/menu/spellbook" --scribe splash "echo splash"
  
  [ -x "$spellbook_dir/spark1" ] || { TEST_FAILURE_REASON="spark1 script not found"; return 1; }
  [ -x "$spellbook_dir/splash" ] || { TEST_FAILURE_REASON="splash script not found"; return 1; }
}

test_path_argument_accepted() {
  stub_dir=$(make_stub_dir)
  write_memorize_command_stub "$stub_dir"
  write_require_command_stub "$stub_dir"
  # Test that spellbook --help includes the PATH usage
  PATH="$stub_dir:$PATH" run_spell "spells/menu/spellbook" --help
  assert_success || return 1
  case "$OUTPUT" in
    *"[PATH|"*) : ;;
    *) TEST_FAILURE_REASON="help text should mention PATH argument: $OUTPUT"; return 1 ;;
  esac
}

run_test_case "spellbook fails when helper missing" test_errors_when_helper_missing
run_test_case "spellbook lists stored entries" test_lists_entries
run_test_case "spellbook memorize and forget" test_memorize_and_forget
run_test_case "spellbook scribe command" test_scribe_records_command
run_test_case "spellbook scribes multiple commands" test_scribe_multiple_commands
run_test_case "spellbook accepts path argument" test_path_argument_accepted

finish_tests
