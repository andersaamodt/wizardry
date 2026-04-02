#!/bin/sh
# Behavioral cases:
# - browse-subpriorities shows usage
# - browse-subpriorities requires DIRECTORY
# - browse-subpriorities rejects missing directories
# - browse-subpriorities runs priorities in the target directory

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/priorities/browse-subpriorities" --help
  assert_success || return 1
  assert_output_contains "Usage: browse-subpriorities" || return 1
}

test_requires_directory() {
  run_spell "spells/priorities/browse-subpriorities"
  assert_failure || return 1
  assert_error_contains "DIRECTORY required" || return 1
}

test_rejects_missing_directory() {
  run_spell "spells/priorities/browse-subpriorities" /nope
  assert_failure || return 1
  assert_error_contains "not a directory" || return 1
}

test_runs_priorities_in_directory() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/project"
  cat >"$tmp/priorities" <<'SH'
#!/bin/sh
pwd >"$PWD_LOG"
SH
  chmod +x "$tmp/priorities"

  run_cmd env PATH="$tmp:$PATH" PWD_LOG="$tmp/log" \
    "$ROOT_DIR/spells/priorities/browse-subpriorities" "$tmp/project"
  assert_success || return 1
  assert_file_contains "$tmp/log" "$tmp/project"
}

run_test_case "browse-subpriorities shows usage" test_help
run_test_case "browse-subpriorities requires DIRECTORY" test_requires_directory
run_test_case "browse-subpriorities rejects missing directories" test_rejects_missing_directory
run_test_case "browse-subpriorities runs priorities in the directory" test_runs_priorities_in_directory

finish_tests
