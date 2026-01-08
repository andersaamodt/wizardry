#!/bin/sh
# Tests for the 'pkg-upgrade' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pkg_upgrade_syntax() {
  # Just verify the imp syntax is valid by checking help/error output
  # Don't actually run upgrade which could hang on NixOS
  skip-if-compiled || return $?
  
  # Test that calling with no package manager fails gracefully
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Stub pkg-manager to return unsupported
  cat > "$stub_dir/pkg-manager" <<'STUB'
#!/bin/sh
exit 1
STUB
  chmod +x "$stub_dir/pkg-manager"
  
  PATH="$stub_dir:$PATH" run_spell spells/.imps/pkg/pkg-upgrade
  assert_failure || return 1
  assert_error_contains "no supported package manager" || return 1
}

run_test_case "pkg-upgrade has valid syntax" test_pkg_upgrade_syntax

finish_tests
