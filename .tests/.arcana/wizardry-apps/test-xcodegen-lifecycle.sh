#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

xcodegen_lifecycle_spells_show_help() {
  for spell in is-xcodegen-installed uninstall-xcodegen; do
    run_spell "spells/.arcana/wizardry-apps/$spell" --help
    assert_success || return 1
  done
}

xcodegen_probe_fails_when_tool_is_absent() {
  data=$(make_tempdir)
  run_cmd env XDG_DATA_HOME="$data" PATH=/usr/bin:/bin \
    "$ROOT_DIR/spells/.arcana/wizardry-apps/is-xcodegen-installed"
  assert_failure
}

xcodegen_uninstaller_removes_managed_install() {
  data=$(make_tempdir)
  managed=$data/wizardry-apps/toolchains/xcodegen/current
  mkdir -p "$managed"
  : > "$managed/xcodegen"
  chmod +x "$managed/xcodegen"
  run_cmd env XDG_DATA_HOME="$data" \
    "$ROOT_DIR/spells/.arcana/wizardry-apps/uninstall-xcodegen"
  assert_success || return 1
  [ ! -e "$data/wizardry-apps/toolchains/xcodegen" ]
}

run_test_case "XcodeGen lifecycle spells show help" xcodegen_lifecycle_spells_show_help
run_test_case "XcodeGen probe fails when the tool is absent" xcodegen_probe_fails_when_tool_is_absent
run_test_case "XcodeGen uninstaller removes managed state" xcodegen_uninstaller_removes_managed_install
finish_tests
