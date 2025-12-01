#!/bin/sh
# Behavioral cases (derived from --help):
# - learn prints usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/spellcraft/learn" --help
  assert_success && assert_error_contains "Usage: learn"
}

test_missing_args() {
  run_spell "spells/spellcraft/learn"
  assert_failure && assert_error_contains "Usage: learn"
}

test_rejects_invalid_name() {
  run_spell "spells/spellcraft/learn" --rc-file "$WIZARDRY_TMPDIR/rc" --spell "bad name" add <<'EOF'
echo hi
EOF
  assert_failure && assert_error_contains "spell names may contain only"
}

test_adds_inline_spell() {
  rc="$WIZARDRY_TMPDIR/inline_rc"
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell summon add <<'EOF'
export HELLO=WORLD
EOF
  assert_success
  assert_file_contains "$rc" "export HELLO=WORLD # wizardry: summon"
}

test_adds_and_readds_block_spell_idempotently() {
  rc="$WIZARDRY_TMPDIR/block_rc"
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell portal add <<'EOF'
echo first
echo second
EOF
  assert_success
  first="$(cat "$rc")"

  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell portal add <<'EOF'
echo first
echo second
EOF
  assert_success
  second="$(cat "$rc")"
  [ "$first" = "$second" ] || { TEST_FAILURE_REASON="expected idempotent block add"; return 1; }
  assert_file_contains "$rc" "# wizardry: portal begin lines=2"
  assert_file_contains "$rc" "# wizardry: portal end"
}

test_remove_reports_missing_file() {
  missing="$WIZARDRY_TMPDIR/absent_rc"
  run_spell "spells/spellcraft/learn" --rc-file "$missing" --spell phantom remove
  assert_failure && assert_error_contains "cannot remove from missing file"
}

test_remove_cleans_block() {
  rc="$WIZARDRY_TMPDIR/cleanup_rc"
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell vanish add <<'EOF'
echo vanish
echo more
EOF
  assert_success
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell vanish remove
  assert_success
  [ ! -s "$rc" ] || { TEST_FAILURE_REASON="expected file empty after remove"; return 1; }
}

test_status_reflects_presence() {
  rc="$WIZARDRY_TMPDIR/status_rc"
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell statuser status
  assert_failure

  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell statuser add <<'EOF'
echo status
EOF
  assert_success
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell statuser status
  assert_success
}

run_test_case "learn prints usage" test_help
run_test_case "learn errors without required arguments" test_missing_args
run_test_case "learn rejects invalid spell names" test_rejects_invalid_name
run_test_case "learn adds inline spell content" test_adds_inline_spell
run_test_case "learn adds blocks idempotently" test_adds_and_readds_block_spell_idempotently
run_test_case "learn fails to remove missing files" test_remove_reports_missing_file
run_test_case "learn removes previously added blocks" test_remove_cleans_block
run_test_case "learn status tracks presence" test_status_reflects_presence

# Nix format tests
test_nix_format_adds_shell_init() {
  rc="$WIZARDRY_TMPDIR/test_nix.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$rc"
  
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell myspell --format nix add <<'EOF'
source "/path/to/spell"
EOF
  assert_success || return 1
  assert_file_contains "$rc" "programs.bash.initExtra" || return 1
  assert_file_contains "$rc" "wizardry-shell: myspell" || return 1
  assert_file_contains "$rc" 'source "/path/to/spell"' || return 1
}

test_nix_format_auto_detects_from_extension() {
  rc="$WIZARDRY_TMPDIR/auto_detect.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$rc"
  
  # Don't specify --format, let it auto-detect from .nix extension
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell autospell add <<'EOF'
source "/path/to/spell"
EOF
  assert_success || return 1
  assert_file_contains "$rc" "programs.bash.initExtra" || return 1
}

test_nix_format_status_works() {
  rc="$WIZARDRY_TMPDIR/status_nix.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$rc"
  
  # Status should fail when not present
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell nixstatus --format nix status
  assert_failure || return 1
  
  # Add the spell
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell nixstatus --format nix add <<'EOF'
source "/path/to/spell"
EOF
  assert_success || return 1
  
  # Status should succeed when present
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell nixstatus --format nix status
  assert_success || return 1
}

test_nix_format_remove_works() {
  rc="$WIZARDRY_TMPDIR/remove_nix.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$rc"
  
  # Add the spell
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell nixremove --format nix add <<'EOF'
source "/path/to/spell"
EOF
  assert_success || return 1
  
  # Verify it was added
  if ! grep -q "wizardry-shell: nixremove" "$rc"; then
    TEST_FAILURE_REASON="spell was not added"
    return 1
  fi
  
  # Remove it
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell nixremove --format nix remove
  assert_success || return 1
  
  # Verify it was removed
  if grep -q "wizardry-shell: nixremove" "$rc"; then
    TEST_FAILURE_REASON="spell was not removed"
    return 1
  fi
}

test_nix_format_zsh_shell_option() {
  rc="$WIZARDRY_TMPDIR/zsh_nix.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$rc"
  
  run_spell "spells/spellcraft/learn" --rc-file "$rc" --spell zshspell --format nix --shell zsh add <<'EOF'
source "/path/to/spell"
EOF
  assert_success || return 1
  assert_file_contains "$rc" "programs.zsh.initExtra" || return 1
}

test_learn_auto_detects_rc_file() {
  # Test that learn can auto-detect rc file when --rc-file is not provided
  tmpdir=$(make_tempdir)
  rc="$tmpdir/.bashrc"
  
  # Create a detect-rc-file stub
  stub_detect="$tmpdir/detect-rc-file"
  cat >"$stub_detect" <<STUB
#!/bin/sh
printf 'rc_file=$rc\n'
printf 'platform=debian\n'
printf 'format=shell\n'
STUB
  chmod +x "$stub_detect"
  
  # Run learn without --rc-file
  run_spell "spells/spellcraft/learn" --spell autospell add <<'EOF'
source "/path/to/spell"
EOF
  # This will fail without detect-rc-file in PATH, so we use env override
  DETECT_RC_FILE="$stub_detect" run_spell "spells/spellcraft/learn" --spell autospell add <<'EOF'
source "/path/to/spell"
EOF
  assert_success || return 1
  assert_file_contains "$rc" "source \"/path/to/spell\"" || return 1
}

run_test_case "learn nix format adds shell init" test_nix_format_adds_shell_init
run_test_case "learn nix format auto-detects from extension" test_nix_format_auto_detects_from_extension
run_test_case "learn nix format status works" test_nix_format_status_works
run_test_case "learn nix format remove works" test_nix_format_remove_works
run_test_case "learn nix format zsh shell option" test_nix_format_zsh_shell_option
run_test_case "learn auto-detects rc file" test_learn_auto_detects_rc_file

finish_tests
