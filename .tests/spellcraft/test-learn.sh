#!/bin/sh
# Tests for the learn spell - copying/linking spells into spellbook

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/spellcraft/learn" --help
  assert_success && assert_output_contains "Usage: learn"
}

test_missing_args() {
  run_spell "spells/spellcraft/learn"
  assert_failure && assert_error_contains "spell or directory path required"
}

test_nonexistent_path() {
  run_spell "spells/spellcraft/learn" /nonexistent/path
  assert_failure && assert_error_contains "path not found"
}

test_copy_spell() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/spellbook"
  
  # Create a test spell
  test_spell="$tmpdir/my-test-spell"
  cat >"$test_spell" <<'EOF'
#!/bin/sh
echo "test spell"
EOF
  chmod +x "$test_spell"
  
  # Copy it to spellbook
  SPELLBOOK_DIR="$spellbook" run_spell "spells/spellcraft/learn" "$test_spell"
  assert_success || return 1
  
  # Verify it was copied
  [ -f "$spellbook/my-test-spell" ] || {
    printf 'Expected spell to be copied to spellbook\n' >&2
    return 1
  }
  [ -x "$spellbook/my-test-spell" ] || {
    printf 'Expected spell to be executable\n' >&2
    return 1
  }
}

test_copy_directory() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/spellbook"
  
  # Create a test spellbook directory
  test_dir="$tmpdir/my-spells"
  mkdir -p "$test_dir"
  cat >"$test_dir/spell1" <<'EOF'
#!/bin/sh
echo "spell 1"
EOF
  chmod +x "$test_dir/spell1"
  
  # Copy it to spellbook
  SPELLBOOK_DIR="$spellbook" run_spell "spells/spellcraft/learn" "$test_dir"
  assert_success || return 1
  
  # Verify directory was copied
  [ -d "$spellbook/my-spells" ] || {
    printf 'Expected directory to be copied to spellbook\n' >&2
    return 1
  }
  [ -f "$spellbook/my-spells/spell1" ] || {
    printf 'Expected spell1 to exist in copied directory\n' >&2
    return 1
  }
}

test_link_spell() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/spellbook"
  
  # Create a test spell
  test_spell="$tmpdir/my-linked-spell"
  cat >"$test_spell" <<'EOF'
#!/bin/sh
echo "linked spell"
EOF
  chmod +x "$test_spell"
  
  # Link it to spellbook
  SPELLBOOK_DIR="$spellbook" run_spell "spells/spellcraft/learn" --link "$test_spell"
  assert_success || return 1
  
  # Verify it's a link
  [ -L "$spellbook/my-linked-spell" ] || {
    printf 'Expected spell to be a symbolic link\n' >&2
    return 1
  }
}

test_prevents_duplicates() {
  tmpdir=$(make_tempdir)
  spellbook="$tmpdir/spellbook"
  
  # Create a test spell
  test_spell="$tmpdir/duplicate-spell"
  cat >"$test_spell" <<'EOF'
#!/bin/sh
echo "duplicate"
EOF
  chmod +x "$test_spell"
  
  # Copy it once
  SPELLBOOK_DIR="$spellbook" run_spell "spells/spellcraft/learn" "$test_spell"
  assert_success || return 1
  
  # Try to copy again - should fail
  SPELLBOOK_DIR="$spellbook" run_spell "spells/spellcraft/learn" "$test_spell"
  assert_failure || return 1
  assert_error_contains "already exists" || return 1
}

run_test_case "learn prints usage" test_help
run_test_case "learn requires path argument" test_missing_args
run_test_case "learn rejects nonexistent path" test_nonexistent_path
run_test_case "learn copies spell to spellbook" test_copy_spell
run_test_case "learn copies directory to spellbook" test_copy_directory
run_test_case "learn links spell to spellbook" test_link_spell
run_test_case "learn prevents duplicate names" test_prevents_duplicates


# Test via source-then-invoke pattern  

finish_tests
