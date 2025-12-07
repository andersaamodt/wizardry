#!/bin/sh
# Behavioral cases (derived from --help):
# - decorate prints usage
# - decorate fails when enchant is unavailable
# - decorate fails when no valid path found among arguments
# - decorate fails for empty description
# - decorate applies description to current directory
# - decorate applies description to specified path
# - decorate accepts description as argument
# - decorate works with reversed argument order (description first, path second)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_dir() {
  dir=$(_make_tempdir)
  printf '%s\n' "$dir"
}

test_help() {
  _run_spell "spells/mud/decorate" --help
  _assert_success && _assert_output_contains "Usage: decorate"
}

test_missing_enchant() {
  stub=$(make_stub_dir)
  PATH="$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" _run_spell "spells/mud/decorate"
  _assert_failure && _assert_error_contains "decorate: enchant spell is missing."
}

test_no_valid_path() {
  stub=$(make_stub_dir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub/enchant"
  PATH="$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" _run_spell "spells/mud/decorate" "/nonexistent/path" "description"
  _assert_failure && _assert_error_contains "no valid path found"
}

test_empty_description() {
  stub=$(make_stub_dir)
  target=$(_make_tempdir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub/enchant"
  PATH="$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" _run_spell "spells/mud/decorate" "$target" ""
  _assert_failure && _assert_error_contains "description cannot be empty"
}

test_decorates_with_description() {
  stub=$(make_stub_dir)
  target=$(_make_tempdir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/decorate.called"
exit 0
EOF
  chmod +x "$stub/enchant"
  PATH="$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" _run_spell "spells/mud/decorate" "$target" "A mystical chamber"
  _assert_success && _assert_output_contains "decorated with the description"
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

test_decorates_with_reversed_args() {
  stub=$(make_stub_dir)
  target=$(_make_tempdir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/decorate.called"
exit 0
EOF
  chmod +x "$stub/enchant"
  # Pass description first, then path
  PATH="$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" _run_spell "spells/mud/decorate" "A secret alcove" "$target"
  _assert_success && _assert_output_contains "decorated with the description"
  called=$(cat "$WIZARDRY_TMPDIR/decorate.called")
  # Check that enchant was called with correct arguments
  case "$called" in
    *"description"*"A secret alcove"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="unexpected enchant call: $called"
      return 1
      ;;
  esac
}

test_decorates_current_directory_with_description_only() {
  stub=$(make_stub_dir)
  target=$(_make_tempdir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/decorate.called"
exit 0
EOF
  chmod +x "$stub/enchant"
  # Pass only description - should use current directory
  RUN_CMD_WORKDIR="$target" PATH="$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" _run_spell "spells/mud/decorate" "The entrance hall"
  _assert_success
  called=$(cat "$WIZARDRY_TMPDIR/decorate.called")
  # Check that the description is in the call
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
  target=$(_make_tempdir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$stub/enchant"
  PATH="$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" _run_spell "spells/mud/decorate" "$target" "description"
  _assert_failure && _assert_error_contains "failed to apply description"
}

_run_test_case "decorate prints usage" test_help
_run_test_case "decorate fails when enchant is missing" test_missing_enchant
_run_test_case "decorate fails when no valid path found" test_no_valid_path
_run_test_case "decorate fails for empty description" test_empty_description
_run_test_case "decorate applies description successfully" test_decorates_with_description
_run_test_case "decorate works with reversed argument order" test_decorates_with_reversed_args
_run_test_case "decorate works with description only" test_decorates_current_directory_with_description_only
_run_test_case "decorate reports enchant failure" test_reports_enchant_failure
_finish_tests
