#!/bin/sh
# Behavioral cases (derived from --help):
# - decorate prints usage
# - decorate fails when enchant is unavailable
# - decorate fails for missing path
# - decorate fails for empty description
# - decorate applies description to current directory
# - decorate applies description to specified path
# - decorate accepts description as argument

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_stub_dir() {
  dir=$(make_tempdir)
  printf '%s\n' "$dir"
}

test_help() {
  run_spell "spells/mud/decorate" --help
  assert_success && assert_output_contains "Usage: decorate"
}

test_missing_enchant() {
  stub=$(make_stub_dir)
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" run_spell "spells/mud/decorate"
  assert_failure && assert_error_contains "decorate: enchant spell is missing."
}

test_missing_path() {
  stub=$(make_stub_dir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub/enchant"
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" run_spell "spells/mud/decorate" "/nonexistent/path" "description"
  assert_failure && assert_error_contains "path does not exist"
}

test_empty_description() {
  stub=$(make_stub_dir)
  target=$(make_tempdir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub/enchant"
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" run_spell "spells/mud/decorate" "$target" ""
  assert_failure && assert_error_contains "description cannot be empty"
}

test_decorates_with_description() {
  stub=$(make_stub_dir)
  target=$(make_tempdir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/decorate.called"
exit 0
EOF
  chmod +x "$stub/enchant"
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" run_spell "spells/mud/decorate" "$target" "A mystical chamber"
  assert_success && assert_output_contains "decorated with the description"
  called=$(cat "$WIZARDRY_TMPDIR/decorate.called")
  # Check that enchant was called with correct arguments
  case "$called" in
    *"description"*"A mystical chamber"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="unexpected enchant call: $called"
      return 1
      ;;
  esac
}

test_decorates_current_directory() {
  stub=$(make_stub_dir)
  target=$(make_tempdir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/decorate.called"
exit 0
EOF
  chmod +x "$stub/enchant"
  RUN_CMD_WORKDIR="$target" PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" run_spell "spells/mud/decorate" "." "The entrance hall"
  assert_success
  called=$(cat "$WIZARDRY_TMPDIR/decorate.called")
  # Check that the target path and description are in the call
  case "$called" in
    *"description"*"The entrance hall"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="unexpected enchant call: $called"
      return 1
      ;;
  esac
}

test_reports_enchant_failure() {
  stub=$(make_stub_dir)
  target=$(make_tempdir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$stub/enchant"
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" run_spell "spells/mud/decorate" "$target" "description"
  assert_failure && assert_error_contains "failed to apply description"
}

run_test_case "decorate prints usage" test_help
run_test_case "decorate fails when enchant is missing" test_missing_enchant
run_test_case "decorate fails for missing path" test_missing_path
run_test_case "decorate fails for empty description" test_empty_description
run_test_case "decorate applies description successfully" test_decorates_with_description
run_test_case "decorate works with current directory" test_decorates_current_directory
run_test_case "decorate reports enchant failure" test_reports_enchant_failure
finish_tests
