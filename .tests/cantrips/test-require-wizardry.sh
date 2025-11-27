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

. "${0%/*}/../test-common.sh"

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
