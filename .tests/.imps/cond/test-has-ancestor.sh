#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_has_ancestor_detects_sh() {
  # We should always be running inside sh/bash/dash
  run_spell "spells/.imps/cond/has-ancestor" sh
  assert_success || return 1
}

test_has_ancestor_rejects_nonexistent() {
  # Should not detect a command that doesn't exist in ancestry
  run_spell "spells/.imps/cond/has-ancestor" nonexistent-xyz-command-99999
  assert_failure || return 1
}

test_has_ancestor_requires_argument() {
  # Should fail when no argument provided
  run_spell "spells/.imps/cond/has-ancestor"
  assert_failure || return 1
}

test_has_ancestor_from_subshell() {
  # Test that has-ancestor works from within a spawned process
  tmpdir=$(make_tempdir)
  tmpscript="$tmpdir/test_script.sh"
  cat > "$tmpscript" << SCRIPT
#!/bin/sh
# This script will be run by a specific shell command
"$ROOT_DIR/spells/.imps/cond/has-ancestor" sh
SCRIPT
  chmod +x "$tmpscript"
  
  # Run the script - it should detect sh in its ancestry
  if "$tmpscript"; then
    return 0
  else
    TEST_FAILURE_REASON="has-ancestor should have detected sh from subshell"
    return 1
  fi
}

run_test_case "has-ancestor detects sh" test_has_ancestor_detects_sh
run_test_case "has-ancestor rejects nonexistent command" test_has_ancestor_rejects_nonexistent
run_test_case "has-ancestor requires argument" test_has_ancestor_requires_argument
run_test_case "has-ancestor works from subshell" test_has_ancestor_from_subshell

finish_tests
