#!/bin/sh
set -eu

# Test suite for the root install script.
# This file is in .tests/ (not .tests/install/) because install is in the repo root,
# not in spells/.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# === Basic Installation Tests ===

install_invokes_core_installer() {
  skip-if-compiled || return $?
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
  skip-if-compiled || return $?
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
  skip-if-compiled || return $?
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
    env PATH='$fixture/bin:$initial_path' \
        DETECT_RC_FILE_PLATFORM=nixos \
        WIZARDRY_INSTALL_DIR='$install_dir' \
        HOME='$fixture/home' \
        WIZARDRY_INSTALL_ASSUME_YES=1 \
        '$ROOT_DIR/install'
  "

  # Check that the output mentions using the custom configuration
  assert_output_contains "Using configuration file:" || return 1
  assert_output_contains "$custom_config_dir/configuration.nix" || return 1
}

install_nixos_fails_without_config_path() {
  skip-if-compiled || return $?
  # On NixOS without a config file and non-interactive input,
  # the installer should fail with an error message
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  # Run without providing any config path input (non-interactive)
  run_cmd env PATH="$fixture/bin:$initial_path" DETECT_RC_FILE_PLATFORM=nixos \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      ASK_CANTRIP_INPUT=none \
      "$ROOT_DIR/install" </dev/null

  assert_failure || return 1
  assert_error_contains "No NixOS configuration file found" || return 1
}

install_nixos_adds_path_to_config() {
  skip-if-compiled || return $?
  # On NixOS, the installer should add shell configuration (invoke-wizardry) to configuration.nix
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
  
  run_cmd env PATH="$fixture/bin:$initial_path" DETECT_RC_FILE_PLATFORM=nixos \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  # Check that the output mentions shell configuration
  assert_output_contains "Shell configuration" || return 1
}

install_nixos_writes_path_block() {
  skip-if-compiled || return $?
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
  
  run_cmd env PATH="$fixture/bin:$initial_path" DETECT_RC_FILE_PLATFORM=nixos \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  # Check that PATH block was written to config file
  assert_file_contains "$fixture/home/.config/home-manager/home.nix" "# wizardry" || return 1
}

install_nixos_adds_path_to_system_config() {
  skip-if-compiled || return $?
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

  # Stub nixos-rebuild and home-manager commands to prevent actual system modifications
  cat >"$fixture/bin/nixos-rebuild" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/nixos-rebuild"
  
  cat >"$fixture/bin/home-manager" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/home-manager"

  install_dir="$fixture/home/.wizardry"
  
  # Set NIXOS_CONFIG to tell the installer where the config file is
  run_cmd env PATH="$fixture/bin:$initial_path" \
      DETECT_RC_FILE_PLATFORM=nixos \
      NIXOS_CONFIG="$fixture/etc/nixos/configuration.nix" \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      HOME="$fixture/home" \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Check that wizardry PATH block was added to configuration.nix
  assert_file_contains "$fixture/etc/nixos/configuration.nix" "# wizardry" || return 1
}

install_nixos_preserves_existing_config() {
  skip-if-compiled || return $?
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

  # Stub nixos-rebuild and home-manager commands to prevent actual system modifications
  cat >"$fixture/bin/nixos-rebuild" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/nixos-rebuild"
  
  cat >"$fixture/bin/home-manager" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/home-manager"

  install_dir="$fixture/home/.wizardry"
  
  # Set NIXOS_CONFIG to tell the installer where the config file is
  run_cmd env PATH="$fixture/bin:$initial_path" \
      DETECT_RC_FILE_PLATFORM=nixos \
      NIXOS_CONFIG="$fixture/etc/nixos/configuration.nix" \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      HOME="$fixture/home" \
      "$ROOT_DIR/install"

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
  skip-if-compiled || return $?
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

  # Stub nixos-rebuild and home-manager commands to prevent actual system modifications
  cat >"$fixture/bin/nixos-rebuild" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/nixos-rebuild"
  
  cat >"$fixture/bin/home-manager" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/home-manager"

  install_dir="$fixture/home/.wizardry"
  
  # Set NIXOS_CONFIG to tell the installer where the config file is
  run_cmd env PATH="$fixture/bin:$initial_path" \
      DETECT_RC_FILE_PLATFORM=nixos \
      NIXOS_CONFIG="$fixture/etc/nixos/configuration.nix" \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      HOME="$fixture/home" \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Check that wizardry PATH block was added to configuration.nix
  if ! grep -q '# wizardry' "$fixture/etc/nixos/configuration.nix" 2>/dev/null; then
    TEST_FAILURE_REASON="PATH entries should be in configuration.nix"
    return 1
  fi
}

install_nixos_simple_input() {
  skip-if-compiled || return $?
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

  # Stub nixos-rebuild and home-manager commands to prevent actual system modifications
  cat >"$fixture/bin/nixos-rebuild" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/nixos-rebuild"
  
  cat >"$fixture/bin/home-manager" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/home-manager"

  install_dir="$fixture/home/.wizardry"
  
  # Set NIXOS_CONFIG to tell the installer where the config file is
  run_cmd env PATH="$fixture/bin:$initial_path" \
      DETECT_RC_FILE_PLATFORM=nixos \
      NIXOS_CONFIG="$fixture/etc/nixos/configuration.nix" \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      HOME="$fixture/home" \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Check that PATH block was added
  assert_file_contains "$fixture/etc/nixos/configuration.nix" "# wizardry" || return 1
}

install_nixos_shows_config_file_message() {
  skip-if-compiled || return $?
  # On NixOS, the installer should show the configuration file
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

  # Stub nixos-rebuild and home-manager commands to prevent actual system modifications
  cat >"$fixture/bin/nixos-rebuild" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/nixos-rebuild"
  
  cat >"$fixture/bin/home-manager" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/home-manager"

  install_dir="$fixture/home/.wizardry"
  
  # Set NIXOS_CONFIG to tell the installer where the config file is
  run_cmd env PATH="$fixture/bin:$initial_path" \
      DETECT_RC_FILE_PLATFORM=nixos \
      NIXOS_CONFIG="$fixture/etc/nixos/configuration.nix" \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      HOME="$fixture/home" \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Check that the output shows the configuration file
  assert_output_contains "Configuration file:" || return 1
}

install_nixos_shows_shell_config_updated_message() {
  skip-if-compiled || return $?
  # On NixOS, the installer should show "Shell configuration updated" message
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

  # Stub nixos-rebuild and home-manager commands to prevent actual system modifications
  cat >"$fixture/bin/nixos-rebuild" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/nixos-rebuild"
  
  cat >"$fixture/bin/home-manager" <<'STUB'
#!/bin/sh
exit 0
STUB
  chmod +x "$fixture/bin/home-manager"

  install_dir="$fixture/home/.wizardry"
  
  # Set NIXOS_CONFIG to tell the installer where the config file is
  run_cmd env PATH="$fixture/bin:$initial_path" \
      DETECT_RC_FILE_PLATFORM=nixos \
      NIXOS_CONFIG="$fixture/etc/nixos/configuration.nix" \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      HOME="$fixture/home" \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Check that the output shows shell configuration message
  assert_output_contains "Shell configuration updated" || return 1
}

# === Path Normalization Tests ===

install_normalizes_path_without_leading_slash() {
  skip-if-compiled || return $?
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
  skip-if-compiled || return $?
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
  skip-if-compiled || return $?
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
  # Test passes if installation succeeded without path doubling
  return 0
}

# === NixOS Shell Code Tests ===

install_nixos_writes_shell_init_properly_to_nix_file() {
  skip-if-compiled || return $?
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
  
  run_cmd env PATH="$fixture/bin:$initial_path" DETECT_RC_FILE_PLATFORM=nixos \
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
  skip-if-compiled || return $?
  # Verify that the install script references helpers using explicit paths,
  # not relying on PATH which could contain old broken versions.
  
  # Check that invoke-wizardry is referenced with an explicit path
  if ! grep -q 'INVOKE_WIZARDRY=.*\$ABS_DIR/spells/.imps/sys/invoke-wizardry' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should use explicit path to invoke-wizardry"
    return 1
  fi
  
  # Check that detect-rc-file is referenced with an explicit path
  if ! grep -q 'DETECT_RC_FILE=.*\$ABS_DIR/spells/divination/detect-rc-file' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should use explicit path to detect-rc-file"
    return 1
  fi
  
  # Check that ask_yn is referenced with an explicit path
  if ! grep -q 'ASK_YN=.*\$ABS_DIR/spells/cantrips/ask-yn' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should use explicit path to ask_yn"
    return 1
  fi
  
  return 0
}

path_wizard_uses_explicit_helper_paths() {
  # OBSOLETE: learn-spellbook was removed - tests disabled
  return 0
}

path_wizard_accepts_helper_overrides() {
  # OBSOLETE: learn-spellbook was removed - tests disabled
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
  skip-if-compiled || return $?
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

install_fresh_does_not_show_menu() {
  skip-if-compiled || return $?
  # When installing fresh (simulating curl | sh), the installer should NOT show
  # the "already installed" menu, even though it just downloaded the files.
  # This is the bug we're fixing.
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  # Run fresh install (simulating curl | sh with downloaded files)
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"
  
  assert_success || return 1
  
  # Should NOT show "already installed" menu
  if printf '%s' "$OUTPUT" | grep -q "already installed"; then
    TEST_FAILURE_REASON="Fresh install should not show 'already installed' menu"
    return 1
  fi
  
  # Should show completion message
  assert_output_contains "Installation Complete" || return 1
}

# === Output Message Tests ===

install_nixos_shows_shell_config_updated() {
  skip-if-compiled || return $?
  # On NixOS, the installer should show "Shell configuration updated"
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
  
  run_cmd env PATH="$fixture/bin:$initial_path" DETECT_RC_FILE_PLATFORM=nixos \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should show "Shell configuration updated" message for NixOS
  assert_output_contains "Shell configuration updated" || return 1
}

install_does_not_show_spell_installation() {
  skip-if-compiled || return $?
  # With word-of-binding paradigm, the installer should NOT pre-install spells
  # Spells are auto-sourced on first use via command_not_found_handle
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should NOT show "Installing Spells" section anymore
  if printf '%s' "$OUTPUT" | grep -q "Installing Spells"; then
    TEST_FAILURE_REASON="installer should not have Installing Spells section"
    return 1
  fi
}

install_creates_uninstall_script_with_correct_name() {
  skip-if-compiled || return $?
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
  skip-if-compiled || return $?
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
  skip-if-compiled || return $?
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
  skip-if-compiled || return $?
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

install_nixos_shows_appropriate_message() {
  skip-if-compiled || return $?
  # On NixOS, the installer should show a message about when wizardry is available
  # This could be "ready to use" (if sourcing succeeded) or "new terminal" (if not)
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
  
  run_cmd env PATH="$fixture/bin:$initial_path" DETECT_RC_FILE_PLATFORM=nixos \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should show availability message for NixOS (either "ready to use" or "new terminal")
  if ! printf '%s' "$OUTPUT" | grep -qE "(ready to use|new terminal|After rebuilding)"; then
    TEST_FAILURE_REASON="output should indicate when wizardry will be available"
    return 1
  fi
}

install_non_nixos_shows_source_message() {
  skip-if-compiled || return $?
  # On non-NixOS platforms, the installer should show appropriate message
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should indicate installation was successful
  if ! printf '%s' "$OUTPUT" | grep -qE "(has been installed successfully|Wizardry is ready)"; then
    TEST_FAILURE_REASON="output should indicate successful installation"
    return 1
  fi
  # Should mention opening a new terminal window
  if ! printf '%s' "$OUTPUT" | grep -qE "(Open a new terminal|open a new terminal)"; then
    TEST_FAILURE_REASON="output should mention opening a new terminal"
    return 1
  fi
}

# === Uninstall Script Tests ===

uninstall_script_removes_invoke_wizardry() {
  skip-if-compiled || return $?
  # Test that the generated uninstall script removes the invoke-wizardry source line
  # This is the new paradigm - we no longer add individual PATH entries
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
  
  # Check that the uninstall script removes the wizardry-init marker
  # This is the new approach for removing invoke-wizardry source line
  assert_file_contains "$uninstall_script" "wizardry-init" || return 1
}

uninstall_script_nixos_includes_rebuild() {
  skip-if-compiled || return $?
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
  
  run_cmd env PATH="$fixture/bin:$initial_path" DETECT_RC_FILE_PLATFORM=nixos \
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

uninstall_script_nixos_includes_terminal_message() {
  skip-if-compiled || return $?
  # Test that the NixOS uninstall script tells users to open a new terminal
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
  
  run_cmd env PATH="$fixture/bin:$initial_path" DETECT_RC_FILE_PLATFORM=nixos \
      WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Check that the uninstall script exists
  uninstall_script="$install_dir/.uninstall"
  assert_path_exists "$uninstall_script" || return 1
  
  # Check that the uninstall script mentions opening a new terminal for NixOS
  assert_file_contains "$uninstall_script" "new terminal" || return 1
}

# === Install Prompt Text Tests ===

install_shows_revised_prompt_text() {
  skip-if-compiled || return $?
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
  # OBSOLETE: learn-spellbook was removed - tests disabled
  return 0
}

path_wizard_remove_all_reports_count() {
  # OBSOLETE: learn-spellbook was removed - tests disabled
  return 0
}

path_wizard_remove_all_handles_empty_file() {
  # OBSOLETE: learn-spellbook was removed - tests disabled
  return 0
}

# === Install Spells Before Rebuild Tests ===

install_no_spell_preinstallation() {
  # With word-of-binding paradigm, spells are NOT pre-installed
  # This test verifies the install script doesn't have the old spell installation logic
  
  # Check that the install script does NOT have LEARNABLE_SPELLS variable
  if grep -q 'LEARNABLE_SPELLS=' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should not have LEARNABLE_SPELLS (word-of-binding handles this)"
    return 1
  fi
  
  # Check that there's no "Installing Spells" section
  if grep -q 'section_msg.*Installing Spells' "$ROOT_DIR/install"; then
    TEST_FAILURE_REASON="install script should not have Installing Spells section"
    return 1
  fi
  
  return 0
}

# === MUD Installation Tests ===

install_mud_setup() {
  skip-if-compiled || return $?
  # Test that MUD installation works properly
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # With word-of-binding paradigm, should NOT mention individual spell installation
  if printf '%s' "$OUTPUT" | grep -q "jump-to-marker"; then
    TEST_FAILURE_REASON="installer should not pre-install individual spells (word-of-binding handles this)"
    return 1
  fi
}

install_mud_installs_cd_hook() {
  skip-if-compiled || return $?
  # Test that MUD installation installs the CD hook
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  rc_file="$fixture/home/.bashrc"
  
  # Create the rc file before the sandbox runs (for proper permissions)
  touch "$rc_file"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_RC_FILE="$rc_file" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      WIZARDRY_INSTALL_MUD=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should show MUD installation section
  assert_output_contains "Installing MUD" || return 1
  
  # Should install CD hook (verify via output since bwrap permissions prevent file read)
  assert_output_contains "CD hook" || return 1
  
  # Verify the cd cantrip was installed (via output message)
  assert_output_contains "runs 'look' on directory change" || return 1
}

install_mud_enables_config_features() {
  skip-if-compiled || return $?
  # Test that MUD installation enables MUD features
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq mkdir

  install_dir="$fixture/home/.wizardry"
  rc_file="$fixture/home/.bashrc"
  spellbook_home="$fixture/home/.spellbook"
  
  # Create the rc file before the sandbox runs (for proper permissions)
  touch "$rc_file"
  mkdir -p "$spellbook_home/.mud"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_RC_FILE="$rc_file" \
      SPELLBOOK_DIR="$spellbook_home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      WIZARDRY_INSTALL_MUD=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should show MUD installation section  
  assert_output_contains "Installing MUD" || return 1
  
  # Should show MUD features configured
  assert_output_contains "MUD features" || return 1
  assert_output_contains "installed" || return 1
}

install_without_mud_skips_mud_section() {
  skip-if-compiled || return $?
  # Test that install without MUD skips the MUD installation section
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq

  install_dir="$fixture/home/.wizardry"
  rc_file="$fixture/home/.bashrc"
  
  # Create the rc file before the sandbox runs (for proper permissions)
  touch "$rc_file"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_RC_FILE="$rc_file" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should NOT show MUD installation section
  if printf '%s' "$OUTPUT" | grep -q "Installing MUD"; then
    TEST_FAILURE_REASON="should not show MUD installation when not requested"
    return 1
  fi
  
  # CD hook should NOT be in the rc file
  if grep -q "wizardry cd cantrip" "$rc_file" 2>/dev/null; then
    TEST_FAILURE_REASON="CD hook should not be installed when MUD is not requested"
    return 1
  fi
}

install_mud_shows_planned_features() {
  skip-if-compiled || return $?
  # Test that MUD installation shows features were configured
  fixture=$(make_fixture)
  provide_basic_tools "$fixture"
  link_tools "$fixture/bin" cp mv tar pwd cat grep cut tr sed awk find uname chmod sort uniq mkdir

  install_dir="$fixture/home/.wizardry"
  
  run_cmd env WIZARDRY_INSTALL_DIR="$install_dir" \
      HOME="$fixture/home" \
      WIZARDRY_INSTALL_ASSUME_YES=1 \
      WIZARDRY_INSTALL_MUD=1 \
      "$ROOT_DIR/install"

  assert_success || return 1
  
  # Should show MUD features were configured
  assert_output_contains "MUD features configured" || return 1
}

# === Mac Install Bug Fix Tests ===
# Tests for the fix that adds .imps/sys to PATH and sources invoke-wizardry directly

install_sources_invoke_wizardry_successfully() {
  skip-if-compiled || return $?
  # Simulate what happens when install script sources invoke-wizardry
  tmp=$(make_tempdir)
  test_script="$tmp/test-install.sh"
  
  cat >"$test_script" <<'EOF'
#!/bin/sh
# Simulate install script sourcing invoke-wizardry
export WIZARDRY_DIR="$1"
INVOKE_WIZARDRY="$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry"

# Source invoke-wizardry like the install script does
sourcing_succeeded=0
if [ -f "$INVOKE_WIZARDRY" ] && . "$INVOKE_WIZARDRY" 2>/dev/null; then
  sourcing_succeeded=1
fi

if [ "$sourcing_succeeded" -eq 1 ]; then
  echo "Sourcing succeeded"
  # Try to run menu --help
  if command -v menu >/dev/null 2>&1; then
    echo "menu is available"
  else
    echo "menu is NOT available"
    exit 1
  fi
else
  echo "Sourcing failed"
  exit 1
fi
EOF
  
  chmod +x "$test_script"
  
  # Run the test script
  run_cmd sh "$test_script" "$ROOT_DIR"
  assert_success || return 1
  assert_output_contains "Sourcing succeeded" || return 1
  assert_output_contains "menu is available" || return 1
}

install_rc_file_sources_invoke_wizardry() {
  skip-if-compiled || return $?
  # Simulate what happens when a new shell sources the rc file
  tmp=$(make_tempdir)
  rc_file="$tmp/.bashrc"
  test_script="$tmp/test-rc.sh"
  
  # Create a fake rc file with invoke-wizardry source line
  cat >"$rc_file" <<EOF
# Fake bashrc
export WIZARDRY_DIR="\$1"
. "\$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" # wizardry: wizardry-init
EOF
  
  # Create a script that sources the rc file then runs menu
  cat >"$test_script" <<'EOF'
#!/bin/sh
export HOME="$2"
. "$2/.bashrc" "$1" >/dev/null 2>&1 || exit 1
# Try to run menu --help
if command -v menu >/dev/null 2>&1; then
  echo "menu is available after sourcing rc"
else
  echo "menu is NOT available after sourcing rc"
  exit 1
fi
EOF
  
  chmod +x "$test_script"
  
  # Run the test script
  run_cmd sh "$test_script" "$ROOT_DIR" "$tmp"
  assert_success || return 1
  assert_output_contains "menu is available after sourcing rc" || return 1
}

install_menu_help_works_after_invoke() {
  skip-if-compiled || return $?
  # Test that menu works after invoke-wizardry is sourced
  tmp=$(make_tempdir)
  test_script="$tmp/test-menu.sh"
  
  cat >"$test_script" <<'EOF'
#!/bin/sh
export WIZARDRY_DIR="$1"
# Redirect invoke-wizardry's output to stderr so it doesn't pollute menu's output
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" >/dev/null 2>&1 || exit 1
"$WIZARDRY_DIR/spells/cantrips/menu" --help
EOF
  
  chmod +x "$test_script"
  
  # Run the test script
  run_cmd sh "$test_script" "$ROOT_DIR"
  assert_success || return 1
  # menu --help outputs to stderr, so check ERROR instead of OUTPUT
  assert_error_contains "Usage:" || return 1
  assert_error_contains "menu" || return 1
}

install_require_wizardry_available() {
  skip-if-compiled || return $?
  # Test that require-wizardry is available after invoke-wizardry is sourced
  tmp=$(make_tempdir)
  test_script="$tmp/test-require.sh"
  
  cat >"$test_script" <<'EOF'
#!/bin/sh
export WIZARDRY_DIR="$1"
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null || exit 1
# Try to execute require-wizardry - it should be in PATH or aliased
if command -v require-wizardry >/dev/null 2>&1; then
  echo "require-wizardry is available"
  exit 0
else
  echo "require-wizardry NOT available"
  exit 1
fi
EOF
  
  chmod +x "$test_script"
  
  # Run the test script
  run_cmd sh "$test_script" "$ROOT_DIR"
  assert_success || return 1
  assert_output_contains "require-wizardry is available" || return 1
}

install_imps_sys_in_path() {
  skip-if-compiled || return $?
  # Test that .imps/sys is in PATH after invoke-wizardry is sourced
  tmp=$(make_tempdir)
  test_script="$tmp/test-path.sh"
  
  cat >"$test_script" <<'EOF'
#!/bin/sh
export WIZARDRY_DIR="$1"
. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry" 2>/dev/null || exit 1
# Check if .imps/sys is in PATH
case ":$PATH:" in
  *":$WIZARDRY_DIR/spells/.imps/sys:"*)
    echo ".imps/sys is in PATH"
    exit 0
    ;;
  *)
    echo ".imps/sys NOT in PATH"
    exit 1
    ;;
esac
EOF
  
  chmod +x "$test_script"
  
  # Run the test script
  run_cmd sh "$test_script" "$ROOT_DIR"
  assert_success || return 1
  assert_output_contains ".imps/sys is in PATH" || return 1
}

install_invoke_wizardry_custom_location() {
  skip-if-compiled || return $?
  # Test that invoke-wizardry auto-detects its location (fixes macOS menu issue)
  # This tests the fix for the bug where menu wasn't found after install on macOS
  # when wizardry is installed to a location other than ~/.wizardry
  #
  # NOTE: This test runs outside the sandbox (no run_cmd) because bwrap's
  # filesystem bindings interfere with path resolution testing
  tmp=$(make_tempdir)
  
  # Create a custom install location (simulating WIZARDRY_INSTALL_DIR=/custom/path)
  custom_install="$tmp/custom/wizardry-install"
  mkdir -p "$custom_install"
  # Only copy spells directory (not the entire repo) to avoid confusion
  cp -R "$ROOT_DIR/spells" "$custom_install/"
  
  test_script="$tmp/test-custom.sh"
  
  cat >"$test_script" <<'EOF'
#!/bin/bash
# Simulate sourcing invoke-wizardry from a custom location (like .zprofile does)
CUSTOM_INSTALL="$1"

# Unset WIZARDRY_DIR to force auto-detection (test framework sets it)
unset WIZARDRY_DIR

# Source invoke-wizardry - it should auto-detect its location via BASH_SOURCE
. "$CUSTOM_INSTALL/spells/.imps/sys/invoke-wizardry" >/dev/null 2>&1 || exit 1

# Normalize both paths for comparison (macOS /var -> /private/var symlink)
# Use cd + pwd -P to resolve symlinks to canonical paths
EXPECTED=$(cd "$CUSTOM_INSTALL" 2>/dev/null && pwd -P)
ACTUAL=$(cd "$WIZARDRY_DIR" 2>/dev/null && pwd -P)

# Verify WIZARDRY_DIR was set correctly to the custom location
if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "FAIL: WIZARDRY_DIR mismatch"
  echo "Expected: $EXPECTED"
  echo "Got: $ACTUAL"
  exit 1
fi

# Verify menu is available in PATH
if ! command -v menu >/dev/null 2>&1; then
  echo "FAIL: menu not in PATH"
  echo "PATH: $PATH"
  exit 1
fi

echo "SUCCESS: menu found at custom location"
EOF
  
  chmod +x "$test_script"
  
  # Run directly with bash (not via run_cmd) to avoid bwrap path issues
  if OUTPUT=$(bash "$test_script" "$custom_install" 2>&1); then
    if printf '%s' "$OUTPUT" | grep -q "SUCCESS: menu found at custom location"; then
      return 0
    else
      TEST_FAILURE_REASON="output missing success message: $OUTPUT"
      return 1
    fi
  else
    TEST_FAILURE_REASON="test script failed: $OUTPUT"
    return 1
  fi
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
run_test_case "install fresh does not show menu" install_fresh_does_not_show_menu
run_test_case "install shows help" shows_help
run_test_case "install NixOS shows shell config updated" install_nixos_shows_shell_config_updated
run_test_case "install does not show spell installation" install_does_not_show_spell_installation
run_test_case "install creates .uninstall script" install_creates_uninstall_script_with_correct_name
run_test_case "install does not show uninstall on success" install_does_not_show_uninstall_on_success
run_test_case "install shows simple run message" install_shows_simple_run_message
run_test_case "install no adding missing path on fresh" install_does_not_show_adding_missing_path_on_fresh
run_test_case "install NixOS shows config file message" install_nixos_shows_config_file_message
run_test_case "install NixOS shows shell config updated message" install_nixos_shows_shell_config_updated_message
run_test_case "install NixOS shows appropriate message" install_nixos_shows_appropriate_message
run_test_case "install non-NixOS shows source message" install_non_nixos_shows_source_message
run_test_case "uninstall script removes invoke-wizardry" uninstall_script_removes_invoke_wizardry
run_test_case "uninstall script NixOS includes rebuild" uninstall_script_nixos_includes_rebuild
run_test_case "uninstall script NixOS includes terminal message" uninstall_script_nixos_includes_terminal_message
run_test_case "install shows revised prompt text" install_shows_revised_prompt_text
run_test_case "learn-spellbook remove-all removes all nix entries" path_wizard_remove_all_removes_all_nix_entries
run_test_case "learn-spellbook remove-all reports count" path_wizard_remove_all_reports_count
run_test_case "learn-spellbook remove-all handles empty file" path_wizard_remove_all_handles_empty_file
run_test_case "install no spell preinstallation" install_no_spell_preinstallation
run_test_case "install MUD setup" install_mud_setup
run_test_case "install MUD installs CD hook" install_mud_installs_cd_hook
run_test_case "install MUD enables config features" install_mud_enables_config_features
run_test_case "install without MUD skips MUD section" install_without_mud_skips_mud_section
run_test_case "install MUD shows planned features" install_mud_shows_planned_features
run_test_case "install sources invoke-wizardry successfully" install_sources_invoke_wizardry_successfully
run_test_case "install rc file sources invoke-wizardry" install_rc_file_sources_invoke_wizardry
run_test_case "install menu works after invoke-wizardry" install_menu_help_works_after_invoke
run_test_case "install require-wizardry available" install_require_wizardry_available
run_test_case "install imps/sys in PATH" install_imps_sys_in_path
run_test_case "install invoke-wizardry custom location (macOS fix)" install_invoke_wizardry_custom_location

finish_tests
