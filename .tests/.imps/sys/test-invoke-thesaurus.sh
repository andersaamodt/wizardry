#!/bin/sh
# COMPILED_UNSUPPORTED: tests invoke-thesaurus which must be sourced
# Test invoke-thesaurus sourcer

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test: invoke-thesaurus fails when executed (must be sourced)
test_fails_when_executed() {
  run_cmd "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus"
  assert_failure || return 1
  assert_error_contains "cannot be cast directly" || return 1
}

# Test: invoke-thesaurus is sourceable without errors
test_sourceable() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  cat > "$tmpdir/test-source.sh" << EOF
#!/bin/sh
SPELLBOOK_DIR="$spellbook"
export SPELLBOOK_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus"
# If we get here, sourcing worked
printf 'sourced successfully\n'
EOF
  chmod +x "$tmpdir/test-source.sh"
  
  run_cmd sh "$tmpdir/test-source.sh"
  assert_success || return 1
  assert_output_contains "sourced successfully" || return 1
}

# Test: invoke-thesaurus creates synonym files if missing
test_creates_synonym_files() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  
  cat > "$tmpdir/test-init.sh" << EOF
#!/bin/sh
SPELLBOOK_DIR="$spellbook"
export SPELLBOOK_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus" >/dev/null 2>&1 || true
# Check files were created
[ -f "$spellbook/.synonyms" ] || exit 1
[ -f "$spellbook/.default-synonyms" ] || exit 1
printf 'files created\n'
EOF
  chmod +x "$tmpdir/test-init.sh"
  
  run_cmd sh "$tmpdir/test-init.sh"
  assert_success || return 1
  assert_output_contains "files created" || return 1
}

# Test: invoke-thesaurus loads default synonyms
test_loads_default_synonyms() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  cat > "$tmpdir/test-defaults.sh" << EOF
#!/bin/sh
SPELLBOOK_DIR="$spellbook"
export SPELLBOOK_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus" >/dev/null 2>&1 || true
# Check that default synonyms file has content in word=target format
grep -q "^detect-os=divine-distro" "$spellbook/.default-synonyms" || exit 1
grep -q "^home=jump-to-marker" "$spellbook/.default-synonyms" || exit 1
printf 'defaults loaded\n'
EOF
  chmod +x "$tmpdir/test-defaults.sh"
  
  run_cmd sh "$tmpdir/test-defaults.sh"
  assert_success || return 1
  assert_output_contains "defaults loaded" || return 1
}

# Test: invoke-thesaurus respects disabled state
test_respects_disabled_state() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  printf '0' > "$spellbook/.synonyms-enabled"
  
  cat > "$tmpdir/test-disabled.sh" << EOF
#!/bin/sh
SPELLBOOK_DIR="$spellbook"
export SPELLBOOK_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus" 2>&1 || true
EOF
  chmod +x "$tmpdir/test-disabled.sh"
  
  run_cmd sh "$tmpdir/test-disabled.sh"
  # Should output disabled message (stdout or stderr)
  if ! printf '%s' "$OUTPUT" | grep -q "disabled" && ! printf '%s' "$ERROR" | grep -q "disabled"; then
    TEST_FAILURE_REASON="expected 'disabled' in output"
    return 1
  fi
}

# Test: invoke-thesaurus creates jump synonym in word=target format
test_creates_jump_synonym() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  cat > "$tmpdir/test-jump.sh" << EOF
#!/bin/sh
SPELLBOOK_DIR="$spellbook"
export SPELLBOOK_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus" >/dev/null 2>&1 || true
# Check that jump synonym exists in word=target format
grep -q "^jump=jump-to-marker" "$spellbook/.default-synonyms" || exit 1
printf 'jump synonym exists\n'
EOF
  chmod +x "$tmpdir/test-jump.sh"
  
  run_cmd sh "$tmpdir/test-jump.sh"
  assert_success || return 1
  assert_output_contains "jump synonym exists" || return 1
}

# Test: invoke-thesaurus creates mark synonym for mark-location
test_creates_mark_synonym() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  cat > "$tmpdir/test-mark.sh" << EOF
#!/bin/sh
SPELLBOOK_DIR="$spellbook"
export SPELLBOOK_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus" >/dev/null 2>&1 || true
# Check that mark synonym exists in word=target format
grep -q "^mark=mark-location" "$spellbook/.default-synonyms" || exit 1
printf 'mark synonym exists\n'
EOF
  chmod +x "$tmpdir/test-mark.sh"
  
  run_cmd sh "$tmpdir/test-mark.sh"
  assert_success || return 1
  assert_output_contains "mark synonym exists" || return 1
}

run_test_case "invoke-thesaurus fails when executed" test_fails_when_executed
run_test_case "invoke-thesaurus is sourceable" test_sourceable
run_test_case "invoke-thesaurus creates synonym files" test_creates_synonym_files
run_test_case "invoke-thesaurus loads default synonyms" test_loads_default_synonyms
run_test_case "invoke-thesaurus respects disabled state" test_respects_disabled_state
run_test_case "invoke-thesaurus creates jump synonym" test_creates_jump_synonym
run_test_case "invoke-thesaurus creates mark synonym" test_creates_mark_synonym

finish_tests
