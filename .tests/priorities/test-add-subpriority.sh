#!/bin/sh
# Behavioral cases:
# - add-subpriority shows usage
# - add-subpriority requires DIRECTORY
# - add-subpriority rejects missing directories
# - add-subpriority runs prioritize --interactive --yes in the target directory

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/priorities/add-subpriority" --help
  assert_success || return 1
  assert_output_contains "Usage: add-subpriority" || return 1
}

test_requires_directory() {
  run_spell "spells/priorities/add-subpriority"
  assert_failure || return 1
  assert_error_contains "DIRECTORY required" || return 1
}

test_rejects_missing_directory() {
  run_spell "spells/priorities/add-subpriority" /nope
  assert_failure || return 1
  assert_error_contains "not a directory" || return 1
}

test_runs_prioritize_in_directory() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/project"
  cat >"$tmp/prioritize" <<'SH'
#!/bin/sh
printf '%s\n' "$PWD" >"$PWD_LOG"
printf '%s\n' "$*" >>"$PWD_LOG"
SH
  chmod +x "$tmp/prioritize"

  run_cmd env PATH="$tmp:$PATH" PWD_LOG="$tmp/log" \
    "$ROOT_DIR/spells/priorities/add-subpriority" "$tmp/project"
  assert_success || return 1
  assert_file_contains "$tmp/log" "$tmp/project"
  assert_file_contains "$tmp/log" "--interactive --yes"
}

run_test_case "add-subpriority shows usage" test_help
run_test_case "add-subpriority requires DIRECTORY" test_requires_directory
run_test_case "add-subpriority rejects missing directories" test_rejects_missing_directory
run_test_case "add-subpriority runs prioritize in the directory" test_runs_prioritize_in_directory

finish_tests
