#!/bin/sh
# Tests for xattr-helper-usable imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_xattr_helper_usable_exists() {
  _run_cmd command -v xattr-helper-usable
  _assert_success || return 1
}

test_xattr_helper_usable_accepts_command() {
  skip-if-compiled || return $?
  # Should return 0 for a command that exists in PATH (but not in system paths during test mode)
  tmpdir=$(_make_tempdir)
  mkdir -p "$tmpdir/bin"
  printf '#!/bin/sh\nprintf "stub"\n' > "$tmpdir/bin/mycmd"
  chmod +x "$tmpdir/bin/mycmd"
  
  _run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && xattr-helper-usable mycmd'
  _assert_success || return 1
  
  rm -rf "$tmpdir"
}

test_xattr_helper_usable_rejects_nonexistent() {
  skip-if-compiled || return $?
  # Should return 1 for non-existent command
  _run_cmd xattr-helper-usable nonexistent-command-xyz123
  _assert_failure || return 1
}

test_xattr_helper_usable_respects_test_mode() {
  skip-if-compiled || return $?
  # When WIZARDRY_TEST_HELPERS_ONLY=1, system commands should be rejected
  _run_cmd sh -c 'WIZARDRY_TEST_HELPERS_ONLY=1 xattr-helper-usable sh'
  _assert_failure || return 1
}

test_xattr_helper_usable_allows_non_system_in_test_mode() {
  skip-if-compiled || return $?
  # Create a stub helper in temp location
  tmpdir=$(_make_tempdir)
  mkdir -p "$tmpdir/bin"
  printf '#!/bin/sh\nprintf "stub"\n' > "$tmpdir/bin/mystub"
  chmod +x "$tmpdir/bin/mystub"
  
  # With WIZARDRY_TEST_HELPERS_ONLY=1, non-system helpers should work
  _run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && WIZARDRY_TEST_HELPERS_ONLY=1 xattr-helper-usable mystub'
  _assert_success || return 1
  
  rm -rf "$tmpdir"
}

_run_test_case "xattr-helper-usable exists" test_xattr_helper_usable_exists
_run_test_case "xattr-helper-usable accepts valid command" test_xattr_helper_usable_accepts_command
_run_test_case "xattr-helper-usable rejects nonexistent command" test_xattr_helper_usable_rejects_nonexistent
_run_test_case "xattr-helper-usable respects test mode" test_xattr_helper_usable_respects_test_mode
_run_test_case "xattr-helper-usable allows non-system in test mode" test_xattr_helper_usable_allows_non_system_in_test_mode

_finish_tests
