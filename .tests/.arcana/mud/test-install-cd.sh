#!/bin/sh
# Tests for install-cd spell
# install-cd installs the cd hook by adding a source line to the shell RC file

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_install_cd_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/mud/install-cd" ]
}

test_install_cd_help_shows_usage() {
  _run_spell spells/.arcana/mud/install-cd --help
  _assert_success || return 1
  _assert_output_contains "Usage:" || return 1
  _assert_output_contains "install-cd" || return 1
}

test_install_cd_installs_to_rc_file() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  
  # Create fake home with bashrc
  fake_home="$tmpdir/home"
  mkdir -p "$fake_home"
  rc_file="$fake_home/.bashrc"
  touch "$rc_file"
  
  # Create a stub detect-rc-file that returns our test rc file
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/detect-rc-file" << STUB_EOF
#!/bin/sh
printf 'rc_file=%s\n' "$rc_file"
printf 'format=shell\n'
STUB_EOF
  chmod +x "$stub_dir/detect-rc-file"
  
  # Run install-cd with stubbed PATH and HOME
  cd_hook_path="$ROOT_DIR/spells/.arcana/mud/cd"
  output=$(env HOME="$fake_home" PATH="$stub_dir:$PATH" sh "$ROOT_DIR/spells/.arcana/mud/install-cd" 2>&1)
  
  # Check output contains success message
  case "$output" in
    *"cd hook installed"*)
      ;;
    *)
      TEST_FAILURE_REASON="Output missing 'cd hook installed': $output"
      return 1
      ;;
  esac
  
  # Verify RC file has the source line
  if ! grep -qF "$cd_hook_path" "$rc_file"; then
    TEST_FAILURE_REASON="RC file doesn't contain cd hook path. Contents: $(cat "$rc_file")"
    return 1
  fi
  
  # Verify marker comment was added
  if ! grep -q "wizardry: cd-hook" "$rc_file"; then
    TEST_FAILURE_REASON="RC file doesn't contain marker comment"
    return 1
  fi
}

test_install_cd_skips_if_already_installed() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  
  # Create fake home with bashrc
  fake_home="$tmpdir/home"
  mkdir -p "$fake_home"
  rc_file="$fake_home/.bashrc"
  
  # Pre-populate RC file with cd hook
  cd_hook_path="$ROOT_DIR/spells/.arcana/mud/cd"
  printf '# wizardry: cd-hook\n. "%s"\n' "$cd_hook_path" > "$rc_file"
  
  # Create stub detect-rc-file
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/detect-rc-file" << STUB_EOF
#!/bin/sh
printf 'rc_file=%s\n' "$rc_file"
printf 'format=shell\n'
STUB_EOF
  chmod +x "$stub_dir/detect-rc-file"
  
  # Run install-cd
  output=$(env HOME="$fake_home" PATH="$stub_dir:$PATH" sh "$ROOT_DIR/spells/.arcana/mud/install-cd" 2>&1)
  
  # Check output says already installed
  case "$output" in
    *"already installed"*)
      ;;
    *)
      TEST_FAILURE_REASON="Output missing 'already installed': $output"
      return 1
      ;;
  esac
  
  # Count how many times the cd hook appears in the file
  count=$(grep -c "$cd_hook_path" "$rc_file" || echo 0)
  if [ "$count" -ne 1 ]; then
    TEST_FAILURE_REASON="Expected 1 occurrence of cd hook, found $count"
    return 1
  fi
}

test_install_cd_handles_nix_format() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  
  # Create a test root directory structure
  test_root="$tmpdir/wizardry"
  mkdir -p "$test_root/spells/divination"
  mkdir -p "$test_root/spells/.arcana/mud"
  
  # Copy the cd hook file
  cp "$ROOT_DIR/spells/.arcana/mud/cd" "$test_root/spells/.arcana/mud/cd"
  
  # Create a fake detect-rc-file that returns nix format
  cat > "$test_root/spells/divination/detect-rc-file" << 'DETECT_EOF'
#!/bin/sh
printf 'rc_file=/etc/nixos/configuration.nix\n'
printf 'format=nix\n'
DETECT_EOF
  chmod +x "$test_root/spells/divination/detect-rc-file"
  
  # Copy install-cd to test location
  cp "$ROOT_DIR/spells/.arcana/mud/install-cd" "$test_root/spells/.arcana/mud/install-cd"
  
  # Run install-cd from the test root
  output=$(cd "$test_root/spells/.arcana/mud" && sh install-cd 2>&1)
  
  # Should skip installation for NixOS
  case "$output" in
    *"not supported on NixOS"*)
      ;;
    *)
      TEST_FAILURE_REASON="Expected NixOS skip message, got: $output"
      return 1
      ;;
  esac
}

test_install_cd_creates_rc_file_if_missing() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  
  # Create fake home WITHOUT bashrc
  fake_home="$tmpdir/home"
  mkdir -p "$fake_home"
  rc_file="$fake_home/.bashrc"
  # Don't create the file - let install-cd create it
  
  # Create stub detect-rc-file
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  cat > "$stub_dir/detect-rc-file" << STUB_EOF
#!/bin/sh
printf 'rc_file=%s\n' "$rc_file"
printf 'format=shell\n'
STUB_EOF
  chmod +x "$stub_dir/detect-rc-file"
  
  # Run install-cd
  output=$(env HOME="$fake_home" PATH="$stub_dir:$PATH" sh "$ROOT_DIR/spells/.arcana/mud/install-cd" 2>&1)
  
  # Verify RC file was created
  if [ ! -f "$rc_file" ]; then
    TEST_FAILURE_REASON="RC file was not created"
    return 1
  fi
  
  # Verify it has the cd hook source line
  cd_hook_path="$ROOT_DIR/spells/.arcana/mud/cd"
  if ! grep -qF "$cd_hook_path" "$rc_file"; then
    TEST_FAILURE_REASON="RC file doesn't contain cd hook path"
    return 1
  fi
}

_run_test_case "install-cd is executable" test_install_cd_is_executable
_run_test_case "install-cd --help shows usage" test_install_cd_help_shows_usage
_run_test_case "install-cd installs to rc file" test_install_cd_installs_to_rc_file
_run_test_case "install-cd skips if already installed" test_install_cd_skips_if_already_installed
_run_test_case "install-cd handles nix format" test_install_cd_handles_nix_format
_run_test_case "install-cd creates rc file if missing" test_install_cd_creates_rc_file_if_missing
_finish_tests
