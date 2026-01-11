#!/bin/sh
# Tests for xattr-helper-usable imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_xattr_helper_usable_exists() {
  run_cmd sh -c 'command -v xattr-helper-usable'
  assert_success || return 1
}

test_xattr_helper_usable_accepts_command() {
  skip-if-compiled || return $?
  # Should return 0 for a command that exists in PATH
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/bin"
  printf '#!/bin/sh\nprintf "stub"\n' > "$tmpdir/bin/mycmd"
  chmod +x "$tmpdir/bin/mycmd"
  
  run_cmd sh -c 'export PATH="'"$tmpdir"'/bin:$PATH" && xattr-helper-usable mycmd'
  assert_success || return 1
  
  rm -rf "$tmpdir"
}

test_xattr_helper_usable_rejects_nonexistent() {
  skip-if-compiled || return $?
  # Should return 1 for non-existent command
  run_cmd xattr-helper-usable nonexistent-command-xyz123
  assert_failure || return 1
}

run_test_case "xattr-helper-usable exists" test_xattr_helper_usable_exists
run_test_case "xattr-helper-usable accepts valid command" test_xattr_helper_usable_accepts_command
run_test_case "xattr-helper-usable rejects nonexistent command" test_xattr_helper_usable_rejects_nonexistent

finish_tests
