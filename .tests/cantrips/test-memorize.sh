#!/bin/sh
# Behavior from --help: memorize spells to the Cast menu.

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

tabbed() {
  # NAME<TAB>NAME (spell name is used as both name and command)
  printf '%s\t%s' "$1" "$1"
}

cast_env() {
  dir=$(mktemp -d "${WIZARDRY_TMPDIR}/cast.XXXXXX")
  mkdir -p "$dir"
  printf 'WIZARDRY_CAST_DIR=%s' "$dir"
}

run_memorize() {
  env_var=$1
  shift
  run_cmd env "$env_var" "$ROOT_DIR/spells/cantrips/memorize" "$@"
}

normalize_output() {
  printf '%s' "$OUTPUT" | tr '\n' '|'
}

memorizes_and_lists_entries() {
  env_var=$(cast_env)
  run_memorize "$env_var" blink
  [ "$STATUS" -eq 0 ] || return 1

  run_memorize "$env_var" list
  expected=$(tabbed "blink")
  case "$(normalize_output)" in
    "$expected"|"$expected|") : ;; 
    *) TEST_FAILURE_REASON="unexpected list output: $OUTPUT"; return 1 ;;
  esac
}

pushes_updates_to_front() {
  env_var=$(cast_env)
  run_memorize "$env_var" blink
  run_memorize "$env_var" gust
  run_memorize "$env_var" blink
  run_memorize "$env_var" list
  first_line=$(printf '%s' "$OUTPUT" | head -n1)
  expected=$(printf 'blink\t%s' "blink")
  [ "$first_line" = "$expected" ] || { TEST_FAILURE_REASON="expected blink to be first"; return 1; }
}

prints_cast_path() {
  env_var=$(cast_env)
  file=${env_var#*=}/.memorized
  run_memorize "$env_var" path
  [ "$STATUS" -eq 0 ] || return 1
  [ "$OUTPUT" = "$file" ] || { TEST_FAILURE_REASON="unexpected path output"; return 1; }
}

rejects_invalid_args() {
  env_var=$(cast_env)
  run_memorize "$env_var" "bad name"
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected invalid name failure"; return 1; }

  run_memorize "$env_var" list extra
  [ "$STATUS" -ne 0 ] || { TEST_FAILURE_REASON="expected usage failure"; return 1; }
}

writes_scripts_into_cast_dir() {
  env_var=$(cast_env)
  cast_dir=${env_var#*=}
  run_memorize "$env_var" spark
  [ -x "$cast_dir/spark" ] || { TEST_FAILURE_REASON="cast spell wrapper missing"; return 1; }
  # The wrapper should run "spark" (which is the spell name)
}

run_test_case "memorizes and lists entries" memorizes_and_lists_entries
run_test_case "pushes updates to the front" pushes_updates_to_front
run_test_case "prints cast path" prints_cast_path
run_test_case "rejects invalid arguments" rejects_invalid_args
run_test_case "writes scripts into cast dir" writes_scripts_into_cast_dir

shows_help() {
  run_spell spells/cantrips/memorize --help
  true
}

run_test_case "memorize shows help" shows_help

finish_tests
