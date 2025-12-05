#!/bin/sh
# Tests for the 'require-wizardry' cantrip
#
# Behavioral cases (derived from --help):
# - require-wizardry --help shows usage
# - require-wizardry --check exits 0 when wizardry is installed
# - require-wizardry --check exits 1 when wizardry is not installed
# - require-wizardry --snippet outputs a valid POSIX shell snippet
# - require-wizardry --offer succeeds when wizardry is installed
# - require-wizardry --offer prints guidance when wizardry is not installed (non-interactive)

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

#!/bin/sh
# Tests for the 'require-wizardry' cantrip
#
# Behavioral cases (derived from --help):
# - require-wizardry --help shows usage
# - require-wizardry --check exits 0 when wizardry is installed
# - require-wizardry --check exits 1 when wizardry is not installed
# - require-wizardry --snippet outputs a valid POSIX shell snippet
# - require-wizardry --offer succeeds when wizardry is installed
# - require-wizardry --offer prints guidance when wizardry is not installed (non-interactive)

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
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


test_help() {
	run_spell spells/cantrips/require-wizardry --help
	assert_success && assert_output_contains "Usage:" && assert_output_contains "require-wizardry"
}

test_check_when_installed() {
	# When running tests, wizardry is on PATH, so --check should succeed
	run_spell spells/cantrips/require-wizardry --check
	assert_success
}

test_check_when_not_installed() {
	# Create an isolated environment without wizardry on PATH
	tmp=$(make_tempdir)
	
	# Link basic shell tools needed for the script to run
	# Include env which run_cmd uses internally
	link_tools "$tmp" sh printf cat command env
	
	# Save wizardry script to run it with absolute path
	script="$ROOT_DIR/spells/cantrips/require-wizardry"
	
	# Temporarily restrict PATH for this test
	OLD_PATH=$PATH
	PATH="$tmp"
	
	# Run with restricted PATH
	run_cmd sh "$script" --check
	
	# Restore PATH
	PATH=$OLD_PATH
	
	assert_failure
}

test_snippet_output() {
	run_spell spells/cantrips/require-wizardry --snippet
	assert_success && \
		assert_output_contains "_require_wizardry" && \
		assert_output_contains "curl" && \
		assert_output_contains "github.com/andersaamodt/wizardry"
}

test_snippet_is_valid_posix() {
	run_spell spells/cantrips/require-wizardry --snippet
	assert_success || return 1
	
	# Write the snippet to a temp file and check if it's valid shell
	tmp=$(make_tempdir)
	printf '%s\n' "$OUTPUT" > "$tmp/snippet.sh"
	
	# Check syntax with sh -n
	run_cmd sh -n "$tmp/snippet.sh"
	assert_success
}

test_offer_when_installed() {
	# When wizardry is installed, --offer should succeed silently
	run_spell spells/cantrips/require-wizardry --offer
	assert_success
}

test_offer_guidance_when_not_installed() {
	# Create an isolated environment without wizardry on PATH
	tmp=$(make_tempdir)
	
	# Link basic shell tools needed for the script to run
	# Include env which run_cmd uses internally
	link_tools "$tmp" sh printf cat command env
	
	# Save wizardry script to run it with absolute path
	script="$ROOT_DIR/spells/cantrips/require-wizardry"
	
	# Temporarily restrict PATH for this test
	OLD_PATH=$PATH
	PATH="$tmp"
	
	# Run in non-interactive mode (no terminal)
	run_cmd sh "$script" --offer
	
	# Restore PATH
	PATH=$OLD_PATH
	
	assert_failure && \
		assert_error_contains "wizardry" && \
		assert_error_contains "curl"
}

test_default_mode_is_offer() {
	# Running without arguments should default to --offer mode
	run_spell spells/cantrips/require-wizardry
	assert_success  # Wizardry is installed in test environment
}

run_test_case "require-wizardry --help shows usage" test_help
run_test_case "require-wizardry --check exits 0 when wizardry is installed" test_check_when_installed
run_test_case "require-wizardry --check exits 1 when wizardry is not installed" test_check_when_not_installed
run_test_case "require-wizardry --snippet outputs valid content" test_snippet_output
run_test_case "require-wizardry --snippet outputs valid POSIX shell" test_snippet_is_valid_posix
run_test_case "require-wizardry --offer succeeds when wizardry is installed" test_offer_when_installed
run_test_case "require-wizardry --offer prints guidance when not installed" test_offer_guidance_when_not_installed
run_test_case "require-wizardry defaults to --offer mode" test_default_mode_is_offer

finish_tests
