#!/bin/sh
# Behavioral cases (derived from --help):
# - require-command succeeds when command exists
# - require-command reports missing commands with default guidance
# - require-command accepts a custom failure message
# - require-command requires at least one argument

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


require_command_succeeds_when_available() {
  run_spell "spells/cantrips/require-command" sh
  assert_success || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no stdout"; return 1; }
}

require_command_reports_missing_with_default_message() {
  run_spell "spells/cantrips/require-command" definitely-not-a-real-command
  assert_failure || return 1
  assert_error_contains "require-command: The 'definitely-not-a-real-command' command is required." || return 1
  assert_error_contains "core-menu" || return 1
}

require_command_supports_custom_message() {
  run_spell "spells/cantrips/require-command" missing-helper "custom install instructions"
  assert_failure || return 1
  assert_error_contains "custom install instructions" || return 1
}

require_command_installs_when_helper_available() {
  tmp=$(make_tempdir)

  cat >"$tmp/install-missing" <<'SH'
#!/bin/sh
touch "$STUB_DIR/missing"
chmod +x "$STUB_DIR/missing"
SH
  chmod +x "$tmp/install-missing"

  run_cmd env PATH="$tmp:$PATH" STUB_DIR="$tmp" REQUIRE_COMMAND_ASSUME_YES=1 \
    "$ROOT_DIR/spells/cantrips/require-command" missing

  assert_success && assert_path_exists "$tmp/missing"
}

require_command_requires_arguments() {
  run_spell "spells/cantrips/require-command"
  assert_failure || return 1
  assert_error_contains "Usage: require-command" || return 1
}

run_test_case "require-command succeeds when command exists" require_command_succeeds_when_available
run_test_case "require-command reports missing commands with default guidance" require_command_reports_missing_with_default_message
run_test_case "require-command accepts a custom failure message" require_command_supports_custom_message
run_test_case "require-command requires at least one argument" require_command_requires_arguments
run_test_case "require-command installs when helper is available" require_command_installs_when_helper_available

finish_tests
