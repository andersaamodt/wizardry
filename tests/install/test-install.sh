#!/bin/sh
set -eu

# shellcheck source=../test-common.sh
. "$(dirname "$0")/../test-common.sh"

install_invokes_core_installer() {
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  core_log="$fixture/log/core.log"
  cat <<'STUB' >"$fixture/install-core-stub"
#!/bin/sh
echo "core installer invoked" >>"${CORE_LOG:?}"
STUB
  chmod +x "$fixture/install-core-stub"

  install_dir="$fixture/home/.wizardry"
  PATH="$fixture/bin:$initial_path" CORE_LOG="$core_log" WIZARDRY_CORE_INSTALLER="$fixture/install-core-stub" \
    WIZARDRY_INSTALL_ASSUME_YES=1 WIZARDRY_INSTALL_DIR="$install_dir" run_cmd \
    env PATH="$fixture/bin:$initial_path" CORE_LOG="$core_log" WIZARDRY_CORE_INSTALLER="$fixture/install-core-stub" \
    WIZARDRY_INSTALL_ASSUME_YES=1 WIZARDRY_INSTALL_DIR="$install_dir" \
    "$ROOT_DIR/install"

  assert_success || return 1
  assert_file_contains "$core_log" "core installer invoked"
}

install_exits_on_interrupt() {
  # Test that the install script properly handles SIGINT (Ctrl-C)
  # We verify this by checking that the trap is set correctly and the handler exits
  
  # Check that a trap handler for INT exists (flexible matching)
  if ! grep -E "trap.*handle_interrupt.*INT" "$ROOT_DIR/install" >/dev/null; then
    TEST_FAILURE_REASON="trap handler for INT signal not found in install script"
    return 1
  fi
  
  # Check that handle_interrupt function exists and contains exit 130
  if ! grep -A5 "handle_interrupt()" "$ROOT_DIR/install" | grep -q "exit 130"; then
    TEST_FAILURE_REASON="handle_interrupt should exit with code 130"
    return 1
  fi
  
  return 0
}

install_nixos_prompts_for_config_path() {
  # On NixOS without a config file at standard paths, the installer should
  # prompt for the config path. When the user provides a valid path via stdin,
  # the installer should use it.
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a fake configuration.nix in a non-standard location
  custom_config_dir="$fixture/custom-nix"
  mkdir -p "$custom_config_dir"
  touch "$custom_config_dir/configuration.nix"

  install_dir="$fixture/home/.wizardry"
  
  # The test simulates user input: the path to the config file, then "y" to confirm
  run_cmd sh -c "
    printf '%s\n%s\n' '$custom_config_dir/configuration.nix' 'y' | \
    env DETECT_RC_FILE_PLATFORM=nixos \
        WIZARDRY_INSTALL_DIR='$install_dir' \
        HOME='$fixture/home' \
        '$ROOT_DIR/install'
  "

  # Check that the output mentions using the custom configuration
  assert_output_contains "Using configuration file:" || return 1
  assert_output_contains "$custom_config_dir/configuration.nix" || return 1
}

install_nixos_fails_without_config_path() {
  # On NixOS without a config file and non-interactive input,
  # the installer should fail with an error message
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  # Run without providing any config path input (non-interactive)
  run_cmd env DETECT_RC_FILE_PLATFORM=nixos \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      ASK_CANTRIP_INPUT=none \
      "$ROOT_DIR/install" </dev/null

  assert_failure || return 1
  assert_error_contains "No NixOS configuration file found" || return 1
}

install_normalizes_path_without_leading_slash() {
  # Test that paths like "home/testuser/.wizardry" are normalized to
  # "/home/testuser/.wizardry" to prevent path doubling.
  # 
  # The bug being fixed: if the user enters "home/username/.wizardry" at the prompt
  # (without leading /), the old code would prepend $cwd, resulting in paths like
  # "$cwd/home/username/.wizardry" = "/current/dir/home/username/.wizardry"
  # which could lead to doubled paths like "/home/user/home/username/.wizardry".
  #
  # The fix: detect paths that start with common Unix directories (home/, etc/, usr/)
  # and prepend a leading slash.
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create the target directory under /tmp where we have write access
  # We use tmp/wiztest as "tmp/..." matches our normalization pattern
  install_target="$fixture/tmp_install_test"
  mkdir -p "$install_target"

  # Use a path without leading slash. We can't test "home/testuser/.wizardry"
  # directly since /home/testuser doesn't exist and we can't create it.
  # Instead, we verify the normalization logic by checking the script behavior.
  # We test with a path under tmp/ which should get a leading slash added.
  install_dir="tmp/wiztest/.wizardry"
  mkdir -p "/tmp/wiztest"

  # Set HOME to a safe location within the fixture
  run_cmd env DETECT_RC_FILE_PLATFORM=debian \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install" 2>&1

  assert_success || return 1
  # The install should have treated "tmp/wiztest/.wizardry" as "/tmp/wiztest/.wizardry"
  # Check output for the normalized path
  assert_output_contains "/tmp/wiztest/.wizardry" || return 1

  # Cleanup
  rm -rf /tmp/wiztest
}

install_nixos_normalizes_config_path_without_leading_slash() {
  # Test that NixOS config paths like "etc/nixos/configuration.nix" are normalized to
  # "/etc/nixos/configuration.nix".
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create the config file at the absolute path that the normalized path will point to
  mkdir -p /etc/nixos 2>/dev/null || true
  if [ ! -w /etc/nixos ]; then
    # Skip test if we can't create the file
    return 0
  fi
  
  install_dir="$fixture/home/.wizardry"

  # Simulate user entering "etc/nixos/configuration.nix" (without leading slash)
  run_cmd sh -c "
    printf '%s\n%s\n' 'etc/nixos/configuration.nix' 'y' | \
    env DETECT_RC_FILE_PLATFORM=nixos \
        WIZARDRY_INSTALL_DIR='$install_dir' \
        HOME='$fixture/home' \
        '$ROOT_DIR/install'
  "

  # The install should normalize the path and find the file
  assert_output_contains "/etc/nixos/configuration.nix" || return 1
}

install_does_not_double_home_path() {
  # Test that paths starting with $HOME are not doubled due to tilde pattern matching.
  # The bug was that the case pattern ~/\* expands ~ to $HOME in POSIX shell,
  # so a path like "$HOME/.wizardry" incorrectly matched and got $HOME prepended again.
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Set install dir to $fixture/home/.wizardry - an absolute path under HOME
  install_dir="$fixture/home/.wizardry"
  
  run_cmd env DETECT_RC_FILE_PLATFORM=debian \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install" 2>&1

  assert_success || return 1
  # Check that the install path is NOT doubled (no $HOME/$HOME)
  # The path should be $fixture/home/.wizardry, not $fixture/home/$fixture/home/.wizardry
  if printf '%s' "$OUTPUT" | grep -q "$fixture/home/$fixture"; then
    TEST_FAILURE_REASON="path was incorrectly doubled: found $fixture/home/$fixture in output"
    return 1
  fi
  # Verify correct path is used
  assert_output_contains "$install_dir/spells" || return 1
}

run_test_case "install runs core installer" install_invokes_core_installer
run_test_case "install exits on interrupt signal" install_exits_on_interrupt
run_test_case "install prompts for NixOS config path" install_nixos_prompts_for_config_path
run_test_case "install fails on NixOS without config path" install_nixos_fails_without_config_path
run_test_case "install normalizes path without leading slash" install_normalizes_path_without_leading_slash
run_test_case "install normalizes NixOS config path" install_nixos_normalizes_config_path_without_leading_slash
run_test_case "install does not double home path" install_does_not_double_home_path

finish_tests
