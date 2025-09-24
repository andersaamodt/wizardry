#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"
source "$(dirname "$0")/lib/stub_helpers.sh"

BASE_PATH=$PATH
uname_stub=$(wizardry_install_uname_stub)

backup_files=()
backup_file() {
  local file=$1
  if [ -f "$file" ]; then
    mv "$file" "$file.wizardrybak"
    backup_files+=("$file")
  fi
}
restore_files() {
  for file in "${backup_files[@]}"; do
    if [ -f "$file.wizardrybak" ]; then
      mv "$file.wizardrybak" "$file"
    fi
  done
}
trap restore_files EXIT

run_detect() {
  local path_override
  path_override=$(wizardry_join_paths "$ROOT_DIR/spells/cantrips" "$uname_stub" "$BASE_PATH")
  RUN_PATH_OVERRIDE="$path_override" run_script "spells/detect-distro" "$@"
}

# Debian detection (default environment)
run_detect
expect_exit_code 0
expect_in_output "debian" "$RUN_STDOUT"

# Verbose Debian message includes color codes
run_detect -v
expect_exit_code 0
expect_in_output "Debian" "$RUN_STDOUT"

# Force Arch detection
backup_file /etc/debian_version
backup_file /etc/arch-release
backup_file /etc/fedora-release
rm -f /etc/debian_version /etc/arch-release /etc/fedora-release
printf 'arch' >/etc/arch-release
run_detect
expect_exit_code 0
expect_in_output "arch" "$RUN_STDOUT"

# Force Fedora detection
rm -f /etc/arch-release
printf 'fedora' >/etc/fedora-release
run_detect
expect_exit_code 0
expect_in_output "fedora" "$RUN_STDOUT"

# Fake Darwin via uname
rm -f /etc/fedora-release
FAKE_UNAME_OUTPUT=Darwin run_detect
expect_exit_code 0
expect_in_output "mac" "$RUN_STDOUT"

FAKE_UNAME_OUTPUT=Darwin run_detect -v
expect_exit_code 0
expect_in_output "MacOS" "$RUN_STDOUT"

# Unknown OS when no markers found
rm -f /etc/debian_version /etc/arch-release /etc/fedora-release
FAKE_UNAME_OUTPUT=Unknown run_detect
expect_exit_code 1
expect_in_output "unknown" "$RUN_STDOUT"

restore_files

assert_all_expectations_met
