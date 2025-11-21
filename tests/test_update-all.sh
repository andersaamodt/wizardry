#!/bin/sh
# Behavioral cases (derived from --help):
# - update-all prints usage
# - update-all rejects unknown options and unexpected args
# - update-all fails when ask_yn is missing
# - update-all aborts when user declines confirmation
# - update-all aborts on unsupported platforms
# - update-all runs the distro update steps with progress helpers
# - update-all propagates failures from distro update commands
# - update-all supports arch and nixos flows

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
run_spell "spells/update-all" --help
  assert_success && assert_output_contains "Usage: update-all"
}

test_argument_validation() {
  run_spell "spells/update-all" --unknown
  assert_failure && assert_error_contains "Unknown option"

  run_spell "spells/update-all" extra
  assert_failure && assert_error_contains "Unexpected argument"
}

test_missing_confirmation_helper() {
  run_cmd env PATH="/usr/bin" WIZARDRY_UPDATE_ALL_DISTRO=debian "$(pwd)/spells/update-all"
  assert_failure
  assert_output_contains "Detected platform: debian"
  assert_error_contains "ask_yn spell is missing"
}

test_user_declines_updates() {
  stub_dir=$(mktemp -d "$WIZARDRY_TMPDIR/update-all.decline.XXXXXX")

  cat >"$stub_dir/ask_yn" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$stub_dir/ask_yn"

  run_cmd env PATH="$stub_dir:$PATH" WIZARDRY_UPDATE_ALL_DISTRO=debian "$(pwd)/spells/update-all"
  assert_failure
  assert_output_contains "Detected platform: debian"
  assert_error_contains "cancelled by user"
}

test_unsupported_platform() {
  temp_dir=$(make_tempdir)
  cp "$(pwd)/spells/update-all" "$temp_dir/update-all"
  cat >"$temp_dir/detect-distro" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$temp_dir/detect-distro"

  run_cmd "$temp_dir/update-all"
  assert_failure && assert_error_contains "Unable to detect operating system"

  run_cmd env WIZARDRY_UPDATE_ALL_ASSUME_YES=1 WIZARDRY_UPDATE_ALL_DISTRO=plan9 "$(pwd)/spells/update-all"
  assert_status 2
  assert_error_contains "Unsupported platform: plan9"
}

test_debian_update_flow() {
  stub_dir=$(mktemp -d "$WIZARDRY_TMPDIR/update-all.XXXXXX")
  log="$stub_dir/log"

  cat >"$stub_dir/sudo" <<EOF
#!/bin/sh
log_path="$log"
echo "sudo \$*" >>"\$log_path"
exec "\$@"
EOF
  chmod +x "$stub_dir/sudo"

  cat >"$stub_dir/apt-get" <<EOF
#!/bin/sh
log_path="$log"
echo "apt-get \$*" >>"\$log_path"
exit 0
EOF
  chmod +x "$stub_dir/apt-get"

  run_cmd env PATH="$stub_dir:$PATH" WIZARDRY_UPDATE_ALL_ASSUME_YES=1 WIZARDRY_UPDATE_ALL_DISTRO=debian "$(pwd)/spells/update-all"
  assert_success
  assert_output_contains "Detected platform: debian"
  assert_output_contains "All updates complete"
  assert_file_contains "$log" "sudo apt-get update"
  assert_file_contains "$log" "apt-get -o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y full-upgrade"
  assert_file_contains "$log" "apt-get -o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y autoremove"
}

test_debian_update_failure_propagates() {
  stub_dir=$(mktemp -d "$WIZARDRY_TMPDIR/update-all.fail.XXXXXX")
  log="$stub_dir/log"

  cat >"$stub_dir/sudo" <<EOF
#!/bin/sh
log_path="$log"
echo "sudo \$*" >>"\$log_path"
exec "\$@"
EOF
  chmod +x "$stub_dir/sudo"

  cat >"$stub_dir/apt-get" <<EOF
#!/bin/sh
log_path="$log"
echo "apt-get \$*" >>"\$log_path"
case "$*" in
  *"full-upgrade"*) exit 9 ;;
esac
exit 0
EOF
  chmod +x "$stub_dir/apt-get"

  run_cmd env PATH="$stub_dir:$PATH" WIZARDRY_UPDATE_ALL_ASSUME_YES=1 WIZARDRY_UPDATE_ALL_DISTRO=debian "$(pwd)/spells/update-all"
  assert_status 9
  assert_file_contains "$log" "apt-get -o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y full-upgrade"
}

test_arch_update_flow() {
  stub_dir=$(mktemp -d "$WIZARDRY_TMPDIR/update-all.arch.XXXXXX")
  log="$stub_dir/log"

  cat >"$stub_dir/sudo" <<EOF
#!/bin/sh
log_path="$log"
echo "sudo \$*" >>"\$log_path"
exec "\$@"
EOF
  chmod +x "$stub_dir/sudo"

  cat >"$stub_dir/pacman" <<EOF
#!/bin/sh
log_path="$log"
echo "pacman \$*" >>"\$log_path"
exit 0
EOF
  chmod +x "$stub_dir/pacman"

  cat >"$stub_dir/pamac" <<EOF
#!/bin/sh
log_path="$log"
echo "pamac \$*" >>"\$log_path"
exit 0
EOF
  chmod +x "$stub_dir/pamac"

  run_cmd env PATH="$stub_dir:$PATH" WIZARDRY_UPDATE_ALL_ASSUME_YES=1 WIZARDRY_UPDATE_ALL_DISTRO=arch "$(pwd)/spells/update-all"
  assert_success
  assert_file_contains "$log" "sudo pacman -Syu --noconfirm"
  assert_file_contains "$log" "pamac update --no-confirm"
  assert_file_contains "$log" "pamac build --no-confirm"
}

test_nixos_update_flow() {
  stub_dir=$(mktemp -d "$WIZARDRY_TMPDIR/update-all.nixos.XXXXXX")
  log="$stub_dir/log"

  cat >"$stub_dir/sudo" <<EOF
#!/bin/sh
log_path="$log"
echo "sudo \$*" >>"\$log_path"
exec "\$@"
EOF
  chmod +x "$stub_dir/sudo"

  for cmd in nix-channel nixos-rebuild nix-env; do
    cat >"$stub_dir/$cmd" <<EOF
#!/bin/sh
log_path="$log"
echo "$cmd \$*" >>"\$log_path"
exit 0
EOF
    chmod +x "$stub_dir/$cmd"
  done

  run_cmd env PATH="$stub_dir:$PATH" WIZARDRY_UPDATE_ALL_ASSUME_YES=1 WIZARDRY_UPDATE_ALL_DISTRO=nixos "$(pwd)/spells/update-all"
  assert_success
  assert_file_contains "$log" "sudo nix-channel --update"
  assert_file_contains "$log" "sudo nixos-rebuild switch --upgrade"
  assert_file_contains "$log" "nix-channel --update"
  assert_file_contains "$log" "nix-env -u --always"
}

run_test_case "update-all prints usage" test_help
run_test_case "update-all validates arguments" test_argument_validation
run_test_case "update-all fails without ask_yn" test_missing_confirmation_helper
run_test_case "update-all aborts when user declines" test_user_declines_updates
run_test_case "update-all handles unsupported platforms" test_unsupported_platform
run_test_case "update-all performs debian updates" test_debian_update_flow
run_test_case "update-all propagates update failures" test_debian_update_failure_propagates
run_test_case "update-all performs arch updates" test_arch_update_flow
run_test_case "update-all performs nixos updates" test_nixos_update_flow
finish_tests
