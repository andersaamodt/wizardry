#!/bin/sh
# Behavioral cases (derived from --help):
# - learn prints usage

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Skip nix rebuild in tests since nixos-rebuild and home-manager aren't available
export WIZARDRY_SKIP_NIX_REBUILD=1
# Skip confirmation prompts in tests
export WIZARDRY_SKIP_CONFIRM=1

# Helper to create a stub detect-rc-file for a specific rc file
make_detect_stub() {
  target_rc=$1
  stub_dir=$(_make_tempdir)
  stub="$stub_dir/detect-rc-file"
  cat >"$stub" <<EOF
#!/bin/sh
printf '%s\\n' '$target_rc'
EOF
  chmod +x "$stub"
  printf '%s' "$stub_dir"
}

test_help() {
  _run_spell "spells/spellcraft/learn" --help
  _assert_success && _assert_error_contains "Usage: learn"
}

test_missing_args() {
  _run_spell "spells/spellcraft/learn"
  _assert_failure && _assert_error_contains "Usage: learn"
}

test_rejects_invalid_name() {
  rc="$WIZARDRY_TMPDIR/rc"
  stub_dir=$(make_detect_stub "$rc")
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell "bad name" add <<'EOF'
echo hi
EOF
  _assert_failure && _assert_error_contains "spell names may contain only"
}

test_adds_inline_spell() {
  rc="$WIZARDRY_TMPDIR/inline_rc"
  stub_dir=$(make_detect_stub "$rc")
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell summon add <<'EOF'
export HELLO=WORLD
EOF
  _assert_success
  _assert_file_contains "$rc" "export HELLO=WORLD # wizardry: summon"
}

test_adds_and_readds_block_spell_idempotently() {
  rc="$WIZARDRY_TMPDIR/block_rc"
  stub_dir=$(make_detect_stub "$rc")
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell portal add <<'EOF'
echo first
echo second
EOF
  _assert_success
  first="$(cat "$rc")"

  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell portal add <<'EOF'
echo first
echo second
EOF
  _assert_success
  second="$(cat "$rc")"
  [ "$first" = "$second" ] || { TEST_FAILURE_REASON="expected idempotent block add"; return 1; }
  _assert_file_contains "$rc" "# wizardry: portal begin lines=2"
  _assert_file_contains "$rc" "# wizardry: portal end"
}

test_remove_reports_missing_file() {
  missing="$WIZARDRY_TMPDIR/absent_rc"
  stub_dir=$(make_detect_stub "$missing")
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell phantom remove
  _assert_failure && _assert_error_contains "cannot remove from missing file"
}

test_remove_cleans_block() {
  rc="$WIZARDRY_TMPDIR/cleanup_rc"
  stub_dir=$(make_detect_stub "$rc")
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell vanish add <<'EOF'
echo vanish
echo more
EOF
  _assert_success
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell vanish remove
  _assert_success
  [ ! -s "$rc" ] || { TEST_FAILURE_REASON="expected file empty after remove"; return 1; }
}

test_status_reflects_presence() {
  rc="$WIZARDRY_TMPDIR/status_rc"
  stub_dir=$(make_detect_stub "$rc")
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell statuser status
  _assert_failure

  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell statuser add <<'EOF'
echo status
EOF
  _assert_success
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell statuser status
  _assert_success
}

_run_test_case "learn prints usage" test_help
_run_test_case "learn errors without required arguments" test_missing_args
_run_test_case "learn rejects invalid spell names" test_rejects_invalid_name
_run_test_case "learn adds inline spell content" test_adds_inline_spell
_run_test_case "learn adds blocks idempotently" test_adds_and_readds_block_spell_idempotently
_run_test_case "learn fails to remove missing files" test_remove_reports_missing_file
_run_test_case "learn removes previously added blocks" test_remove_cleans_block
_run_test_case "learn status tracks presence" test_status_reflects_presence

# Helper to create a stub detect-rc-file for nix format
make_nix_detect_stub() {
  target_rc=$1
  stub_dir=$(_make_tempdir)
  stub="$stub_dir/detect-rc-file"
  cat >"$stub" <<EOF
#!/bin/sh
printf '%s\\n' '$target_rc'
EOF
  chmod +x "$stub"
  printf '%s' "$stub_dir"
}

# Nix format tests
test_nix_format_adds_shell_init() {
  rc="$WIZARDRY_TMPDIR/test_nix.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$rc"
  stub_dir=$(make_nix_detect_stub "$rc")
  
  # Auto-detects nix format from .nix extension
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell myspell add <<'EOF'
source "/path/to/spell"
EOF
  _assert_success || return 1
  _assert_file_contains "$rc" "programs.bash.initExtra" || return 1
  _assert_file_contains "$rc" "wizardry: myspell" || return 1
  _assert_file_contains "$rc" 'source "/path/to/spell"' || return 1
}

test_nix_format_auto_detects_from_extension() {
  rc="$WIZARDRY_TMPDIR/auto_detect.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$rc"
  stub_dir=$(make_nix_detect_stub "$rc")
  
  # Don't specify --format, let it auto-detect from .nix extension
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell autospell add <<'EOF'
source "/path/to/spell"
EOF
  _assert_success || return 1
  _assert_file_contains "$rc" "programs.bash.initExtra" || return 1
}

test_nix_format_status_works() {
  rc="$WIZARDRY_TMPDIR/status_nix.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$rc"
  stub_dir=$(make_nix_detect_stub "$rc")
  
  # Status should fail when not present
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell nixstatus status
  _assert_failure || return 1
  
  # Add the spell
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell nixstatus add <<'EOF'
source "/path/to/spell"
EOF
  _assert_success || return 1
  
  # Status should succeed when present
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell nixstatus status
  _assert_success || return 1
}

test_nix_format_remove_works() {
  rc="$WIZARDRY_TMPDIR/remove_nix.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$rc"
  stub_dir=$(make_nix_detect_stub "$rc")
  
  # Add the spell
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell nixremove add <<'EOF'
source "/path/to/spell"
EOF
  _assert_success || return 1
  
  # Verify it was added
  if ! grep -q "wizardry: nixremove" "$rc"; then
    TEST_FAILURE_REASON="spell was not added"
    return 1
  fi
  
  # Remove it
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell nixremove remove
  _assert_success || return 1
  
  # Verify it was removed
  if grep -q "wizardry: nixremove" "$rc"; then
    TEST_FAILURE_REASON="spell was not removed"
    return 1
  fi
}

test_nix_format_zsh_shell_option() {
  rc="$WIZARDRY_TMPDIR/zsh_nix.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$rc"
  stub_dir=$(make_nix_detect_stub "$rc")
  
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell zshspell --shell zsh add <<'EOF'
source "/path/to/spell"
EOF
  _assert_success || return 1
  _assert_file_contains "$rc" "programs.zsh.initExtra" || return 1
}

test_learn_auto_detects_rc_file() {
  # Test that learn always auto-detects rc file
  tmpdir=$(_make_tempdir)
  rc="$tmpdir/.bashrc"
  stub_dir=$(make_detect_stub "$rc")
  
  PATH="$stub_dir:$PATH" _run_spell "spells/spellcraft/learn" --spell autospell add <<'EOF'
source "/path/to/spell"
EOF
  _assert_success || return 1
  _assert_file_contains "$rc" "source \"/path/to/spell\"" || return 1
}

_run_test_case "learn nix format adds shell init" test_nix_format_adds_shell_init
_run_test_case "learn nix format auto-detects from extension" test_nix_format_auto_detects_from_extension
_run_test_case "learn nix format status works" test_nix_format_status_works
_run_test_case "learn nix format remove works" test_nix_format_remove_works
_run_test_case "learn nix format zsh shell option" test_nix_format_zsh_shell_option
_run_test_case "learn auto-detects rc file" test_learn_auto_detects_rc_file

_finish_tests
