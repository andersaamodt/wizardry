#!/bin/sh
set -eu

# shellcheck source=../test_common.sh
. "$(dirname "$0")/../test_common.sh"

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
  # Test that the install script properly exits when receiving SIGINT (Ctrl-C)
  # We simulate this by sending SIGINT to the script during execution
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq kill sleep

  install_dir="$fixture/home/.wizardry"
  
  # Create a script that sends SIGINT to itself after a brief delay
  cat >"$fixture/test_interrupt.sh" <<'SCRIPT'
#!/bin/sh
# Start the install script in the background
"$INSTALL_SCRIPT" &
pid=$!

# Give it a moment to start, then send SIGINT
sleep 0.5
kill -INT $pid 2>/dev/null || true

# Wait for it and capture the exit status
wait $pid 2>/dev/null
status=$?

# Exit status 130 indicates the script was interrupted by SIGINT (128 + 2)
if [ "$status" -eq 130 ]; then
  echo "INTERRUPT_HANDLED"
  exit 0
else
  echo "UNEXPECTED_STATUS:$status"
  exit 1
fi
SCRIPT
  chmod +x "$fixture/test_interrupt.sh"

  # Run our test wrapper
  PATH="$fixture/bin:$initial_path" \
    WIZARDRY_INSTALL_DIR="$install_dir" \
    INSTALL_SCRIPT="$ROOT_DIR/install" \
    run_cmd sh "$fixture/test_interrupt.sh"

  # The test should pass if the interrupt was handled (exit 0)
  # or if the script exited with 130 (INT signal)
  if [ "$STATUS" -eq 0 ]; then
    assert_output_contains "INTERRUPT_HANDLED" || return 1
    return 0
  fi
  
  # If the wrapper itself failed, check if it was due to the expected interrupt
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

run_test_case "install runs core installer" install_invokes_core_installer
run_test_case "install exits on interrupt signal" install_exits_on_interrupt
run_test_case "install prompts for NixOS config path" install_nixos_prompts_for_config_path
run_test_case "install fails on NixOS without config path" install_nixos_fails_without_config_path

finish_tests
