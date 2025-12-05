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

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
	_run_spell spells/cantrips/require-wizardry --help
	_assert_success && _assert_output_contains "Usage:" && _assert_output_contains "require-wizardry"
}

test_check_when_installed() {
	# When running tests, wizardry is on PATH, so --check should succeed
	_run_spell spells/cantrips/require-wizardry --check
	_assert_success
}

test_check_when_not_installed() {
	# Create an isolated environment without wizardry on PATH
	tmp=$(_make_tempdir)
	
	# Link basic shell tools needed for the script to run
	# Include env which _run_cmd uses internally
	_link_tools "$tmp" sh printf cat command env
	
	# Save wizardry script to run it with absolute path
	script="$ROOT_DIR/spells/cantrips/require-wizardry"
	
	# Temporarily restrict PATH for this test
	OLD_PATH=$PATH
	PATH="$tmp"
	
	# Run with restricted PATH
	_run_cmd sh "$script" --check
	
	# Restore PATH
	PATH=$OLD_PATH
	
	_assert_failure
}

test_snippet_output() {
	_run_spell spells/cantrips/require-wizardry --snippet
	_assert_success && \
		_assert_output_contains "_require_wizardry" && \
		_assert_output_contains "curl" && \
		_assert_output_contains "github.com/andersaamodt/wizardry"
}

test_snippet_is_valid_posix() {
	_run_spell spells/cantrips/require-wizardry --snippet
	_assert_success || return 1
	
	# Write the snippet to a temp file and check if it's valid shell
	tmp=$(_make_tempdir)
	printf '%s\n' "$OUTPUT" > "$tmp/snippet.sh"
	
	# Check syntax with sh -n
	_run_cmd sh -n "$tmp/snippet.sh"
	_assert_success
}

test_offer_when_installed() {
	# When wizardry is installed, --offer should succeed silently
	_run_spell spells/cantrips/require-wizardry --offer
	_assert_success
}

test_offer_guidance_when_not_installed() {
	# Create an isolated environment without wizardry on PATH
	tmp=$(_make_tempdir)
	
	# Link basic shell tools needed for the script to run
	# Include env which _run_cmd uses internally
	_link_tools "$tmp" sh printf cat command env
	
	# Save wizardry script to run it with absolute path
	script="$ROOT_DIR/spells/cantrips/require-wizardry"
	
	# Temporarily restrict PATH for this test
	OLD_PATH=$PATH
	PATH="$tmp"
	
	# Run in non-interactive mode (no terminal)
	_run_cmd sh "$script" --offer
	
	# Restore PATH
	PATH=$OLD_PATH
	
	_assert_failure && \
		_assert_error_contains "wizardry" && \
		_assert_error_contains "curl"
}

test_default_mode_is_offer() {
	# Running without arguments should default to --offer mode
	_run_spell spells/cantrips/require-wizardry
	_assert_success  # Wizardry is installed in test environment
}

_run_test_case "require-wizardry --help shows usage" test_help
_run_test_case "require-wizardry --check exits 0 when wizardry is installed" test_check_when_installed
_run_test_case "require-wizardry --check exits 1 when wizardry is not installed" test_check_when_not_installed
_run_test_case "require-wizardry --snippet outputs valid content" test_snippet_output
_run_test_case "require-wizardry --snippet outputs valid POSIX shell" test_snippet_is_valid_posix
_run_test_case "require-wizardry --offer succeeds when wizardry is installed" test_offer_when_installed
_run_test_case "require-wizardry --offer prints guidance when not installed" test_offer_guidance_when_not_installed
_run_test_case "require-wizardry defaults to --offer mode" test_default_mode_is_offer

_finish_tests
