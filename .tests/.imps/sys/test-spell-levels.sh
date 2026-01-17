#!/bin/sh
# Tests for the 'spell-levels' imp

# Locate the repository root so we can source test-bootstrap
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_level_spells_have_expected_entries() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/test-level-spells.sh" << 'SCRIPT_EOF'
#!/bin/sh
spells=$(spell-levels 0 spells)
case "$spells" in
  *divine-posix:divination*) printf 'found divine-posix\n' ;;
  *) printf 'missing divine-posix\n'; exit 1 ;;
esac
case "$spells" in
  *verify-posix:.wizardry*) printf 'found verify-posix\n' ;;
  *) printf 'missing verify-posix\n'; exit 1 ;;
esac
SCRIPT_EOF
  chmod +x "$tmpdir/test-level-spells.sh"

  # Add spell-levels to PATH
  run_cmd env PATH="$ROOT_DIR/spells/.imps/sys:$PATH" sh "$tmpdir/test-level-spells.sh"
  assert_success
  assert_output_contains "found divine-posix"
  assert_output_contains "found verify-posix"
}

test_level_imps_have_expected_entries() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/test-level-imps.sh" << 'SCRIPT_EOF'
#!/bin/sh
imps=$(spell-levels 1 imps)
case "$imps" in
  *cond/has*) printf 'found has\n' ;;
  *) printf 'missing has\n'; exit 1 ;;
esac
case "$imps" in
  *text/count-words*) printf 'found count-words\n' ;;
  *) printf 'missing count-words\n'; exit 1 ;;
esac
SCRIPT_EOF
  chmod +x "$tmpdir/test-level-imps.sh"

  # Add spell-levels to PATH
  run_cmd env PATH="$ROOT_DIR/spells/.imps/sys:$PATH" sh "$tmpdir/test-level-imps.sh"
  assert_success
  assert_output_contains "found has"
  assert_output_contains "found count-words"
}

test_level_names_are_defined() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/test-level-names.sh" << 'SCRIPT_EOF'
#!/bin/sh
name=$(spell-levels 0 name)
if [ -n "$name" ]; then
  printf 'level name: %s\n' "$name"
else
  printf 'level name missing\n'
  exit 1
fi
SCRIPT_EOF
  chmod +x "$tmpdir/test-level-names.sh"

  # Add spell-levels to PATH
  run_cmd env PATH="$ROOT_DIR/spells/.imps/sys:$PATH" sh "$tmpdir/test-level-names.sh"
  assert_success
  assert_output_contains "level name:"
}

run_test_case "spell-levels defines level spells" test_level_spells_have_expected_entries
run_test_case "spell-levels defines level imps" test_level_imps_have_expected_entries
run_test_case "spell-levels defines level names" test_level_names_are_defined

finish_tests
