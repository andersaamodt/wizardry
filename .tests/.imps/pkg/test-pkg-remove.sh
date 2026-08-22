#!/bin/sh
# Tests for the 'pkg-remove' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pkg_remove_no_package_fails() {
  skip-if-compiled || return $?
  run_spell spells/.imps/pkg/pkg-remove
  assert_failure
  assert_error_contains "package name required"
}

test_pkg_remove_empty_package_fails() {
  skip-if-compiled || return $?
  run_spell spells/.imps/pkg/pkg-remove ""
  assert_failure
  assert_error_contains "package name required"
}

test_pkg_remove_uses_termux_pkg() {
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

  PKG_LOG="$log_file" PATH="$stub_dir:/bin:/usr/bin" run_spell spells/.imps/pkg/pkg-remove vim
  assert_success || return 1
  assert_file_contains "$log_file" "uninstall" || return 1
  assert_file_contains "$log_file" "-y" || return 1
  assert_file_contains "$log_file" "vim" || return 1
}

run_test_case "pkg-remove without package fails" test_pkg_remove_no_package_fails
run_test_case "pkg-remove with empty package fails" test_pkg_remove_empty_package_fails
run_test_case "pkg-remove uses Termux pkg" test_pkg_remove_uses_termux_pkg

finish_tests
