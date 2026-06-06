#!/bin/sh
# Ensure test-bootstrap exposes expected testing primitives

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_exports_find_repo_root() {
  root=$(find_repo_root)
  [ -n "$root" ] && [ -d "$root/.tests" ] && [ -d "$root/spells" ]
}

test_exports_run_spell() {
  run_spell spells/.imps/out/ok
  assert_success
}

test_skip_marks_case_skipped() {
  test_skip "bootstrap skip reason"
}

test_bootstrap_loads_invoke_without_warning() {
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/source-bootstrap.sh" << EOF
#!/bin/sh
. "$ROOT_DIR/spells/.imps/test/test-bootstrap"
printf 'WIZARDRY_INVOKED=%s\n' "\${WIZARDRY_INVOKED-}"
EOF
  chmod +x "$tmpdir/source-bootstrap.sh"

  run_cmd sh "$tmpdir/source-bootstrap.sh"
  assert_success || return 1
  assert_output_contains "WIZARDRY_INVOKED=1" || return 1
  case "$ERROR" in
    *"invoke-wizardry failed to load in test-bootstrap"*)
      TEST_FAILURE_REASON="test-bootstrap emitted stale invoke-wizardry warning"
      return 1
      ;;
  esac
}

run_test_case "test-bootstrap finds repository root" test_exports_find_repo_root
run_test_case "test-bootstrap exports run_spell helper" test_exports_run_spell
run_test_case "test-bootstrap test_skip marks case skipped" test_skip_marks_case_skipped
run_test_case "test-bootstrap loads invoke-wizardry without warning" test_bootstrap_loads_invoke_without_warning

finish_tests
