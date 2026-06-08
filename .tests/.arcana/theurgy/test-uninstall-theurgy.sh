#!/bin/sh
# Behavioral coverage for uninstall-theurgy.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/theurgy/uninstall-theurgy"

test_uninstall_theurgy_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: uninstall-theurgy" || return 1
}

test_uninstall_theurgy_removes_wrappers_without_home() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/bin"
  touch "$tmpdir/bin/assay-theurgy" "$tmpdir/bin/conjure-native-desktop"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  [ ! -e "$tmpdir/bin/assay-theurgy" ] || {
    TEST_FAILURE_REASON="expected assay-theurgy wrapper removed"
    return 1
  }
}

test_uninstall_theurgy_uses_project_uninstaller() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/theurgy" "$tmpdir/bin"
  cat >"$tmpdir/theurgy/uninstall" <<'SH'
#!/bin/sh
set -eu
printf 'called\n' >"$THEURGY_HOME/uninstall-called"
SH
  chmod +x "$tmpdir/theurgy/uninstall"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  [ -f "$tmpdir/theurgy/uninstall-called" ] || {
    TEST_FAILURE_REASON="expected project uninstaller to run"
    return 1
  }
}

run_test_case "uninstall-theurgy shows help" test_uninstall_theurgy_help
run_test_case "uninstall-theurgy removes wrappers without project uninstaller" \
  test_uninstall_theurgy_removes_wrappers_without_home
run_test_case "uninstall-theurgy delegates to project uninstaller" \
  test_uninstall_theurgy_uses_project_uninstaller

finish_tests
