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

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/system/update-all" --help
  _assert_success && _assert_output_contains "Usage: update-all"
}

test_argument_validation() {
  _run_spell "spells/system/update-all" --unknown
  _assert_failure && _assert_error_contains "Usage:"

  _run_spell "spells/system/update-all" extra
  _assert_failure && _assert_error_contains "Usage:"
}

test_missing_confirmation_helper() {
  skip-if-compiled || return $?
  _run_cmd env PATH="$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/pkg:$ROOT_DIR/spells/.imps/menu:$ROOT_DIR/spells/.imps/test:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/input:/bin:/usr/bin" WIZARDRY_UPDATE_ALL_DISTRO=debian "$(pwd)/spells/system/update-all"
  _assert_failure
  _assert_output_contains "Detected platform: debian"
  _assert_error_contains "ask-yn spell is missing"
}

test_user_declines_updates() {
  skip-if-compiled || return $?
  stub_dir=$(mktemp -d "$WIZARDRY_TMPDIR/update-all.decline.XXXXXX")

  cat >"$stub_dir/ask-yn" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$stub_dir/ask-yn"

  _run_cmd env PATH="$stub_dir:$PATH" WIZARDRY_UPDATE_ALL_DISTRO=debian "$(pwd)/spells/system/update-all"
  _assert_failure
  _assert_output_contains "Detected platform: debian"
  _assert_error_contains "cancelled by user"
}

test_unsupported_platform() {
  skip-if-compiled || return $?
  temp_dir=$(_make_tempdir)
  cp "$(pwd)/spells/system/update-all" "$temp_dir/update-all"
  cat >"$temp_dir/detect-distro" <<'EOF'
#!/bin/sh
exit 1
EOF
  chmod +x "$temp_dir/detect-distro"

  _run_cmd env PATH="$temp_dir:$PATH" "$temp_dir/update-all"
  _assert_failure && _assert_error_contains "Unable to detect operating system"

  _run_cmd env WIZARDRY_UPDATE_ALL_ASSUME_YES=1 WIZARDRY_UPDATE_ALL_DISTRO=plan9 "$(pwd)/spells/system/update-all"
  _assert_status 2
  _assert_error_contains "Unsupported platform: plan9"
}

test_debian_update_flow() {
  skip-if-compiled || return $?
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

  _run_cmd env PATH="$stub_dir:$PATH" WIZARDRY_UPDATE_ALL_ASSUME_YES=1 WIZARDRY_UPDATE_ALL_DISTRO=debian "$(pwd)/spells/system/update-all"
  _assert_success
  _assert_output_contains "Detected platform: debian"
  _assert_output_contains "All updates complete"
  _assert_file_contains "$log" "sudo apt-get update"
  _assert_file_contains "$log" "apt-get -o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y full-upgrade"
  _assert_file_contains "$log" "apt-get -o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y autoremove"
}

test_debian_update_failure_propagates() {
  skip-if-compiled || return $?
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

  _run_cmd env PATH="$stub_dir:$PATH" WIZARDRY_UPDATE_ALL_ASSUME_YES=1 WIZARDRY_UPDATE_ALL_DISTRO=debian "$(pwd)/spells/system/update-all"
  _assert_status 9
  _assert_file_contains "$log" "apt-get -o Dpkg::Progress-Fancy=1 -o Dpkg::Use-Pty=0 -y full-upgrade"
}

test_arch_update_flow() {
  skip-if-compiled || return $?
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

  _run_cmd env PATH="$stub_dir:$PATH" WIZARDRY_UPDATE_ALL_ASSUME_YES=1 WIZARDRY_UPDATE_ALL_DISTRO=arch "$(pwd)/spells/system/update-all"
  _assert_success
  _assert_file_contains "$log" "sudo pacman -Syu --noconfirm"
  _assert_file_contains "$log" "pamac update --no-confirm"
  _assert_file_contains "$log" "pamac build --no-confirm"
}

test_nixos_update_flow() {
  skip-if-compiled || return $?
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

  _run_cmd env PATH="$stub_dir:$PATH" WIZARDRY_UPDATE_ALL_ASSUME_YES=1 WIZARDRY_UPDATE_ALL_DISTRO=nixos "$(pwd)/spells/system/update-all"
  _assert_success
  _assert_file_contains "$log" "sudo nix-channel --update"
  _assert_file_contains "$log" "sudo nixos-rebuild switch --upgrade"
  _assert_file_contains "$log" "nix-channel --update"
  _assert_file_contains "$log" "nix-env -u --always"
}

_run_test_case "update-all prints usage" test_help
_run_test_case "update-all validates arguments" test_argument_validation
_run_test_case "update-all fails without ask_yn" test_missing_confirmation_helper
_run_test_case "update-all aborts when user declines" test_user_declines_updates
_run_test_case "update-all handles unsupported platforms" test_unsupported_platform
_run_test_case "update-all performs debian updates" test_debian_update_flow
_run_test_case "update-all propagates update failures" test_debian_update_failure_propagates
_run_test_case "update-all performs arch updates" test_arch_update_flow
_run_test_case "update-all performs nixos updates" test_nixos_update_flow
_finish_tests
