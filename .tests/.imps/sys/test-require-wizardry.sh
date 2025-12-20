#!/bin/sh
# COMPILED_UNSUPPORTED: tests require-wizardry which is wizardry bootstrap
# Tests for the 'require-wizardry' imp
#
# Behavioral cases:
# - require-wizardry returns 0 when wizardry is installed (menu found)
# - require-wizardry returns 1 when wizardry is not installed
# - require-wizardry auto-succeeds in test mode (WIZARDRY_TEST_HELPERS_ONLY=1)

# Locate the repository root so we can source test-bootstrap
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_succeeds_when_installed() {
# When running tests, wizardry is on PATH, so should succeed
_run_spell spells/.imps/sys/require-wizardry
_assert_success
}

test_auto_succeeds_in_test_mode() {
# With WIZARDRY_TEST_HELPERS_ONLY=1, should always succeed
WIZARDRY_TEST_HELPERS_ONLY=1 _run_spell spells/.imps/sys/require-wizardry
_assert_success
}

test_fails_when_not_installed() {
# Create an isolated environment without wizardry on PATH
tmp=$(_make_tempdir)

# Link basic shell tools needed for the script to run
for tool in sh printf cat command env; do
tool_path=$(command -v "$tool" 2>/dev/null) || continue
[ -x "$tool_path" ] && ln -sf "$tool_path" "$tmp/$tool"
done

# Also need the has imp
mkdir -p "$tmp/imps"
cp "$ROOT_DIR/spells/.imps/cond/has" "$tmp/imps/has"

# Save wizardry script to run it with absolute path
script="$ROOT_DIR/spells/.imps/sys/require-wizardry"

# Run with restricted PATH (no menu, no wizardry, not in test mode)
# Unset WIZARDRY_DIR to simulate environment without wizardry
WIZARDRY_DIR="" WIZARDRY_TEST_HELPERS_ONLY="" PATH="$tmp:$tmp/imps" _run_cmd sh "$script" </dev/null
_assert_failure || return 1
_assert_error_contains "wizardry is not installed" || return 1
}

_run_test_case "succeeds when wizardry installed" test_succeeds_when_installed
_run_test_case "auto-succeeds in test mode" test_auto_succeeds_in_test_mode
_run_test_case "fails when not installed" test_fails_when_not_installed
_finish_tests
