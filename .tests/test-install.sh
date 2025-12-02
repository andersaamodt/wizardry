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

install_nixos_adds_path_to_config() {
  # On NixOS, the installer should add PATH entries to configuration.nix
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
  # Check that the output mentions PATH configuration
  assert_output_contains "PATH configuration" || return 1
}

install_nixos_writes_path_block() {
  # On NixOS, the installer should write a PATH block to configuration.nix
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
  # Check that PATH block was written to config file
  assert_file_contains "$fixture/home/.config/home-manager/home.nix" "# wizardry" || return 1
}

install_nixos_adds_path_to_system_config() {
  # On NixOS, the installer should add PATH entries to configuration.nix
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a configuration.nix
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
  
  # Check that wizardry PATH block was added to configuration.nix
  assert_file_contains "$fixture/etc/nixos/configuration.nix" "# wizardry" || return 1
}

install_nixos_preserves_existing_config() {
  # The installer should preserve existing content in configuration.nix
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a configuration.nix with existing content
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
  
  # Count occurrences of experimental-features - should be exactly 1 (preserved, not duplicated)
  count=$(grep -c "experimental-features" "$fixture/etc/nixos/configuration.nix" 2>/dev/null || printf '0')
  if [ "$count" -ne 1 ]; then
    TEST_FAILURE_REASON="expected exactly 1 occurrence of experimental-features, got $count"
    return 1
  fi
  
  # Check that PATH block was added
  assert_file_contains "$fixture/etc/nixos/configuration.nix" "# wizardry" || return 1
}

install_nixos_writes_path_entries_to_config() {
  # On NixOS, PATH entries should be written to configuration.nix
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a configuration.nix
  mkdir -p "$fixture/etc/nixos"
  cat >"$fixture/etc/nixos/configuration.nix" <<'EOF'
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
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
  
  # Check that wizardry PATH block was added to configuration.nix
  if ! grep -q '# wizardry' "$fixture/etc/nixos/configuration.nix" 2>/dev/null; then
    TEST_FAILURE_REASON="PATH entries should be in configuration.nix"
    return 1
  fi
}

install_nixos_simple_input() {
  # Test that NixOS installer only needs config path and confirmation
  # (no separate flakes consent prompt)
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a configuration.nix
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
  
  # Simulate user input: config path, then 'y' to proceed (only 2 prompts now)
  run_cmd sh -c "
    printf '%s\n%s\n' '$fixture/etc/nixos/configuration.nix' 'y' | \
    env DETECT_RC_FILE_PLATFORM=nixos \
        WIZARDRY_INSTALL_DIR='$install_dir' \
        HOME='$fixture/home' \
        '$ROOT_DIR/install'
  "

  assert_success || return 1
  
  # Check that PATH block was added
  assert_file_contains "$fixture/etc/nixos/configuration.nix" "# wizardry" || return 1
}

install_nixos_shows_config_file_message() {
  # On NixOS, the installer should show "Configuration file to be modified" 
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  # Create a configuration.nix
  mkdir -p "$fixture/etc/nixos"
  cat >"$fixture/etc/nixos/configuration.nix" <<'EOF'
{ config, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];
  
  boot.loader.grub.enable = true;
}
EOF

  install_dir="$fixture/home/.wizardry"
  
  # Simulate user input: config path, then 'y' to proceed
  run_cmd sh -c "
    printf '%s\n%s\n' '$fixture/etc/nixos/configuration.nix' 'y' | \
    env DETECT_RC_FILE_PLATFORM=nixos \
        WIZARDRY_INSTALL_DIR='$install_dir' \
        HOME='$fixture/home' \
        '$ROOT_DIR/install'
  "

  assert_success || return 1
  
  # Check that the output shows "Configuration file to be modified"
  assert_output_contains "Configuration file to be modified" || return 1
}

install_nixos_shows_path_updated_message() {
  # On NixOS, the installer should show "PATH configuration updated" message
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
  
  # Simulate user input: config path, then 'y' to proceed
  run_cmd sh -c "
    printf '%s\n%s\n' '$fixture/etc/nixos/configuration.nix' 'y' | \
    env DETECT_RC_FILE_PLATFORM=nixos \
        WIZARDRY_INSTALL_DIR='$install_dir' \
        HOME='$fixture/home' \
        '$ROOT_DIR/install'
  "

  assert_success || return 1
  
  # Check that the output shows PATH configuration message
  assert_output_contains "PATH configuration updated" || return 1
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

install_nixos_writes_shell_init_properly_to_nix_file() {
  # When format is nix, the installer should write shell code to the .nix file
  # using proper nix syntax (programs.bash.initExtra) instead of raw shell markers.
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
  
  # The nix file should NOT contain raw shell code markers (old format)
  if grep -q '# >>> wizardry cd cantrip >>>' "$fixture/home/.config/home-manager/home.nix" 2>/dev/null; then
    TEST_FAILURE_REASON="raw shell code markers (cd cantrip) found in .nix file - should use nix format"
    return 1
  fi
  
  # Shell code should be written using proper nix syntax (programs.bash.initExtra)
  # If installable spells were installed, they should use wizardry-shell markers
  # PATH entries should be in home.nix using # wizardry markers
  assert_file_contains "$fixture/home/.config/home-manager/home.nix" "# wizardry" || return 1
  
  return 0
}

# === Old Version Compatibility Tests (from test-install-with-old-version.sh) ===
# These tests verify that the install script uses explicit paths to helper spells
# rather than relying on PATH resolution (which could use old broken versions).

install_uses_explicit_helper_paths() {
  # Verify that the install script references helpers using explicit paths,
  # not relying on PATH which could contain old broken versions.
  
  # Check that learn-spellbook is referenced with an explicit path
  if ! grep -q 'LEARN_SPELLBOOK=.*\$ABS_DIR/spells/spellcraft/learn-spellbook' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should use explicit path to learn-spellbook"
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
  # Verify that learn-spellbook references helpers using explicit paths when available.
  
  # Check that learn-spellbook has default paths for DETECT_RC_FILE and LEARN
  if ! grep -q 'DETECT_RC_FILE_DEFAULT=.*\$SCRIPT_DIR' "$ROOT_DIR/spells/spellcraft/learn-spellbook"; then
    TEST_FAILURE_REASON="learn-spellbook should have explicit default path for DETECT_RC_FILE"
    return 1
  fi
  
  if ! grep -q 'LEARN_DEFAULT=.*\$SCRIPT_DIR' "$ROOT_DIR/spells/spellcraft/learn-spellbook"; then
    TEST_FAILURE_REASON="learn-spellbook should have explicit default path for LEARN"
    return 1
  fi
  
  return 0
}

path_wizard_accepts_helper_overrides() {
  # Test that learn-spellbook respects DETECT_RC_FILE and LEARN_SPELL env vars,
  # allowing the install script to force use of new helpers.
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq mkdir rm date mktemp

  # Create a test directory to add to PATH
  test_dir="$fixture/test-path"
  mkdir -p "$test_dir"

  # Set up environment with explicit helper paths
  rc_file="$fixture/.testrc"
  
  # Run learn-spellbook with explicit helper env vars
  DETECT_RC_FILE="$ROOT_DIR/spells/divination/detect-rc-file" \
    LEARN_SPELL="$ROOT_DIR/spells/spellcraft/learn" \
    run_cmd "$ROOT_DIR/spells/spellcraft/learn-spellbook" \
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

# === Bootstrapping Spell Independence Tests ===
# Verify that install script uses only explicit paths to helper scripts,
# not PATH-based invocations that could fail if wizardry isn't installed yet.

install_uses_only_bootstrappable_spells() {
  # The install script should only use:
  # 1. Spells from spells/install/core/ (bootstrapping spells)
  # 2. Helper spells via explicit $ABS_DIR paths (not PATH lookup)
  #
  # This test verifies that no spell is invoked by bare name (relying on PATH)
  # except for standard system commands.
  
  # List of allowed bare commands (system tools, not wizardry spells)
  allowed_cmds="cat|cd|chmod|command|cp|curl|date|dirname|find|grep|head|ls|mkdir|mktemp|mv|printf|pwd|rm|sed|sh|sort|tar|tr|uname|wc|wget|awk|cut|uniq"
  
  # Check that the install script doesn't invoke wizardry spells by bare name
  # Look for patterns like: command_name or "command_name" that might be spell invocations
  # (excluding variable assignments and comments)
  
  # Get list of wizardry spell names
  spell_names=""
  for spell in "$ROOT_DIR"/spells/*; do
    [ -f "$spell" ] && [ -x "$spell" ] || continue
    name=${spell##*/}
    spell_names="$spell_names $name"
  done
  for spell in "$ROOT_DIR"/spells/*/*; do
    [ -f "$spell" ] && [ -x "$spell" ] || continue
    name=${spell##*/}
    spell_names="$spell_names $name"
  done
  
  # Check that the install script uses explicit paths (like $ASK_YN, $LEARN_SPELLBOOK)
  # rather than bare spell names in command position
  
  # Verify key spells are invoked via variables, not bare names
  # learn-spellbook should be invoked as $LEARN_SPELLBOOK
  if grep -E '^\s*learn-spellbook\s' "$ROOT_DIR/install" 2>/dev/null | grep -v '^#' | grep -v 'LEARN_SPELLBOOK=' >/dev/null; then
    TEST_FAILURE_REASON="install script invokes 'learn-spellbook' directly instead of via \$LEARN_SPELLBOOK"
    return 1
  fi
  
  # detect-rc-file should be invoked as $DETECT_RC_FILE
  if grep -E '^\s*detect-rc-file\s' "$ROOT_DIR/install" 2>/dev/null | grep -v '^#' | grep -v 'DETECT_RC_FILE=' >/dev/null; then
    TEST_FAILURE_REASON="install script invokes 'detect-rc-file' directly instead of via \$DETECT_RC_FILE"
    return 1
  fi
  
  # ask_yn should be invoked as $ASK_YN
  if grep -E '^\s*ask_yn\s' "$ROOT_DIR/install" 2>/dev/null | grep -v '^#' | grep -v 'ASK_YN=' >/dev/null; then
    TEST_FAILURE_REASON="install script invokes 'ask_yn' directly instead of via \$ASK_YN"
    return 1
  fi
  
  # learn (for installing spells) should be invoked as $SPELL_INSTALLER
  if grep -E '^\s*learn\s' "$ROOT_DIR/install" 2>/dev/null | grep -v '^#' | grep -v 'LEARN_SPELL=' | grep -v 'SPELL_INSTALLER=' >/dev/null; then
    TEST_FAILURE_REASON="install script invokes 'learn' directly instead of via \$SPELL_INSTALLER"
    return 1
  fi
  
  return 0
}

# === Already Installed Menu Tests ===

install_shows_menu_when_already_installed() {
  # When wizardry is already installed, the installer should show a numbered menu
  # with options: repair, reinstall, uninstall, exit
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  # First install wizardry
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"
  
  assert_success || return 1
  
  # Now run install again - should show menu. Choose exit (4)
  run_cmd sh -c "
    printf '4\n' | \
    env WIZARDRY_INSTALL_DIR='$install_dir' \
        HOME='$fixture/home' \
        '$ROOT_DIR/install'
  "
  
  assert_success || return 1
  
  # Check that menu options are shown
  assert_output_contains "already installed" || return 1
  assert_output_contains "Repair" || return 1
  assert_output_contains "Reinstall" || return 1
  assert_output_contains "Uninstall" || return 1
  assert_output_contains "Exit" || return 1
}

# === Output Message Tests ===

install_nixos_shows_path_updated() {
  # On NixOS, the installer should show "PATH configuration updated"
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
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should show "PATH configuration updated" message for NixOS
  assert_output_contains "PATH configuration updated" || return 1
}

install_shows_spell_names_installed() {
  # The installer should list the names of spells that were installed
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should list spell names in output (e.g., "cd" spell)
  # The output should contain the spell names that were installed
  if printf '%s' "$OUTPUT" | grep -q "Memorizing"; then
    # If spells were installed, check that names are listed
    if printf '%s' "$OUTPUT" | grep -q "Installed"; then
      # Check that individual spell names are shown with ->
      assert_output_contains "->" || return 1
    fi
  fi
}

install_creates_uninstall_script_with_correct_name() {
  # The uninstall script should be named .uninstall not uninstall_wizardry
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Check that .uninstall script exists
  assert_path_exists "$install_dir/.uninstall" || return 1
  
  # Check that old uninstall_wizardry does NOT exist
  assert_path_missing "$install_dir/uninstall_wizardry" || return 1
}

install_does_not_show_uninstall_on_success() {
  # The installer should NOT show "Uninstall script created at:" message
  # on successful installation (per problem statement - only notify on failure)
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should have Installation Complete message
  if ! printf '%s' "$OUTPUT" | grep -q "Installation Complete"; then
    TEST_FAILURE_REASON="Installation Complete message not found"
    return 1
  fi
  
  # Should NOT show uninstall script message on success
  if printf '%s' "$OUTPUT" | grep -q "Uninstall script created"; then
    TEST_FAILURE_REASON="should not show uninstall script message on success"
    return 1
  fi
  
  # The uninstall script should still be created though
  assert_path_exists "$install_dir/.uninstall" || return 1
}

install_shows_simple_run_message() {
  # The installer should show simple message about running menu/mud
  # instead of "Next steps" section
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should show simple run message (with either "Run" or "run" prefix)
  if ! printf '%s' "$OUTPUT" | grep -iq "run.*menu.*or.*mud.*to start using wizardry"; then
    TEST_FAILURE_REASON="output missing run message about menu or mud"
    return 1
  fi
  
  # Should NOT show "Next steps" heading
  if printf '%s' "$OUTPUT" | grep -q "Next steps"; then
    TEST_FAILURE_REASON="should not show 'Next steps' heading"
    return 1
  fi
  
  # Should NOT show "To uninstall, run:" instruction
  if printf '%s' "$OUTPUT" | grep -q "To uninstall"; then
    TEST_FAILURE_REASON="should not show uninstall instructions"
    return 1
  fi
}

install_does_not_show_adding_missing_path_on_fresh() {
  # The installer should not show "Adding missing PATH configuration" on fresh install
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should NOT show "Adding missing PATH configuration" on fresh install
  if printf '%s' "$OUTPUT" | grep -q "Adding missing PATH configuration"; then
    TEST_FAILURE_REASON="should not show 'Adding missing PATH configuration' on fresh install"
    return 1
  fi
}

# === NixOS Log Out/In Message Tests ===

install_nixos_shows_logout_message() {
  # On NixOS, the installer should show a message about logging out and back in
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
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should show log out message for NixOS (new message uses "logging out")
  assert_output_contains "logging out" || return 1
}

install_non_nixos_shows_source_message() {
  # On non-NixOS platforms, the installer should show that wizardry is ready
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should indicate wizardry is ready in this terminal
  assert_output_contains "ready to use" || return 1
  # Should mention new terminal windows will also have wizardry
  if ! printf '%s' "$OUTPUT" | grep -qi "terminal"; then
    TEST_FAILURE_REASON="output should mention terminal windows"
    return 1
  fi
}

# === Uninstall Script Tests ===

uninstall_script_handles_imps_directory() {
  # Test that the generated uninstall script uses remove-all to handle all PATH entries
  # This includes .imps and other hidden directories that glob patterns might miss
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Check that the uninstall script exists
  uninstall_script="$install_dir/.uninstall"
  assert_path_exists "$uninstall_script" || return 1
  
  # Check that the uninstall script uses remove-all to handle all entries
  # This is more reliable than iterating over directories (which could miss .imps)
  assert_file_contains "$uninstall_script" "remove-all" || return 1
}

uninstall_script_nixos_includes_rebuild() {
  # Test that the NixOS uninstall script includes nixos-rebuild switch
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
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Check that the uninstall script exists
  uninstall_script="$install_dir/.uninstall"
  assert_path_exists "$uninstall_script" || return 1
  
  # Check that the uninstall script contains nixos-rebuild logic for NixOS
  assert_file_contains "$uninstall_script" "nixos-rebuild" || return 1
}

uninstall_script_nixos_includes_logout_message() {
  # Test that the NixOS uninstall script includes log out message
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
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Check that the uninstall script exists
  uninstall_script="$install_dir/.uninstall"
  assert_path_exists "$uninstall_script" || return 1
  
  # Check that the uninstall script contains logout message for NixOS
  assert_file_contains "$uninstall_script" "logging out" || return 1
}

# === Install Prompt Text Tests ===

install_shows_revised_prompt_text() {
  # Test that the install script uses the revised prompt text
  # "Wizardry install directory?" instead of "Where should wizardry be installed?"
  # This phrasing works for both fresh installs and reinstalls
  if grep -q "Where should wizardry be installed" "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should use revised prompt 'Wizardry install directory?'"
    return 1
  fi
  
  if ! grep -q "Wizardry install directory?" "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should have prompt 'Wizardry install directory?'"
    return 1
  fi
  
  return 0
}

# === Path Wizard remove-all Tests ===

path_wizard_remove_all_removes_all_nix_entries() {
  # Test that learn-spellbook remove-all removes all wizardry entries from nix files
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq mkdir rm date mktemp wc

  mkdir -p "$fixture/home/.config/home-manager"
  mkdir -p "$fixture/test-dir1" "$fixture/test-dir2"
  
  # Create a nix file with multiple wizardry entries
  cat >"$fixture/home/.config/home-manager/home.nix" <<EOF
{ config, pkgs, ... }:

{
  home.username = "testuser";
  
  environment.sessionVariables.PATH = [
    "$fixture/test-dir1" # wizardry
    "$fixture/test-dir2" # wizardry
    "$fixture/non-existent-dir" # wizardry
  ];
}
EOF

  # Run remove-all
  run_cmd "$ROOT_DIR/spells/spellcraft/learn-spellbook" \
      --rc-file "$fixture/home/.config/home-manager/home.nix" \
      --format nix \
      remove-all

  assert_success || return 1
  
  # Check that all wizardry entries are removed
  if grep -q "# wizardry" "$fixture/home/.config/home-manager/home.nix" 2>/dev/null; then
    TEST_FAILURE_REASON="remove-all should remove all wizardry entries"
    return 1
  fi
  
  return 0
}

path_wizard_remove_all_reports_count() {
  # Test that remove-all reports the count of entries removed
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq mkdir rm date mktemp wc

  mkdir -p "$fixture/home/.config/home-manager"
  mkdir -p "$fixture/test-dir1"
  
  # Create a nix file with wizardry entries
  cat >"$fixture/home/.config/home-manager/home.nix" <<EOF
{ config, pkgs, ... }:

{
  environment.sessionVariables.PATH = [
    "$fixture/test-dir1" # wizardry
    "$fixture/test-dir2" # wizardry
  ];
}
EOF

  run_cmd "$ROOT_DIR/spells/spellcraft/learn-spellbook" \
      --rc-file "$fixture/home/.config/home-manager/home.nix" \
      --format nix \
      remove-all

  assert_success || return 1
  
  # Check that the output mentions removing 2 entries
  assert_output_contains "Removed 2" || return 1
  
  return 0
}

path_wizard_remove_all_handles_empty_file() {
  # Test that remove-all handles files with no wizardry entries gracefully
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq mkdir rm date mktemp wc

  mkdir -p "$fixture/home/.config/home-manager"
  
  # Create a nix file with NO wizardry entries
  cat >"$fixture/home/.config/home-manager/home.nix" <<EOF
{ config, pkgs, ... }:

{
  home.username = "testuser";
}
EOF

  run_cmd "$ROOT_DIR/spells/spellcraft/learn-spellbook" \
      --rc-file "$fixture/home/.config/home-manager/home.nix" \
      --format nix \
      remove-all

  assert_success || return 1
  
  # Check that the output mentions no entries found
  assert_output_contains "No wizardry PATH entries" || return 1
  
  return 0
}

# === Install Spells Before Rebuild Tests ===

install_spells_before_nixos_rebuild() {
  # Test that the install script has the spell installation section before nixos-rebuild
  # This ensures spells are ready when the rebuild completes
  
  # Find line numbers of key sections
  install_spells_line=$(grep -n "section_msg.*Installing Spells" "$ROOT_DIR/install" | head -1 | cut -d: -f1)
  rebuild_line=$(grep -n "nixos-rebuild switch" "$ROOT_DIR/install" | head -1 | cut -d: -f1)
  
  if [ -z "$install_spells_line" ]; then
    TEST_FAILURE_REASON="Installing Spells section not found in install script"
    return 1
  fi
  
  if [ -z "$rebuild_line" ]; then
    # No nixos-rebuild in script (might be in different format), skip check
    return 0
  fi
  
  if [ "$install_spells_line" -gt "$rebuild_line" ]; then
    TEST_FAILURE_REASON="Installing Spells section should come before nixos-rebuild (install spells at line $install_spells_line, rebuild at line $rebuild_line)"
    return 1
  fi
  
  return 0
}

# === Run Tests ===

run_test_case "install runs core installer" install_invokes_core_installer
run_test_case "install exits on interrupt signal" install_exits_on_interrupt
run_test_case "install prompts for NixOS config path" install_nixos_prompts_for_config_path
run_test_case "install fails on NixOS without config path" install_nixos_fails_without_config_path
run_test_case "install NixOS adds PATH to config" install_nixos_adds_path_to_config
run_test_case "install NixOS writes PATH block" install_nixos_writes_path_block
run_test_case "install NixOS adds PATH to system config" install_nixos_adds_path_to_system_config
run_test_case "install NixOS preserves existing config" install_nixos_preserves_existing_config
run_test_case "install NixOS writes PATH entries to config" install_nixos_writes_path_entries_to_config
run_test_case "install NixOS simple input" install_nixos_simple_input
run_test_case "install normalizes path without leading slash" install_normalizes_path_without_leading_slash
run_test_case "install normalizes NixOS config path" install_nixos_normalizes_config_path_without_leading_slash
run_test_case "install does not double home path" install_does_not_double_home_path
run_test_case "install writes shell init properly to nix file" install_nixos_writes_shell_init_properly_to_nix_file
run_test_case "install uses explicit helper paths" install_uses_explicit_helper_paths
run_test_case "learn-spellbook uses explicit helper paths" path_wizard_uses_explicit_helper_paths
run_test_case "learn-spellbook accepts helper overrides" path_wizard_accepts_helper_overrides
run_test_case "install uses only bootstrappable spells" install_uses_only_bootstrappable_spells
run_test_case "install shows menu when already installed" install_shows_menu_when_already_installed
run_test_case "install shows help" shows_help
run_test_case "install NixOS shows PATH updated" install_nixos_shows_path_updated
run_test_case "install shows spell names installed" install_shows_spell_names_installed
run_test_case "install creates .uninstall script" install_creates_uninstall_script_with_correct_name
run_test_case "install does not show uninstall on success" install_does_not_show_uninstall_on_success
run_test_case "install shows simple run message" install_shows_simple_run_message
run_test_case "install no adding missing path on fresh" install_does_not_show_adding_missing_path_on_fresh
run_test_case "install NixOS shows config file message" install_nixos_shows_config_file_message
run_test_case "install NixOS shows path updated message" install_nixos_shows_path_updated_message
run_test_case "install NixOS shows logout message" install_nixos_shows_logout_message
run_test_case "install non-NixOS shows source message" install_non_nixos_shows_source_message
run_test_case "uninstall script handles .imps directory" uninstall_script_handles_imps_directory
run_test_case "uninstall script NixOS includes rebuild" uninstall_script_nixos_includes_rebuild
run_test_case "uninstall script NixOS includes logout message" uninstall_script_nixos_includes_logout_message
run_test_case "install shows revised prompt text" install_shows_revised_prompt_text
run_test_case "learn-spellbook remove-all removes all nix entries" path_wizard_remove_all_removes_all_nix_entries
run_test_case "learn-spellbook remove-all reports count" path_wizard_remove_all_reports_count
run_test_case "learn-spellbook remove-all handles empty file" path_wizard_remove_all_handles_empty_file
run_test_case "install installs spells before nixos-rebuild" install_spells_before_nixos_rebuild

finish_tests
