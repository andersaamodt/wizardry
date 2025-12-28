#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_in_ancestry_detects_sh() {
  # We should always be running inside sh/bash/dash
  run_spell "spells/.imps/cond/in-ancestry" sh
  assert_success || return 1
}

test_in_ancestry_rejects_nonexistent() {
  # Should not detect a command that doesn't exist in ancestry
  run_spell "spells/.imps/cond/in-ancestry" nonexistent-xyz-command-99999
  assert_failure || return 1
}

test_in_ancestry_requires_argument() {
  # Should fail when no argument provided
  run_spell "spells/.imps/cond/in-ancestry"
  assert_failure || return 1
}

test_in_ancestry_from_subshell() {
  # Test that in-ancestry works from within a spawned process
  tmpdir=$(make_tempdir)
  tmpscript="$tmpdir/test_script.sh"
  cat > "$tmpscript" << SCRIPT
#!/bin/sh
# This script will be run by a specific shell command
"$ROOT_DIR/spells/.imps/cond/in-ancestry" sh
SCRIPT
  chmod +x "$tmpscript"
  
  # Run the script - it should detect sh in its ancestry
  if "$tmpscript"; then
    return 0
  else
    TEST_FAILURE_REASON="in-ancestry should have detected sh from subshell"
    return 1
  fi
}

run_test_case "in-ancestry detects sh" test_in_ancestry_detects_sh
run_test_case "in-ancestry rejects nonexistent command" test_in_ancestry_rejects_nonexistent
run_test_case "in-ancestry requires argument" test_in_ancestry_requires_argument
run_test_case "in-ancestry works from subshell" test_in_ancestry_from_subshell

finish_tests
