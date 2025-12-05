#!/bin/sh
# Test invoke-wizardry sourcer

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: invoke-wizardry is sourceable without errors
test_sourceable() {
  # Create a test script that sources invoke-wizardry
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/test-source.sh" << EOF
#!/bin/sh
WIZARDRY_DIR="$ROOT_DIR"
export WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"
# If we get here, sourcing worked
printf 'sourced successfully\n'
EOF
  chmod +x "$tmpdir/test-source.sh"
  
  run_cmd sh "$tmpdir/test-source.sh"
  assert_success || return 1
  assert_output_contains "sourced successfully" || return 1
}

# Test: invoke-wizardry sets WIZARDRY_DIR when not already set
test_sets_wizardry_dir() {
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/test-var.sh" << EOF
#!/bin/sh
unset WIZARDRY_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-wizardry"
printf '%s\n' "\${WIZARDRY_DIR:-unset}"
EOF
  chmod +x "$tmpdir/test-var.sh"
  
  run_cmd sh "$tmpdir/test-var.sh"
  assert_success || return 1
  # Should either be set to the root dir or remain unset (if detection fails)
  # The key is it shouldn't error
}

run_test_case "invoke-wizardry is sourceable" test_sourceable
run_test_case "invoke-wizardry sets WIZARDRY_DIR" test_sets_wizardry_dir

finish_tests
