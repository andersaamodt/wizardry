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
  _run_cmd "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus"
  _assert_failure || return 1
  _assert_error_contains "must be sourced" || return 1
}

# Test: invoke-thesaurus is sourceable without errors
test_sourceable() {
  tmpdir=$(_make_tempdir)
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
  
  _run_cmd sh "$tmpdir/test-source.sh"
  _assert_success || return 1
  _assert_output_contains "sourced successfully" || return 1
}

# Test: invoke-thesaurus creates synonym files if missing
test_creates_synonym_files() {
  tmpdir=$(_make_tempdir)
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
  
  _run_cmd sh "$tmpdir/test-init.sh"
  _assert_success || return 1
  _assert_output_contains "files created" || return 1
}

# Test: invoke-thesaurus loads default synonyms
test_loads_default_synonyms() {
  tmpdir=$(_make_tempdir)
  spellbook="$tmpdir/.spellbook"
  mkdir -p "$spellbook"
  
  cat > "$tmpdir/test-defaults.sh" << EOF
#!/bin/sh
SPELLBOOK_DIR="$spellbook"
export SPELLBOOK_DIR
. "$ROOT_DIR/spells/.imps/sys/invoke-thesaurus" >/dev/null 2>&1 || true
# Check that default synonyms file has content
grep -q "^alias detect-os=" "$spellbook/.default-synonyms" || exit 1
grep -q "^alias home=" "$spellbook/.default-synonyms" || exit 1
printf 'defaults loaded\n'
EOF
  chmod +x "$tmpdir/test-defaults.sh"
  
  _run_cmd sh "$tmpdir/test-defaults.sh"
  _assert_success || return 1
  _assert_output_contains "defaults loaded" || return 1
}

# Test: invoke-thesaurus respects disabled state
test_respects_disabled_state() {
  tmpdir=$(_make_tempdir)
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
  
  _run_cmd sh "$tmpdir/test-disabled.sh"
  # Should output disabled message (stdout or stderr)
  if ! printf '%s' "$OUTPUT" | grep -q "disabled" && ! printf '%s' "$ERROR" | grep -q "disabled"; then
    TEST_FAILURE_REASON="expected 'disabled' in output"
    return 1
  fi
}

_run_test_case "invoke-thesaurus fails when executed" test_fails_when_executed
_run_test_case "invoke-thesaurus is sourceable" test_sourceable
_run_test_case "invoke-thesaurus creates synonym files" test_creates_synonym_files
_run_test_case "invoke-thesaurus loads default synonyms" test_loads_default_synonyms
_run_test_case "invoke-thesaurus respects disabled state" test_respects_disabled_state

_finish_tests
