#!/bin/sh
# Tests for check-attribute-tool imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_xattr_helper_usable_exists() {
  run_cmd sh -c 'command -v check-attribute-tool'
  assert_success || return 1
}

test_xattr_helper_usable_accepts_command() {
  skip-if-compiled || return $?
  # Should return 0 for a command that exists in PATH (but not in system paths during test mode)
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/bin"
  printf '#!/bin/sh\nprintf "stub"\n' > "$tmpdir/bin/mycmd"
  chmod +x "$tmpdir/bin/mycmd"
  
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && check-attribute-tool mycmd'
  assert_success || return 1
  
  rm -rf "$tmpdir"
}

test_xattr_helper_usable_rejects_nonexistent() {
  skip-if-compiled || return $?
  # Should return 1 for non-existent command
  run_cmd check-attribute-tool nonexistent-command-xyz123
  assert_failure || return 1
}

test_xattr_helper_usable_respects_test_mode() {
  skip-if-compiled || return $?
  # When WIZARDRY_TEST_HELPERS_ONLY=1, system commands should be rejected
  run_cmd sh -c 'WIZARDRY_TEST_HELPERS_ONLY=1 check-attribute-tool sh'
  assert_failure || return 1
}

test_xattr_helper_usable_allows_non_system_in_test_mode() {
  skip-if-compiled || return $?
  # Create a stub helper in temp location
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/bin"
  printf '#!/bin/sh\nprintf "stub"\n' > "$tmpdir/bin/mystub"
  chmod +x "$tmpdir/bin/mystub"
  
  # With WIZARDRY_TEST_HELPERS_ONLY=1, non-system helpers should work
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && WIZARDRY_TEST_HELPERS_ONLY=1 check-attribute-tool mystub'
  assert_success || return 1
  
  rm -rf "$tmpdir"
}

test_xattr_helper_usable_rejects_termux_system_command() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  prefix="$tmpdir/usr"
  mkdir -p "$prefix/bin"
  printf '#!/bin/sh\nexit 0\n' > "$prefix/bin/systemcmd"
  chmod +x "$prefix/bin/systemcmd"

  run_cmd env PREFIX="$prefix" PATH="$prefix/bin:$PATH" \
    WIZARDRY_TEST_HELPERS_ONLY=1 \
    "$ROOT_DIR/spells/.imps/fs/check-attribute-tool" systemcmd
  assert_failure
}

run_test_case "check-attribute-tool exists" test_xattr_helper_usable_exists
run_test_case "check-attribute-tool accepts valid command" test_xattr_helper_usable_accepts_command
run_test_case "check-attribute-tool rejects nonexistent command" test_xattr_helper_usable_rejects_nonexistent
run_test_case "check-attribute-tool respects test mode" test_xattr_helper_usable_respects_test_mode
run_test_case "check-attribute-tool allows non-system in test mode" test_xattr_helper_usable_allows_non_system_in_test_mode
run_test_case "check-attribute-tool rejects Termux prefix commands in test mode" \
  test_xattr_helper_usable_rejects_termux_system_command

finish_tests
