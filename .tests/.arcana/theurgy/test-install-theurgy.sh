#!/bin/sh
# Behavioral coverage for install-theurgy.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/theurgy/install-theurgy"

make_theurgy_source() {
  source_dir=$1
  mkdir -p "$source_dir/.git" "$source_dir/spells"
  cat >"$source_dir/install" <<'SH'
#!/bin/sh
set -eu
mkdir -p "${XDG_BIN_HOME:?}" "$THEURGY_HOME/spells"
cat >"$THEURGY_HOME/spells/assay-theurgy" <<'WRAP'
#!/bin/sh
exit 0
WRAP
cat >"$XDG_BIN_HOME/assay-theurgy" <<'WRAP'
#!/bin/sh
exit 0
WRAP
chmod +x "$THEURGY_HOME/spells/assay-theurgy" "$XDG_BIN_HOME/assay-theurgy"
SH
  chmod +x "$source_dir/install"
}

test_install_theurgy_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: install-theurgy" || return 1
}

test_install_theurgy_uses_local_source() {
  tmpdir=$(make_tempdir)
  make_theurgy_source "$tmpdir/source"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" \
    THEURGY_HOME="$tmpdir/theurgy" THEURGY_SOURCE_DIR="$tmpdir/source" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
  [ -x "$tmpdir/bin/assay-theurgy" ] || {
    TEST_FAILURE_REASON="expected assay-theurgy wrapper"
    return 1
  }
}

test_install_theurgy_rejects_non_link_home() {
  tmpdir=$(make_tempdir)
  make_theurgy_source "$tmpdir/source"
  mkdir -p "$tmpdir/theurgy"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" \
    THEURGY_HOME="$tmpdir/theurgy" THEURGY_SOURCE_DIR="$tmpdir/source" \
    sh "$ROOT_DIR/$target"
  assert_failure || return 1
  assert_error_contains "already exists" || return 1
}

run_test_case "install-theurgy shows help" test_install_theurgy_help
run_test_case "install-theurgy installs from local source" test_install_theurgy_uses_local_source
run_test_case "install-theurgy rejects non-link install home" test_install_theurgy_rejects_non_link_home

finish_tests
