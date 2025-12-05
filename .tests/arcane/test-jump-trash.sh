#!/bin/sh
# Behavioral cases (derived from --help and script behavior):
# - jump-trash prints usage with --help
# - jump-trash rejects unknown options
# - jump-trash cds to trash when sourced (via jump_trash function)
# - jump-trash uses inline fallback when detect-trash is missing
# - jump-trash fails if trash directory does not exist
# - jump-trash prompts to memorize when run directly

set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


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

  # Source the spell and call the jump_trash function
  run_cmd sh -c "
    PATH='$stub:$PATH'
    export PATH
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jump_trash
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

  # Source the spell and call the jump_trash function with custom HOME
  run_cmd sh -c "
    PATH='$stub:/bin:/usr/bin'
    HOME='$fake_home'
    export PATH HOME
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jump_trash
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

  # Source and call the jump_trash function
  run_cmd sh -c "
    PATH='$stub:$PATH'
    export PATH
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jump_trash
  "
  assert_failure || return 1
  assert_error_contains "trash directory does not exist" || return 1
}

test_jump_trash_function_help() {
  stub=$(make_tempdir)
  trash_dir="$stub/Trash"
  mkdir -p "$trash_dir"

  cat >"$stub/detect-trash" <<STUB
#!/bin/sh
printf '%s\n' "$trash_dir"
STUB
  chmod +x "$stub/detect-trash"

  # Test jump_trash function --help
  run_cmd sh -c "
    PATH='$stub:$PATH'
    export PATH
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jump_trash --help
  "
  assert_success || return 1
  assert_output_contains "Usage: jump-trash" || return 1
}

test_unknown_option() {
  run_spell "spells/arcane/jump-trash" --unknown
  assert_failure && assert_error_contains "unknown option"
}

run_test_case "jump-trash prints usage" test_help
run_test_case "jump-trash rejects unknown option" test_unknown_option
run_test_case "jump-trash cds when sourced" test_cds_when_sourced
run_test_case "jump-trash uses inline fallback without detect-trash" test_uses_inline_fallback
run_test_case "jump-trash fails if trash dir missing" test_fails_if_trash_dir_missing
run_test_case "jump_trash function shows help" test_jump_trash_function_help

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
  cat >"$stub/ask-yn" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$stub/ask-yn"
  
  link_tools "$stub" sh printf grep cat test sed basename command pwd
  
  # Run jump_trash_install
  run_cmd sh -c "
    PATH='$stub:/bin:/usr/bin'
    HOME='$fake_home'
    DETECT_RC_FILE='$stub/detect-rc-file'
    LEARN_SPELL='$stub/learn'
    JUMP_TRASH_PATH='$ROOT_DIR/spells/arcane/jump-trash'
    WIZARDRY_SKIP_NIX_REBUILD=1
    export PATH HOME DETECT_RC_FILE LEARN_SPELL JUMP_TRASH_PATH WIZARDRY_SKIP_NIX_REBUILD
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jump_trash_install
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

test_nixos_install_runs_home_manager() {
  # Test that on NixOS (nix format), install runs home-manager switch automatically
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
  
  # Create learn stub
  cat >"$stub/learn" <<STUB
#!/bin/sh
exit 0
STUB
  chmod +x "$stub/learn"
  
  # Create home-manager stub that logs its invocation
  home_manager_log="$stub/home-manager.log"
  cat >"$stub/home-manager" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$home_manager_log"
exit 0
STUB
  chmod +x "$stub/home-manager"
  
  link_tools "$stub" sh printf grep cat test sed basename command pwd
  
  # Run jump_trash_install - the spell should call home-manager switch
  run_cmd sh -c "
    PATH='$stub:/bin:/usr/bin'
    HOME='$fake_home'
    DETECT_RC_FILE='$stub/detect-rc-file'
    LEARN_SPELL='$stub/learn'
    JUMP_TRASH_PATH='$ROOT_DIR/spells/arcane/jump-trash'
    export PATH HOME DETECT_RC_FILE LEARN_SPELL JUMP_TRASH_PATH
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jump_trash_install
  "
  assert_success || return 1
  
  # Check that home-manager switch was called
  if [ -f "$home_manager_log" ]; then
    if grep -q "switch" "$home_manager_log"; then
      return 0
    fi
    TEST_FAILURE_REASON="home-manager was not called with 'switch': $(cat "$home_manager_log")"
    return 1
  fi
  TEST_FAILURE_REASON="home-manager was not called"
  return 1
}

test_nixos_install_skips_rebuild_when_disabled() {
  # Test that WIZARDRY_SKIP_NIX_REBUILD=1 skips the rebuild
  stub=$(make_tempdir)
  fake_home="$stub/home"
  mkdir -p "$fake_home"
  
  nix_config="$fake_home/configuration.nix"
  printf '{ config, pkgs, ... }:\n\n{\n}\n' > "$nix_config"
  
  cat >"$stub/detect-rc-file" <<STUB
#!/bin/sh
printf 'platform=nixos\n'
printf 'rc_file=$nix_config\n'
printf 'format=nix\n'
STUB
  chmod +x "$stub/detect-rc-file"
  
  cat >"$stub/learn" <<STUB
#!/bin/sh
exit 0
STUB
  chmod +x "$stub/learn"
  
  # Create home-manager stub that logs its invocation
  home_manager_log="$stub/home-manager.log"
  cat >"$stub/home-manager" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$home_manager_log"
exit 0
STUB
  chmod +x "$stub/home-manager"
  
  link_tools "$stub" sh printf grep cat test sed basename command pwd
  
  # Run install with WIZARDRY_SKIP_NIX_REBUILD=1
  run_cmd sh -c "
    PATH='$stub:/bin:/usr/bin'
    HOME='$fake_home'
    DETECT_RC_FILE='$stub/detect-rc-file'
    LEARN_SPELL='$stub/learn'
    JUMP_TRASH_PATH='$ROOT_DIR/spells/arcane/jump-trash'
    WIZARDRY_SKIP_NIX_REBUILD=1
    export PATH HOME DETECT_RC_FILE LEARN_SPELL JUMP_TRASH_PATH WIZARDRY_SKIP_NIX_REBUILD
    . '$ROOT_DIR/spells/arcane/jump-trash'
    jump_trash_install
  "
  assert_success || return 1
  
  # Check that home-manager was NOT called
  if [ -f "$home_manager_log" ]; then
    TEST_FAILURE_REASON="home-manager should not have been called when WIZARDRY_SKIP_NIX_REBUILD=1"
    return 1
  fi
  return 0
}

run_test_case "jump-trash uses nix format on NixOS" test_nixos_uses_nix_format
run_test_case "jump-trash nixos install runs home-manager" test_nixos_install_runs_home_manager
run_test_case "jump-trash nixos install skips rebuild when disabled" test_nixos_install_skips_rebuild_when_disabled

finish_tests
