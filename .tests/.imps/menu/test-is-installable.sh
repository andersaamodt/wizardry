#!/bin/sh
# Tests for the 'is-installable' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Create a temp spell with an install() function
create_installable_spell() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/spell.XXXXXX")
  cat > "$tmpfile" <<'SPELL'
#!/bin/sh
# A test spell with install function

install() {
  echo "Installing..."
}

echo "Running..."
SPELL
  chmod +x "$tmpfile"
  printf '%s' "$tmpfile"
}

# Create a temp spell without an install() function
create_noninstallable_spell() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/spell.XXXXXX")
  cat > "$tmpfile" <<'SPELL'
#!/bin/sh
# A test spell without install function

echo "Running..."
SPELL
  chmod +x "$tmpfile"
  printf '%s' "$tmpfile"
}

test_detects_installable_spell() {
  spell=$(create_installable_spell)
  run_spell spells/.imps/menu/is-installable "$spell"
  rm -f "$spell"
  assert_success
}

test_rejects_noninstallable_spell() {
  skip-if-compiled || return $?
  spell=$(create_noninstallable_spell)
  run_spell spells/.imps/menu/is-installable "$spell"
  rm -f "$spell"
  assert_failure
}

test_fails_for_missing_file() {
  skip-if-compiled || return $?
  run_spell spells/.imps/menu/is-installable "/nonexistent/path/to/spell"
  assert_failure
}

test_fails_for_empty_argument() {
  skip-if-compiled || return $?
  run_spell spells/.imps/menu/is-installable ""
  assert_failure
}

test_fails_for_no_argument() {
  skip-if-compiled || return $?
  run_spell spells/.imps/menu/is-installable
  assert_failure
}

test_detects_indented_install_function() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/spell.XXXXXX")
  cat > "$tmpfile" <<'SPELL'
#!/bin/sh
# A test spell with indented install function

  install() {
    echo "Installing..."
  }
SPELL
  chmod +x "$tmpfile"
  run_spell spells/.imps/menu/is-installable "$tmpfile"
  rm -f "$tmpfile"
  assert_success
}

run_test_case "is-installable detects spell with install()" test_detects_installable_spell
run_test_case "is-installable rejects spell without install()" test_rejects_noninstallable_spell
run_test_case "is-installable fails for missing file" test_fails_for_missing_file
run_test_case "is-installable fails for empty argument" test_fails_for_empty_argument
run_test_case "is-installable fails for no argument" test_fails_for_no_argument
run_test_case "is-installable detects indented install function" test_detects_indented_install_function

finish_tests
