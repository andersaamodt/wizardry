#!/bin/sh
# Tests for the 'make-indent' imp

. "${0%/*}/../../test-common.sh"

test_make_2space_level1() {
  tmpfile="$WIZARDRY_TMPDIR/2space.nix"
  printf '{\n  foo = true;\n}\n' > "$tmpfile"
  run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 1 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  [ "$OUTPUT" = "  " ] || { TEST_FAILURE_REASON="expected 2 spaces but got '$OUTPUT'"; return 1; }
}

test_make_2space_level2() {
  tmpfile="$WIZARDRY_TMPDIR/2space2.nix"
  printf '{\n  foo = true;\n}\n' > "$tmpfile"
  run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 2 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  [ "$OUTPUT" = "    " ] || { TEST_FAILURE_REASON="expected 4 spaces but got '$OUTPUT'"; return 1; }
}

test_make_4space_level1() {
  tmpfile="$WIZARDRY_TMPDIR/4space.nix"
  printf '{\n    foo = true;\n}\n' > "$tmpfile"
  run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 1 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  [ "$OUTPUT" = "    " ] || { TEST_FAILURE_REASON="expected 4 spaces but got '$OUTPUT'"; return 1; }
}

test_make_tab_level1() {
  tmpfile="$WIZARDRY_TMPDIR/tab.nix"
  printf '{\n\tfoo = true;\n}\n' > "$tmpfile"
  run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 1 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  [ "$OUTPUT" = "	" ] || { TEST_FAILURE_REASON="expected 1 tab but got '$OUTPUT'"; return 1; }
}

test_make_tab_level2() {
  tmpfile="$WIZARDRY_TMPDIR/tab2.nix"
  printf '{\n\tfoo = true;\n}\n' > "$tmpfile"
  run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 2 "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  [ "$OUTPUT" = "		" ] || { TEST_FAILURE_REASON="expected 2 tabs but got '$OUTPUT'"; return 1; }
}

test_make_default_without_file() {
  run_cmd "$ROOT_DIR/spells/.imps/text/make-indent" 1
  assert_success
  [ "$OUTPUT" = "  " ] || { TEST_FAILURE_REASON="expected 2 spaces as default but got '$OUTPUT'"; return 1; }
}

run_test_case "make-indent generates 2-space level 1" test_make_2space_level1
run_test_case "make-indent generates 2-space level 2" test_make_2space_level2
run_test_case "make-indent generates 4-space level 1" test_make_4space_level1
run_test_case "make-indent generates tab level 1" test_make_tab_level1
run_test_case "make-indent generates tab level 2" test_make_tab_level2
run_test_case "make-indent uses 2-space default without file" test_make_default_without_file

finish_tests
