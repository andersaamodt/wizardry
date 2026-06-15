#!/bin/sh
# Tests for the 'pkg-has' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pkg_has_no_package_fails() {
  skip-if-compiled || return $?
  run_spell spells/.imps/pkg/pkg-has
  assert_failure
  assert_error_contains "package name required"
}

test_pkg_has_empty_package_fails() {
  skip-if-compiled || return $?
  run_spell spells/.imps/pkg/pkg-has ""
  assert_failure
  assert_error_contains "package name required"
}

test_pkg_has_checks_termux_packages_with_dpkg() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"

  cat >"$stub_dir/pkg-manager" <<'SH'
#!/bin/sh
printf '%s\n' termux
SH
  chmod +x "$stub_dir/pkg-manager"

  cat >"$stub_dir/dpkg" <<'SH'
#!/bin/sh
if [ "${1-}" = "-l" ] && [ "${2-}" = "git" ]; then
  printf '%s\n' "ii  git 1.0 all"
  exit 0
fi
exit 1
SH
  chmod +x "$stub_dir/dpkg"

  PATH="$stub_dir:/bin:/usr/bin" run_spell spells/.imps/pkg/pkg-has git
  assert_success || return 1
}

run_test_case "pkg-has without package fails" test_pkg_has_no_package_fails
run_test_case "pkg-has with empty package fails" test_pkg_has_empty_package_fails
run_test_case "pkg-has checks Termux packages with dpkg" test_pkg_has_checks_termux_packages_with_dpkg

finish_tests
