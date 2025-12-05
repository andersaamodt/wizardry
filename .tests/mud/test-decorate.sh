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

set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


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

test_no_valid_path() {
  stub=$(make_stub_dir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$stub/enchant"
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" run_spell "spells/mud/decorate" "/nonexistent/path" "description"
  assert_failure && assert_error_contains "no valid path found"
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

test_decorates_with_reversed_args() {
  stub=$(make_stub_dir)
  target=$(make_tempdir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/decorate.called"
exit 0
EOF
  chmod +x "$stub/enchant"
  # Pass description first, then path
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" run_spell "spells/mud/decorate" "A secret alcove" "$target"
  assert_success && assert_output_contains "decorated with the description"
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
  target=$(make_tempdir)
  cat >"$stub/enchant" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >"${WIZARDRY_TMPDIR:?}/decorate.called"
exit 0
EOF
  chmod +x "$stub/enchant"
  # Pass only description - should use current directory
  RUN_CMD_WORKDIR="$target" PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$stub:/bin:/usr/bin" run_spell "spells/mud/decorate" "The entrance hall"
  assert_success
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
run_test_case "decorate fails when no valid path found" test_no_valid_path
run_test_case "decorate fails for empty description" test_empty_description
run_test_case "decorate applies description successfully" test_decorates_with_description
run_test_case "decorate works with reversed argument order" test_decorates_with_reversed_args
run_test_case "decorate works with description only" test_decorates_current_directory_with_description_only
run_test_case "decorate reports enchant failure" test_reports_enchant_failure
finish_tests
