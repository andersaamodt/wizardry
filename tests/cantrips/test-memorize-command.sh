#!/bin/sh
# Behavior from --help: manage the prioritized cast list.

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

tabbed() {
  printf 'blink\t%s' "$1"
}

cast_env() {
  dir=$(mktemp -d "${WIZARDRY_TMPDIR}/cast.XXXXXX")
  mkdir -p "$dir"
  printf 'WIZARDRY_CAST_DIR=%s' "$dir"
}

run_store() {
  env_var=$1
  shift
  run_cmd env "$env_var" "$ROOT_DIR/spells/cantrips/memorize-command" "$@"
}

normalize_output() {
  printf '%s' "$OUTPUT" | tr '\n' '|'
}

adds_and_lists_entries() {
  env_var=$(cast_env)
  run_store "$env_var" add blink "echo cast"
  [ "$STATUS" -eq 0 ] || return 1

  run_store "$env_var" list
  expected=$(tabbed "echo cast")
  case "$(normalize_output)" in
    "$expected"|"$expected|") : ;; 
    *) TEST_FAILURE_REASON="unexpected list output: $OUTPUT"; return 1 ;;
  esac
}

pushes_updates_to_front() {
  env_var=$(cast_env)
  run_store "$env_var" add blink "echo one"
  run_store "$env_var" add gust "echo two"
  run_store "$env_var" add blink "echo three"
  run_store "$env_var" list
  first_line=$(printf '%s' "$OUTPUT" | head -n1)
  expected=$(printf 'blink\t%s' "echo three")
  [ "$first_line" = "$expected" ] || { TEST_FAILURE_REASON="expected blink to be first"; return 1; }
}

removes_entries_and_errors_when_missing() {
  env_var=$(cast_env)
  run_store "$env_var" add blink "echo cast"
  run_store "$env_var" remove blink
  [ "$STATUS" -eq 0 ] || return 1

  run_store "$env_var" remove blink
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected failure for missing"; return 1; }
}

prints_cast_path() {
  env_var=$(cast_env)
  file=${env_var#*=}/.memorized
  run_store "$env_var" path
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "$file" ] || { TEST_FAILURE_REASON="unexpected path output"; return 1; }
}

rejects_invalid_args() {
  env_var=$(cast_env)
  run_store "$env_var" add "bad name" "echo x"
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected invalid name failure"; return 1; }

  run_store "$env_var" add blink ""
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected empty command failure"; return 1; }

  run_store "$env_var" list extra
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected usage failure"; return 1; }
}

writes_scripts_into_cast_dir() {
  env_var=$(cast_env)
  cast_dir=${env_var#*=}
  run_store "$env_var" add spark "echo cast spark"
  [ -x "$cast_dir/spark" ] || { TEST_FAILURE_REASON="cast spell wrapper missing"; return 1; }
  script_output=$("$cast_dir/spark")
  [ "$script_output" = "cast spark" ] || { TEST_FAILURE_REASON="unexpected wrapper output"; return 1; }
}

run_test_case "adds and lists entries" adds_and_lists_entries
run_test_case "pushes updates to the front" pushes_updates_to_front
run_test_case "removes entries and errors when missing" removes_entries_and_errors_when_missing
run_test_case "prints cast path" prints_cast_path
run_test_case "rejects invalid arguments" rejects_invalid_args
run_test_case "writes scripts into cast dir" writes_scripts_into_cast_dir

shows_help() {
  run_spell spells/cantrips/memorize-command --help
  true
}

run_test_case "memorize-command shows help" shows_help

finish_tests
