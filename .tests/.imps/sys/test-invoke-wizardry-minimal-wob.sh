#!/bin/sh
# COMPILED_UNSUPPORTED: tests invoke-wizardry-minimal-wob which is wizardry bootstrap
# Test invoke-wizardry-minimal-wob sourcer

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_sourceable() {
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/test-source.sh" << SCRIPT_EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry-minimal-wob"
printf 'sourced successfully\n'
SCRIPT_EOF
  chmod +x "$tmpdir/test-source.sh"

  run_cmd sh "$tmpdir/test-source.sh"
  assert_success || return 1
  assert_output_contains "sourced successfully" || return 1
}

test_sets_command_not_found_handle_in_bash() {
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/test-cnf.sh" << SCRIPT_EOF
#!/bin/bash
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry-minimal-wob"
if type command_not_found_handle >/dev/null 2>&1; then
  printf 'cnf handler available\n'
fi
SCRIPT_EOF
  chmod +x "$tmpdir/test-cnf.sh"

  if command -v bash >/dev/null 2>&1; then
    run_cmd bash "$tmpdir/test-cnf.sh"
    assert_success || return 1
    assert_output_contains "cnf handler available" || return 1
  else
    skip_test "bash not available"
  fi
}

test_requires_valid_wizardry_dir() {
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/test-bad-dir.sh" << SCRIPT_EOF
#!/bin/sh
WIZARDRY_DIR="$tmpdir/nonexistent"
export WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry-minimal-wob"
SCRIPT_EOF
  chmod +x "$tmpdir/test-bad-dir.sh"

  run_cmd sh "$tmpdir/test-bad-dir.sh"
  assert_status 1 || return 1
  assert_error_contains "WIZARDRY_DIR not found" || return 1
}

run_test_case "invoke-wizardry-minimal-wob is sourceable" test_sourceable
# Test #2 removed: command_not_found_handle no longer used (glossary-based system instead)
run_test_case "invoke-wizardry-minimal-wob requires a valid wizardry dir" test_requires_valid_wizardry_dir

finish_tests
