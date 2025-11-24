#!/bin/sh
set -eu

# Test that install script works even when old versions of spells are in PATH

# shellcheck source=../test_common.sh
. "$(dirname "$0")/../test_common.sh"

# Test: Install should work when old broken versions of helper spells are in PATH
install_with_old_spells_in_path() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq mkdir rm date mktemp

  # Create an "old" wizardry installation with broken versions of helper spells
  old_wizardry="$fixture/old-wizardry"
  mkdir -p "$old_wizardry/spells/translocation"
  mkdir -p "$old_wizardry/spells/divination"
  mkdir -p "$old_wizardry/spells/spellcraft"
  mkdir -p "$old_wizardry/spells/cantrips"

  # Create a broken old path-wizard that always fails
  cat <<'BROKEN_WIZARD' >"$old_wizardry/spells/translocation/path-wizard"
#!/bin/sh
echo "ERROR: This is a broken old version of path-wizard" >&2
exit 1
BROKEN_WIZARD
  chmod +x "$old_wizardry/spells/translocation/path-wizard"

  # Create a broken old detect-rc-file that returns invalid output
  cat <<'BROKEN_DETECT' >"$old_wizardry/spells/divination/detect-rc-file"
#!/bin/sh
echo "broken=invalid"
exit 1
BROKEN_DETECT
  chmod +x "$old_wizardry/spells/divination/detect-rc-file"

  # Create a broken old scribe-spell that always fails
  cat <<'BROKEN_SCRIBE' >"$old_wizardry/spells/spellcraft/scribe-spell"
#!/bin/sh
echo "ERROR: This is a broken old version of scribe-spell" >&2
exit 1
BROKEN_SCRIBE
  chmod +x "$old_wizardry/spells/spellcraft/scribe-spell"

  # Create a broken old ask_yn that always returns no
  cat <<'BROKEN_ASK' >"$old_wizardry/spells/cantrips/ask_yn"
#!/bin/sh
echo "ERROR: This is a broken old version of ask_yn" >&2
exit 1
BROKEN_ASK
  chmod +x "$old_wizardry/spells/cantrips/ask_yn"

  # Add the old (broken) wizardry to PATH BEFORE the current one
  # This simulates the real-world scenario where old spells are in PATH
  old_path="$old_wizardry/spells/translocation:$old_wizardry/spells/divination:$old_wizardry/spells/spellcraft:$old_wizardry/spells/cantrips"

  install_dir="$fixture/home/.wizardry"
  
  # Run install with old broken spells in PATH
  PATH="$old_path:$fixture/bin:$initial_path" \
    WIZARDRY_INSTALL_ASSUME_YES=1 \
    WIZARDRY_INSTALL_DIR="$install_dir" \
    run_cmd "$ROOT_DIR/install"

  # The install should succeed despite broken old spells in PATH
  assert_success || return 1
  
  # Verify the new wizardry was installed
  assert_path_exists "$install_dir/spells" || return 1
  
  # Verify that the error messages from the broken old spells are NOT in the output
  # This confirms we're using the new spells, not the old ones
  if printf '%s' "$ERROR" | grep -q "This is a broken old version"; then
    TEST_FAILURE_REASON="Install used broken old spells from PATH instead of new ones"
    return 1
  fi

  return 0
}

# Test: Install should work even when old path-wizard lies about status
# This test verifies that the NEW path-wizard is used, not the old one from PATH
install_ignores_lying_old_path_wizard() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq mkdir rm date mktemp

  # Create an "old" broken path-wizard that always returns success for 'status'
  # This simulates an old buggy version that incorrectly reports paths are already set
  old_wizardry="$fixture/old-wizardry"
  mkdir -p "$old_wizardry/spells/translocation"
  
  # Create a log file in the fixture directory for tracking
  log_file="$fixture/old-wizard-calls.log"
  
  cat <<LYING_WIZARD >"$old_wizardry/spells/translocation/path-wizard"
#!/bin/sh
# This old broken version lies about status and logs to show it was called
echo "OLD_WIZARD_CALLED" >> "$log_file"
if [ "\${1:-}" = "status" ] || [ "\${2:-}" = "status" ] || [ "\${3:-}" = "status" ]; then
  exit 0  # Falsely claim path is already set
fi
exit 1
LYING_WIZARD
  chmod +x "$old_wizardry/spells/translocation/path-wizard"

  install_dir="$fixture/home/.wizardry"
  
  # Run install with the lying old path-wizard in PATH
  # The install should use the NEW path-wizard (via explicit path), not the old one
  PATH="$old_wizardry/spells/translocation:$fixture/bin:$initial_path" \
    WIZARDRY_INSTALL_ASSUME_YES=1 \
    WIZARDRY_INSTALL_DIR="$install_dir" \
    run_cmd "$ROOT_DIR/install"

  # Should succeed
  assert_success || return 1
  
  # Verify wizardry was installed (spells directory exists)
  assert_path_exists "$install_dir/spells" || return 1
  
  # Verify the old lying wizard was NOT called
  # If it was called, the log file would exist and contain "OLD_WIZARD_CALLED"
  if [ -f "$log_file" ] && grep -q "OLD_WIZARD_CALLED" "$log_file" 2>/dev/null; then
    TEST_FAILURE_REASON="Install called the old lying path-wizard from PATH instead of using the new one"
    return 1
  fi
  
  return 0
}

# Test: path-wizard should use new helper spells even when old ones are in PATH
path_wizard_uses_new_helpers() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq mkdir rm date mktemp

  # Create an "old" broken detect-rc-file in PATH
  old_spell_dir="$fixture/old-spells"
  mkdir -p "$old_spell_dir"
  
  cat <<'BROKEN' >"$old_spell_dir/detect-rc-file"
#!/bin/sh
echo "ERROR: Old broken detect-rc-file" >&2
exit 1
BROKEN
  chmod +x "$old_spell_dir/detect-rc-file"

  cat <<'BROKEN' >"$old_spell_dir/scribe-spell"
#!/bin/sh
echo "ERROR: Old broken scribe-spell" >&2
exit 1
BROKEN
  chmod +x "$old_spell_dir/scribe-spell"

  # Create a test directory to add to PATH
  test_dir="$fixture/test-path"
  mkdir -p "$test_dir"

  # Set up environment with old broken spells in PATH
  rc_file="$fixture/.testrc"
  
  # Run path-wizard with old broken spells in PATH
  # But explicitly set DETECT_RC_FILE and SCRIBE_SPELL to use new versions
  PATH="$old_spell_dir:$fixture/bin:$initial_path" \
    DETECT_RC_FILE="$ROOT_DIR/spells/divination/detect-rc-file" \
    SCRIBE_SPELL="$ROOT_DIR/spells/spellcraft/scribe-spell" \
    run_cmd "$ROOT_DIR/spells/translocation/path-wizard" \
      --rc-file "$rc_file" \
      --format shell \
      add "$test_dir"

  # Should succeed because we're using the new helpers via env vars
  assert_success || return 1
  
  # Verify it didn't use the broken old spells
  if printf '%s' "$ERROR" | grep -q "Old broken"; then
    TEST_FAILURE_REASON="path-wizard used old broken spells from PATH"
    return 1
  fi

  return 0
}

run_test_case "install works with old spells in PATH" install_with_old_spells_in_path
run_test_case "install ignores lying old path-wizard" install_ignores_lying_old_path_wizard
run_test_case "path-wizard uses new helpers via env vars" path_wizard_uses_new_helpers

finish_tests
