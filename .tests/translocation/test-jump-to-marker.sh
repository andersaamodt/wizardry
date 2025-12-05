#!/bin/sh
# Behavioral cases (derived from --help):
# - jump-to-marker prints usage
# - jump to specific marker
# - jump cycles through markers when called repeatedly
# - jump fails when no markers exist

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/translocation/jump-to-marker" --help
  _assert_success && _assert_output_contains "Usage: jump"
}

test_unknown_option_fails() {
  _run_spell "spells/translocation/jump-to-marker" --bad
  _assert_failure && _assert_error_contains "unknown option"
}

test_install_requires_helpers() {
  helpers_dir="$WIZARDRY_TMPDIR/helpers-missing"
  mkdir -p "$helpers_dir"
  PATH="/bin:/usr/bin" JUMP_TO_MARKER_HELPERS_DIR="$helpers_dir" JUMP_TO_MARKERS_DIR="$WIZARDRY_TMPDIR/markers" \
    _run_spell "spells/translocation/jump-to-marker" --install
  _assert_failure && _assert_error_contains "required helper 'detect-rc-file' is missing"
}

run_jump() {
  marker_arg=${1:-}
  markers_dir=${2:-$WIZARDRY_TMPDIR/markers}
  RUN_CMD_WORKDIR=${3:-$WIZARDRY_TMPDIR}
  PATH="/bin:/usr/bin"
  JUMP_TO_MARKERS_DIR="$markers_dir"
  export JUMP_TO_MARKERS_DIR PATH
  if [ -n "$marker_arg" ]; then
    _run_cmd sh -c ". \"$ROOT_DIR/spells/translocation/jump-to-marker\"; jump \"$marker_arg\""
  else
    _run_cmd sh -c ". \"$ROOT_DIR/spells/translocation/jump-to-marker\"; jump"
  fi
}

test_jump_requires_markers_dir() {
  missing_dir="$WIZARDRY_TMPDIR/no-markers"
  rm -rf "$missing_dir"
  run_jump "" "$missing_dir"
  _assert_failure && _assert_output_contains "No markers have been set"
}

test_jump_requires_specific_marker() {
  markers_dir="$WIZARDRY_TMPDIR/markers-test"
  mkdir -p "$markers_dir"
  run_jump "nonexistent" "$markers_dir"
  _assert_failure && _assert_output_contains "No marker 'nonexistent' found"
}

test_jump_rejects_blank_marker() {
  markers_dir="$WIZARDRY_TMPDIR/markers-blank"
  mkdir -p "$markers_dir"
  : >"$markers_dir/1"
  run_jump "1" "$markers_dir"
  _assert_failure && _assert_output_contains "is blank"
}

test_jump_rejects_missing_destination() {
  markers_dir="$WIZARDRY_TMPDIR/markers-missing-dest"
  mkdir -p "$markers_dir"
  printf '%s\n' "$WIZARDRY_TMPDIR/nonexistent" >"$markers_dir/1"
  run_jump "1" "$markers_dir"
  _assert_failure && _assert_output_contains "no longer exists"
}

test_jump_detects_current_location() {
  destination="$WIZARDRY_TMPDIR/already-here"
  markers_dir="$WIZARDRY_TMPDIR/markers-here"
  mkdir -p "$destination" "$markers_dir"
  # Write resolved path to marker to match what jump will compare
  destination_resolved=$(cd "$destination" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$destination_resolved" >"$markers_dir/1"
  run_jump "1" "$markers_dir" "$destination"
  _assert_success && _assert_output_contains "already standing"
}

test_jump_changes_directory() {
  start_dir="$WIZARDRY_TMPDIR/start"
  destination="$WIZARDRY_TMPDIR/portal"
  markers_dir="$WIZARDRY_TMPDIR/markers-jump"
  mkdir -p "$start_dir" "$destination" "$markers_dir"
  # Write resolved path to marker
  destination_resolved=$(cd "$destination" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$destination_resolved" >"$markers_dir/1"
  run_jump "1" "$markers_dir" "$start_dir"
  _assert_success
}

test_jump_to_named_marker() {
  start_dir="$WIZARDRY_TMPDIR/start-named"
  destination="$WIZARDRY_TMPDIR/portal-named"
  markers_dir="$WIZARDRY_TMPDIR/markers-named"
  mkdir -p "$start_dir" "$destination" "$markers_dir"
  destination_resolved=$(cd "$destination" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$destination_resolved" >"$markers_dir/alpha"
  run_jump "alpha" "$markers_dir" "$start_dir"
  _assert_success
}

test_jump_lists_available_markers() {
  markers_dir="$WIZARDRY_TMPDIR/markers-list"
  dest="$WIZARDRY_TMPDIR/dest-list"
  mkdir -p "$markers_dir" "$dest"
  dest_resolved=$(cd "$dest" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$dest_resolved" >"$markers_dir/1"
  printf '%s\n' "$dest_resolved" >"$markers_dir/alpha"
  run_jump "nonexistent" "$markers_dir"
  _assert_failure
  _assert_output_contains "Available markers:"
  _assert_output_contains "1"
  _assert_output_contains "alpha"
}

test_jump_zero_cycles() {
  start_dir="$WIZARDRY_TMPDIR/start-zero"
  dest1="$WIZARDRY_TMPDIR/dest1"
  dest2="$WIZARDRY_TMPDIR/dest2"
  markers_dir="$WIZARDRY_TMPDIR/markers-zero"
  mkdir -p "$start_dir" "$dest1" "$dest2" "$markers_dir"
  dest1_resolved=$(cd "$dest1" && pwd -P | sed 's|//|/|g')
  dest2_resolved=$(cd "$dest2" && pwd -P | sed 's|//|/|g')
  printf '%s\n' "$dest1_resolved" >"$markers_dir/1"
  printf '%s\n' "$dest2_resolved" >"$markers_dir/2"
  # jump 0 should behave like jump with no args (start at 1)
  run_jump "0" "$markers_dir" "$start_dir"
  _assert_success
}

test_nixos_install_runs_home_manager() {
  # Test that on NixOS (nix format), install runs home-manager switch automatically
  stub=$(_make_tempdir)
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
  
  _link_tools "$stub" sh printf grep cat test sed basename command pwd
  
  # Run install - the spell should call home-manager switch
  _run_cmd sh -c "
    PATH='$stub:/bin:/usr/bin'
    HOME='$fake_home'
    DETECT_RC_FILE='$stub/detect-rc-file'
    LEARN_SPELL='$stub/learn'
    JUMP_TO_MARKER_PATH='$ROOT_DIR/spells/translocation/jump-to-marker'
    export PATH HOME DETECT_RC_FILE LEARN_SPELL JUMP_TO_MARKER_PATH
    . '$ROOT_DIR/spells/translocation/jump-to-marker'
    install
  "
  _assert_success || return 1
  
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
  stub=$(_make_tempdir)
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
  
  learn_log="$stub/learn.log"
  cat >"$stub/learn" <<STUB
#!/bin/sh
printf '%s\n' "\$*" >>"$learn_log"
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
  
  _link_tools "$stub" sh printf grep cat test sed basename command pwd
  
  # Run install with WIZARDRY_SKIP_NIX_REBUILD=1
  _run_cmd sh -c "
    PATH='$stub:/bin:/usr/bin'
    HOME='$fake_home'
    DETECT_RC_FILE='$stub/detect-rc-file'
    LEARN_SPELL='$stub/learn'
    JUMP_TO_MARKER_PATH='$ROOT_DIR/spells/translocation/jump-to-marker'
    WIZARDRY_SKIP_NIX_REBUILD=1
    export PATH HOME DETECT_RC_FILE LEARN_SPELL JUMP_TO_MARKER_PATH WIZARDRY_SKIP_NIX_REBUILD
    . '$ROOT_DIR/spells/translocation/jump-to-marker'
    install
  "
  _assert_success || return 1
  
  # Check that home-manager was NOT called
  if [ -f "$home_manager_log" ]; then
    TEST_FAILURE_REASON="home-manager should not have been called when WIZARDRY_SKIP_NIX_REBUILD=1"
    return 1
  fi
  return 0
}

test_install_adds_jump_alias() {
  # Test that install adds the 'jump' alias to the rc file
  stub=$(_make_tempdir)
  fake_home="$stub/home"
  mkdir -p "$fake_home"
  rc_file="$fake_home/.bashrc"
  touch "$rc_file"
  
  # Create detect-rc-file stub
  cat >"$stub/detect-rc-file" <<STUB
#!/bin/sh
printf 'platform=linux\n'
printf 'rc_file=$rc_file\n'
printf 'format=shell\n'
STUB
  chmod +x "$stub/detect-rc-file"
  
  # Create learn stub that captures stdin content
  learn_stdin="$stub/learn_stdin.txt"
  cat >"$stub/learn" <<STUB
#!/bin/sh
cat >"$learn_stdin"
exit 0
STUB
  chmod +x "$stub/learn"
  
  _link_tools "$stub" sh printf grep cat test sed basename command pwd
  
  # Run install
  _run_cmd sh -c "
    PATH='$stub:/bin:/usr/bin'
    HOME='$fake_home'
    DETECT_RC_FILE='$stub/detect-rc-file'
    LEARN_SPELL='$stub/learn'
    JUMP_TO_MARKER_PATH='$ROOT_DIR/spells/translocation/jump-to-marker'
    export PATH HOME DETECT_RC_FILE LEARN_SPELL JUMP_TO_MARKER_PATH
    . '$ROOT_DIR/spells/translocation/jump-to-marker'
    install
  "
  _assert_success || return 1
  
  # Verify the content passed to learn contains the alias
  if [ ! -f "$learn_stdin" ]; then
    TEST_FAILURE_REASON="learn was not called with stdin content"
    return 1
  fi
  if ! grep -q "alias jump=jump-to-marker" "$learn_stdin"; then
    TEST_FAILURE_REASON="install did not add 'alias jump=jump-to-marker': $(cat "$learn_stdin")"
    return 1
  fi
  return 0
}

_run_test_case "jump-to-marker prints usage" test_help
_run_test_case "jump-to-marker rejects unknown options" test_unknown_option_fails
_run_test_case "jump-to-marker fails when markers dir is missing" test_jump_requires_markers_dir
_run_test_case "jump-to-marker fails when specific marker is missing" test_jump_requires_specific_marker
_run_test_case "jump-to-marker fails when marker is blank" test_jump_rejects_blank_marker
_run_test_case "jump-to-marker fails when destination is missing" test_jump_rejects_missing_destination
_run_test_case "jump-to-marker reports when already at destination" test_jump_detects_current_location
_run_test_case "jump-to-marker jumps to marked directory" test_jump_changes_directory
_run_test_case "jump-to-marker jumps to named marker" test_jump_to_named_marker
_run_test_case "jump-to-marker lists available markers on error" test_jump_lists_available_markers
_run_test_case "jump 0 cycles like jump with no args" test_jump_zero_cycles
_finish_tests
