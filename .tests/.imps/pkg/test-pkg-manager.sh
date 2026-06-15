#!/bin/sh
# Tests for the 'pkg-manager' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pkg_manager_returns_name() {
  run_spell spells/.imps/pkg/pkg-manager
  # Should succeed and output a package manager name (apt, dnf, etc.)
  assert_success
}

test_pkg_manager_output_is_valid() {
  skip-if-compiled || return $?
  run_spell spells/.imps/pkg/pkg-manager
  assert_success
  case "$OUTPUT" in
    termux|apt|dnf|pacman|brew|nix|pkgin|apk) : ;;
    *) TEST_FAILURE_REASON="unexpected output: $OUTPUT"; return 1 ;;
  esac
}

test_pkg_manager_detects_termux_from_path_markers() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"

  cat >"$stub_dir/pkg" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$stub_dir/pkg"

  cat >"$stub_dir/apt-get" <<'SH'
#!/bin/sh
exit 0
SH
  chmod +x "$stub_dir/apt-get"

  PATH="$stub_dir:/data/data/com.termux/files/usr/bin:/bin:/usr/bin" run_spell spells/.imps/pkg/pkg-manager
  assert_success || return 1
  [ "$OUTPUT" = "termux" ] || { TEST_FAILURE_REASON="expected termux but saw $OUTPUT"; return 1; }
}

run_test_case "pkg-manager returns name" test_pkg_manager_returns_name
run_test_case "pkg-manager output is valid" test_pkg_manager_output_is_valid
run_test_case "pkg-manager detects Termux from PATH markers" test_pkg_manager_detects_termux_from_path_markers

finish_tests
