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
  stub_dir="${WIZARDRY_TMPDIR}/stubs"
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

test_pkg_upgrade_uses_termux_pkg() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  log_file="$tmpdir/pkg.log"
  mkdir -p "$stub_dir"

  cat >"$stub_dir/pkg-manager" <<'SH'
#!/bin/sh
printf '%s\n' termux
SH
  chmod +x "$stub_dir/pkg-manager"

  cat >"$stub_dir/pkg" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${PKG_LOG:?}"
exit 0
SH
  chmod +x "$stub_dir/pkg"

  PKG_LOG="$log_file" PATH="$stub_dir:/bin:/usr/bin" run_spell spells/.imps/pkg/pkg-upgrade
  assert_success || return 1
  assert_file_contains "$log_file" "upgrade" || return 1
  assert_file_contains "$log_file" "-y" || return 1
}

run_test_case "pkg-upgrade has valid syntax" test_pkg_upgrade_syntax
run_test_case "pkg-upgrade uses Termux pkg" test_pkg_upgrade_uses_termux_pkg

finish_tests
