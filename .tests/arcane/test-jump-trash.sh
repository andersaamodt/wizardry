#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - jump-trash prints usage with --help
# - jump-trash cds to trash when sourced (via jtrash function)
# - jump-trash uses inline fallback when detect-trash is missing
# - jump-trash fails if trash directory does not exist
# - jump-trash prompts to memorize when run directly

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/arcane/jump-trash" --help
  assert_success && assert_output_contains "Usage: jump-trash"
}

test_cds_when_sourced() {
  stub=$(make_tempdir)
  trash_dir="$stub/Trash"
  mkdir -p "$trash_dir"

  # Create detect-trash stub that returns our test trash dir
  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$trash_dir"
STUB
  chmod +x "$stub/detect-trash"

  # Source the spell and call the jtrash function
  run_cmd sh -c "
    PATH='$stub:$PATH'
    export PATH
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jtrash
    pwd
  "
  assert_success || return 1
  assert_output_contains "teleport to the trash" || return 1
  assert_output_contains "$trash_dir" || return 1
}

test_uses_inline_fallback() {
  stub=$(make_tempdir)
  # Create a fake trash dir based on the system's expected location
  # We'll use a custom HOME to control the path
  fake_home="$stub/home"
  trash_dir="$fake_home/.local/share/Trash/files"
  mkdir -p "$trash_dir"
  
  # Create uname stub for Linux
  cat >"$stub/uname" <<'STUB'
#!/bin/sh
printf 'Linux\n'
STUB
  chmod +x "$stub/uname"
  
  # Provide only basic utilities, no detect-trash
  link_tools "$stub" sh printf test cd

  # Source the spell and call the jtrash function with custom HOME
  # Include imps directory in PATH for declare-globals
  run_cmd sh -c "
    PATH='$stub:$ROOT_DIR/spells/.imps:/bin:/usr/bin'
    HOME='$fake_home'
    export PATH HOME
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jtrash
    pwd
  "
  assert_success || return 1
  assert_output_contains "teleport to the trash" || return 1
}

test_fails_if_trash_dir_missing() {
  stub=$(make_tempdir)
  nonexistent_dir="$stub/nonexistent/Trash"

  # Create detect-trash stub that returns a nonexistent path
  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$nonexistent_dir"
STUB
  chmod +x "$stub/detect-trash"

  # Source and call the jtrash function
  run_cmd sh -c "
    PATH='$stub:$PATH'
    export PATH
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jtrash
  "
  assert_failure || return 1
  assert_error_contains "trash directory does not exist" || return 1
}

test_jtrash_function_help() {
  stub=$(make_tempdir)
  trash_dir="$stub/Trash"
  mkdir -p "$trash_dir"

  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$trash_dir"
STUB
  chmod +x "$stub/detect-trash"

  # Test jtrash function --help
  run_cmd sh -c "
    PATH='$stub:$PATH'
    export PATH
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jtrash --help
  "
  assert_success || return 1
  assert_output_contains "Usage: jtrash" || return 1
}

run_test_case "jump-trash prints usage" test_help
run_test_case "jump-trash cds when sourced" test_cds_when_sourced
run_test_case "jump-trash uses inline fallback without detect-trash" test_uses_inline_fallback
run_test_case "jump-trash fails if trash dir missing" test_fails_if_trash_dir_missing
run_test_case "jtrash function shows help" test_jtrash_function_help

test_nixos_uses_nix_format() {
  # Test that on NixOS (nix format), jump-trash calls learn without --rc-file
  # (learn auto-detects rc file and format)
  stub=$(make_tempdir)
  fake_home="$stub/home"
  mkdir -p "$fake_home"
  
  # Create a nix config file
  nix_config="$fake_home/configuration.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_config"
  
  # Create detect-rc-file stub that returns nix format
  cat >"$stub/detect-rc-file" <<STUB
#!/bin/sh
printf 'platform=nixos\n'
printf 'rc_file=$nix_config\n'
printf 'format=nix\n'
STUB
  chmod +x "$stub/detect-rc-file"
  
  # Create learn stub that records what it was called with
  learn_log="$stub/learn.log"
  cat >"$stub/learn" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$learn_log"
# Simulate success
exit 0
STUB
  chmod +x "$stub/learn"
  
  # Create ask_yn stub that always says yes
  cat >"$stub/ask_yn" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub/ask_yn"
  
  link_tools "$stub" sh printf grep cat test sed basename command pwd
  
  # Run jtrash_install - include imps directory for declare-globals
  run_cmd sh -c "
    PATH='$stub:$ROOT_DIR/spells/.imps:/bin:/usr/bin'
    HOME='$fake_home'
    DETECT_RC_FILE='$stub/detect-rc-file'
    LEARN_SPELL='$stub/learn'
    JUMP_TRASH_PATH='$ROOT_DIR/spells/arcane/jump-trash'
    export PATH HOME DETECT_RC_FILE LEARN_SPELL JUMP_TRASH_PATH
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jtrash_install
  "
  assert_success || return 1
  
  # Check that learn was called with --spell (not --rc-file since learn auto-detects)
  if [ -f "$learn_log" ]; then
    if grep -q "\-\-spell jump-trash" "$learn_log"; then
      return 0
    fi
    TEST_FAILURE_REASON="learn was not called with --spell: $(cat "$learn_log")"
    return 1
  fi
  TEST_FAILURE_REASON="learn was not called"
  return 1
}

run_test_case "jump-trash uses nix format on NixOS" test_nixos_uses_nix_format

finish_tests
