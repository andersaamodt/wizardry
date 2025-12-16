#!/bin/sh
# Tests for the 'make-indent' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_make_2space_level1() {
  skip-if-compiled || return $?
  tmpfile="$WIZARDRY_TMPDIR/2space.nix"
  printf '{\n  foo = true;\n}\n' > "$tmpfile"
  _run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 1 "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  [ "$OUTPUT" = "  " ] || { TEST_FAILURE_REASON="expected 2 spaces but got '$OUTPUT'"; return 1; }
}

test_make_2space_level2() {
  skip-if-compiled || return $?
  tmpfile="$WIZARDRY_TMPDIR/2space2.nix"
  printf '{\n  foo = true;\n}\n' > "$tmpfile"
  _run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 2 "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  [ "$OUTPUT" = "    " ] || { TEST_FAILURE_REASON="expected 4 spaces but got '$OUTPUT'"; return 1; }
}

test_make_4space_level1() {
  skip-if-compiled || return $?
  tmpfile="$WIZARDRY_TMPDIR/4space.nix"
  printf '{\n    foo = true;\n}\n' > "$tmpfile"
  _run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 1 "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  [ "$OUTPUT" = "    " ] || { TEST_FAILURE_REASON="expected 4 spaces but got '$OUTPUT'"; return 1; }
}

test_make_tab_level1() {
  skip-if-compiled || return $?
  tmpfile="$WIZARDRY_TMPDIR/tab.nix"
  printf '{\n\tfoo = true;\n}\n' > "$tmpfile"
  _run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 1 "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  [ "$OUTPUT" = "	" ] || { TEST_FAILURE_REASON="expected 1 tab but got '$OUTPUT'"; return 1; }
}

test_make_tab_level2() {
  skip-if-compiled || return $?
  tmpfile="$WIZARDRY_TMPDIR/tab2.nix"
  printf '{\n\tfoo = true;\n}\n' > "$tmpfile"
  _run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 2 "$tmpfile"
  rm -f "$tmpfile"
  _assert_success
  [ "$OUTPUT" = "		" ] || { TEST_FAILURE_REASON="expected 2 tabs but got '$OUTPUT'"; return 1; }
}

test_make_default_without_file() {
  skip-if-compiled || return $?
  _run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 1
  _assert_success
  [ "$OUTPUT" = "  " ] || { TEST_FAILURE_REASON="expected 2 spaces as default but got '$OUTPUT'"; return 1; }
}

_run_test_case "make-indent generates 2-space level 1" test_make_2space_level1
_run_test_case "make-indent generates 2-space level 2" test_make_2space_level2
_run_test_case "make-indent generates 4-space level 1" test_make_4space_level1
_run_test_case "make-indent generates tab level 1" test_make_tab_level1
_run_test_case "make-indent generates tab level 2" test_make_tab_level2
_run_test_case "make-indent uses 2-space default without file" test_make_default_without_file

_finish_tests
