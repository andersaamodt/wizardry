#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

menu_reports_missing_tty() {
  tmpdir=$(_make_tempdir)
  
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  for stub in fathom-cursor fathom-terminal move-cursor cursor-blink stty await-keypress; do
    ln -s "$ROOT_DIR/spells/.imps/test/stub-$stub" "$stub_dir/$stub"
  done

  PATH="$stub_dir:$ROOT_DIR/spells/cantrips:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" _run_cmd env \
    AWAIT_KEYPRESS_DEVICE="$tmpdir/nonexistent-tty" \
    "$ROOT_DIR/spells/cantrips/menu" "Menu" "Item%echo hi"
  printf 'Output: %s\n' "$OUTPUT" >&2
  printf 'Error: %s\n' "$ERROR" >&2
  printf 'Exit code: %d\n' "$EXIT_CODE" >&2
  _assert_failure || return 1
  _assert_error_contains "menu: unable to access controlling terminal" || return 1
}

_run_test_case "menu reports missing tty" menu_reports_missing_tty
