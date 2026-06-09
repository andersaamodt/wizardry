#!/bin/sh
# Behavioral coverage for invoke-theurgy.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/theurgy/invoke-theurgy"

make_theurgy_source() {
  source_dir=$1
  mkdir -p "$source_dir/.git"
  cat >"$source_dir/install" <<'SH'
#!/bin/sh
set -eu
mkdir -p "${XDG_BIN_HOME:?}" "$THEURGY_HOME/spells"
touch "$THEURGY_HOME/spells/assay-theurgy" "$XDG_BIN_HOME/assay-theurgy"
chmod +x "$THEURGY_HOME/spells/assay-theurgy" "$XDG_BIN_HOME/assay-theurgy"
SH
  chmod +x "$source_dir/install"
}

test_invoke_theurgy_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: invoke-theurgy" || return 1
}

test_invoke_theurgy_skips_installed() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/theurgy/spells" "$tmpdir/bin"
  touch "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  chmod +x "$tmpdir/theurgy/spells/assay-theurgy" "$tmpdir/bin/assay-theurgy"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" THEURGY_HOME="$tmpdir/theurgy" \
    sh "$ROOT_DIR/$target"
  assert_success || return 1
}

test_invoke_theurgy_yes_installs() {
  tmpdir=$(make_tempdir)
  make_theurgy_source "$tmpdir/source"
  run_cmd env HOME="$tmpdir/home" XDG_BIN_HOME="$tmpdir/bin" \
    THEURGY_HOME="$tmpdir/theurgy" THEURGY_SOURCE_DIR="$tmpdir/source" \
    sh "$ROOT_DIR/$target" --yes
  assert_success || return 1
  [ -x "$tmpdir/bin/assay-theurgy" ] || {
    TEST_FAILURE_REASON="expected invoke --yes to install wrapper"
    return 1
  }
}

run_test_case "invoke-theurgy shows help" test_invoke_theurgy_help
run_test_case "invoke-theurgy succeeds when installed" test_invoke_theurgy_skips_installed
run_test_case "invoke-theurgy --yes installs missing dependency" test_invoke_theurgy_yes_installs

finish_tests
