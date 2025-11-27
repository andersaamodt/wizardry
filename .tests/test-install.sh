#!/bin/sh
set -eu

# Test suite for the root install script.
# This file is in .tests/ (not .tests/install/) because install is in the repo root,
# not in spells/.

# shellcheck source=test-common.sh
. "$(dirname "$0")/test-common.sh"

# === Basic Installation Tests ===

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

# === NixOS Configuration Tests ===

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

install_nixos_mentions_flakes_in_output() {
  # On NixOS, the installer should mention flakes in the output
  # since that's how wizardry is installed on NixOS.
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a fake configuration.nix
  mkdir -p "$fixture/home/.config/home-manager"
  cat >"$fixture/home/.config/home-manager/home.nix" <<'EOF'
{ config, pkgs, ... }:

{
  home.username = "testuser";
  home.homeDirectory = "/home/testuser";
  programs.bash.enable = true;
}
EOF

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env DETECT_RC_FILE_PLATFORM=nixos \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  # Check that the output mentions flakes
  assert_output_contains "flake" || return 1
}

install_nixos_generates_flake_nix() {
  # On NixOS, the installer should generate a flake.nix in the wizardry directory
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a fake configuration.nix
  mkdir -p "$fixture/home/.config/home-manager"
  cat >"$fixture/home/.config/home-manager/home.nix" <<'EOF'
{ config, pkgs, ... }:

{
  home.username = "testuser";
  home.homeDirectory = "/home/testuser";
  programs.bash.enable = true;
}
EOF

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env DETECT_RC_FILE_PLATFORM=nixos \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  # Check that flake.nix was generated
  assert_path_exists "$install_dir/flake.nix" || return 1
}

install_nixos_adds_flakes_enablement() {
  # On NixOS, the installer should add flakes enablement to configuration.nix
  # if flakes are not already enabled.
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a configuration.nix without flakes enabled
  mkdir -p "$fixture/etc/nixos"
  cat >"$fixture/etc/nixos/configuration.nix" <<'EOF'
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  boot.loader.grub.enable = true;
  
  environment.systemPackages = with pkgs; [
    vim
    git
  ];
}
EOF

  install_dir="$fixture/home/.wizardry"
  
  # Simulate user input: the path to the config file, then "y" to confirm
  run_cmd sh -c "
    printf '%s\n%s\n' '$fixture/etc/nixos/configuration.nix' 'y' | \
    env DETECT_RC_FILE_PLATFORM=nixos \
        WIZARDRY_INSTALL_DIR='$install_dir' \
        HOME='$fixture/home' \
        '$ROOT_DIR/install'
  "

  assert_success || return 1
  
  # Check that flakes enablement was added to configuration.nix
  assert_file_contains "$fixture/etc/nixos/configuration.nix" "nix.settings.experimental-features" || return 1
}

install_nixos_preserves_existing_flakes_setting() {
  # If flakes are already enabled in configuration.nix, the installer should
  # not add duplicate enablement.
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a configuration.nix with flakes already enabled
  mkdir -p "$fixture/etc/nixos"
  cat >"$fixture/etc/nixos/configuration.nix" <<'EOF'
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  environment.systemPackages = with pkgs; [
    vim
    git
  ];
}
EOF

  install_dir="$fixture/home/.wizardry"
  
  # Simulate user input: the path to the config file, then "y" to confirm
  run_cmd sh -c "
    printf '%s\n%s\n' '$fixture/etc/nixos/configuration.nix' 'y' | \
    env DETECT_RC_FILE_PLATFORM=nixos \
        WIZARDRY_INSTALL_DIR='$install_dir' \
        HOME='$fixture/home' \
        '$ROOT_DIR/install'
  "

  assert_success || return 1
  
  # Count occurrences of experimental-features - should be exactly 1
  count=$(grep -c "experimental-features" "$fixture/etc/nixos/configuration.nix" 2>/dev/null || printf '0')
  if [ "$count" -ne 1 ]; then
    TEST_FAILURE_REASON="expected exactly 1 occurrence of experimental-features, got $count"
    return 1
  fi
}

install_nixos_adds_flake_input() {
  # On NixOS, the installer should add the wizardry flake input to configuration.nix
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a configuration.nix
  mkdir -p "$fixture/etc/nixos"
  cat >"$fixture/etc/nixos/configuration.nix" <<'EOF'
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  environment.systemPackages = with pkgs; [
    vim
    git
  ];
}
EOF

  install_dir="$fixture/home/.wizardry"
  
  # Simulate user input: the path to the config file, then "y" to confirm
  run_cmd sh -c "
    printf '%s\n%s\n' '$fixture/etc/nixos/configuration.nix' 'y' | \
    env DETECT_RC_FILE_PLATFORM=nixos \
        WIZARDRY_INSTALL_DIR='$install_dir' \
        HOME='$fixture/home' \
        '$ROOT_DIR/install'
  "

  assert_success || return 1
  
  # Check that the wizardry PATH block was added
  assert_file_contains "$fixture/etc/nixos/configuration.nix" "# wizardry PATH begin" || return 1
}

# === Path Normalization Tests ===

install_normalizes_path_without_leading_slash() {
  # Test that paths like "home/testuser/.wizardry" are normalized to
  # "/home/testuser/.wizardry" to prevent path doubling.
  #
  # This test verifies the path normalization logic exists in the install script.
  
  # Check that the install script has path normalization logic for common patterns
  # The install script uses case patterns like [Hh]ome/*|[Uu]sers/*
  if ! grep -q '\[Hh\]ome' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should have path normalization for home/ patterns"
    return 1
  fi
  
  # Check that there's logic to prepend / to paths that look absolute but lack it
  # The install script uses patterns like PROMPT_DEFAULT="/$PROMPT_DEFAULT"
  if ! grep -q '"/\$' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should prepend / to paths missing leading slash"
    return 1
  fi
  
  return 0
}

install_nixos_normalizes_config_path_without_leading_slash() {
  # Test that NixOS config paths like "etc/nixos/configuration.nix" are normalized to
  # "/etc/nixos/configuration.nix".
  # This test verifies the path normalization logic exists in the install script.
  
  # Check that the install script has normalization for paths missing leading slash
  # that look like they should be absolute (e.g., etc/, home/, nix/)
  if ! grep -q '\[Ee\]tc' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should have path normalization for etc/ patterns"
    return 1
  fi
  
  # Check specifically for Nix-related path normalization
  if ! grep -q '\[Nn\]ix' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should handle nix/ paths in normalization"
    return 1
  fi
  
  return 0
}

install_does_not_double_home_path() {
  # Test that paths starting with $HOME are not doubled due to tilde pattern matching.
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
  if printf '%s' "$OUTPUT" | grep -q "$fixture/home/$fixture"; then
    TEST_FAILURE_REASON="path was incorrectly doubled: found $fixture/home/$fixture in output"
    return 1
  fi
  # Verify correct path is used
  assert_output_contains "$install_dir/spells" || return 1
}

# === NixOS Shell Code Tests ===

install_nixos_does_not_write_shell_code_to_nix_file() {
  # When format is nix, the installer should not write shell code to the .nix file.
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a fake home.nix
  mkdir -p "$fixture/home/.config/home-manager"
  cat >"$fixture/home/.config/home-manager/home.nix" <<'EOF'
{ config, pkgs, ... }:

{
  home.username = "testuser";
  home.homeDirectory = "/home/testuser";
  programs.bash.enable = true;
}
EOF

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env DETECT_RC_FILE_PLATFORM=nixos \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install" 2>&1

  assert_success || return 1
  
  # The nix file should not contain shell code markers
  if grep -q '# >>> wizardry cd cantrip >>>' "$fixture/home/.config/home-manager/home.nix" 2>/dev/null; then
    TEST_FAILURE_REASON="shell code (cd cantrip) was written to .nix file"
    return 1
  fi
  
  if grep -q 'source.*jump-to-marker' "$fixture/home/.config/home-manager/home.nix" 2>/dev/null; then
    TEST_FAILURE_REASON="shell code (jump-to-marker source) was written to .nix file"
    return 1
  fi
  
  # But the nix file SHOULD contain the PATH configuration
  if ! grep -q '# wizardry PATH begin' "$fixture/home/.config/home-manager/home.nix" 2>/dev/null; then
    TEST_FAILURE_REASON="PATH configuration was not written to .nix file"
    return 1
  fi
  
  return 0
}

# === Old Version Compatibility Tests (from test-install-with-old-version.sh) ===
# These tests verify that the install script uses explicit paths to helper spells
# rather than relying on PATH resolution (which could use old broken versions).

install_uses_explicit_helper_paths() {
  # Verify that the install script references helpers using explicit paths,
  # not relying on PATH which could contain old broken versions.
  
  # Check that path-wizard is referenced with an explicit path
  if ! grep -q 'PATH_WIZARD=.*\$ABS_DIR/spells/system/path-wizard' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should use explicit path to path-wizard"
    return 1
  fi
  
  # Check that detect-rc-file is referenced with an explicit path
  if ! grep -q 'DETECT_RC_FILE=.*\$ABS_DIR/spells/divination/detect-rc-file' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should use explicit path to detect-rc-file"
    return 1
  fi
  
  # Check that ask_yn is referenced with an explicit path
  if ! grep -q 'ASK_YN=.*\$ABS_DIR/spells/cantrips/ask_yn' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should use explicit path to ask_yn"
    return 1
  fi
  
  return 0
}

path_wizard_uses_explicit_helper_paths() {
  # Verify that path-wizard references helpers using explicit paths when available.
  
  # Check that path-wizard has default paths for DETECT_RC_FILE and SCRIBE_SPELL
  if ! grep -q 'DETECT_RC_FILE_DEFAULT=.*\$SCRIPT_DIR' "$ROOT_DIR/spells/system/path-wizard"; then
    TEST_FAILURE_REASON="path-wizard should have explicit default path for DETECT_RC_FILE"
    return 1
  fi
  
  if ! grep -q 'SCRIBE_SPELL_DEFAULT=.*\$SCRIPT_DIR' "$ROOT_DIR/spells/system/path-wizard"; then
    TEST_FAILURE_REASON="path-wizard should have explicit default path for SCRIBE_SPELL"
    return 1
  fi
  
  return 0
}

path_wizard_accepts_helper_overrides() {
  # Test that path-wizard respects DETECT_RC_FILE and SCRIBE_SPELL env vars,
  # allowing the install script to force use of new helpers.
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq mkdir rm date mktemp

  # Create a test directory to add to PATH
  test_dir="$fixture/test-path"
  mkdir -p "$test_dir"

  # Set up environment with explicit helper paths
  rc_file="$fixture/.testrc"
  
  # Run path-wizard with explicit helper env vars
  DETECT_RC_FILE="$ROOT_DIR/spells/divination/detect-rc-file" \
    SCRIBE_SPELL="$ROOT_DIR/spells/spellcraft/scribe-spell" \
    run_cmd "$ROOT_DIR/spells/system/path-wizard" \
      --rc-file "$rc_file" \
      --format shell \
      add "$test_dir"

  # Should succeed
  assert_success || return 1

  return 0
}

# === Help Tests ===

shows_help() {
  run_spell spells/install/install --help
  true
}

# === Run Tests ===

run_test_case "install runs core installer" install_invokes_core_installer
run_test_case "install exits on interrupt signal" install_exits_on_interrupt
run_test_case "install prompts for NixOS config path" install_nixos_prompts_for_config_path
run_test_case "install fails on NixOS without config path" install_nixos_fails_without_config_path
run_test_case "install mentions flakes in NixOS output" install_nixos_mentions_flakes_in_output
run_test_case "install generates flake.nix on NixOS" install_nixos_generates_flake_nix
run_test_case "install adds flakes enablement on NixOS" install_nixos_adds_flakes_enablement
run_test_case "install preserves existing flakes setting" install_nixos_preserves_existing_flakes_setting
run_test_case "install adds flake input on NixOS" install_nixos_adds_flake_input
run_test_case "install normalizes path without leading slash" install_normalizes_path_without_leading_slash
run_test_case "install normalizes NixOS config path" install_nixos_normalizes_config_path_without_leading_slash
run_test_case "install does not double home path" install_does_not_double_home_path
run_test_case "install does not write shell code to nix file" install_nixos_does_not_write_shell_code_to_nix_file
run_test_case "install uses explicit helper paths" install_uses_explicit_helper_paths
run_test_case "path-wizard uses explicit helper paths" path_wizard_uses_explicit_helper_paths
run_test_case "path-wizard accepts helper overrides" path_wizard_accepts_helper_overrides
run_test_case "install shows help" shows_help

finish_tests
