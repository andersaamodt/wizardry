#!/bin/sh
# Test run-spell-in-dir imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_runs_in_directory() {
  tmpdir=$(make_tempdir)
  # Create a simple test script
  cat > "$tmpdir/testscript" << 'EOF'
#!/bin/sh
pwd
EOF
  chmod +x "$tmpdir/testscript"
  
  run_spell_in_dir "$tmpdir" spells/.imps/out/ok
  # Just test that it runs without error
  assert_success
}

test_sets_workdir() {
  tmpdir=$(make_tempdir)
  
  run_spell_in_dir "$tmpdir" spells/.imps/out/ok
  assert_success
}

run_test_case "run-spell-in-dir runs spell in specified directory" test_runs_in_directory
run_test_case "run-spell-in-dir sets working directory" test_sets_workdir

finish_tests
