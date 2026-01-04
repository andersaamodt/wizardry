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
. "$ROOT_DIR/spells/.imps/sys/spell-levels"
spells=$(get_level_spells 0)
case "$spells" in
  *detect-posix:divination*) printf 'found detect-posix\n' ;;
  *) printf 'missing detect-posix\n'; exit 1 ;;
esac
case "$spells" in
  *verify-posix:.wizardry*) printf 'found verify-posix\n' ;;
  *) printf 'missing verify-posix\n'; exit 1 ;;
esac
SCRIPT_EOF
  chmod +x "$tmpdir/test-level-spells.sh"

  run_cmd env ROOT_DIR="$ROOT_DIR" sh "$tmpdir/test-level-spells.sh"
  assert_success
  assert_output_contains "found detect-posix"
  assert_output_contains "found verify-posix"
}

test_level_imps_have_expected_entries() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/test-level-imps.sh" << 'SCRIPT_EOF'
#!/bin/sh
. "$ROOT_DIR/spells/.imps/sys/spell-levels"
imps=$(get_level_imps 1)
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

  run_cmd env ROOT_DIR="$ROOT_DIR" sh "$tmpdir/test-level-imps.sh"
  assert_success
  assert_output_contains "found has"
  assert_output_contains "found count-words"
}

test_level_names_are_defined() {
  skip-if-compiled || return $?
  tmpdir=$(make_tempdir)
  cat > "$tmpdir/test-level-names.sh" << 'SCRIPT_EOF'
#!/bin/sh
. "$ROOT_DIR/spells/.imps/sys/spell-levels"
name=$(banish_level_name 0)
if [ -n "$name" ]; then
  printf 'level name: %s\n' "$name"
else
  printf 'level name missing\n'
  exit 1
fi
SCRIPT_EOF
  chmod +x "$tmpdir/test-level-names.sh"

  run_cmd env ROOT_DIR="$ROOT_DIR" sh "$tmpdir/test-level-names.sh"
  assert_success
  assert_output_contains "level name:"
}

run_test_case "spell-levels defines level spells" test_level_spells_have_expected_entries
run_test_case "spell-levels defines level imps" test_level_imps_have_expected_entries
run_test_case "spell-levels defines level names" test_level_names_are_defined

finish_tests
