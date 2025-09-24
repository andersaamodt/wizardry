#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  uname_stub=$(wizardry_install_uname_stub)
  backup_files=()
  created_files=()
  ensure_default_release_state
}

teardown() {
  restore_files
  PATH=$ORIGINAL_PATH
  default_teardown
}

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
  backup_files=()

  for file in "${created_files[@]}"; do
    rm -f "$file"
  done
  created_files=()
}

ensure_default_release_state() {
  local file

  for file in /etc/arch-release /etc/fedora-release; do
    if [ -f "$file" ]; then
      backup_file "$file"
      rm -f "$file"
    fi
  done

  if [ -f /etc/debian_version ]; then
    backup_file /etc/debian_version
  else
    created_files+=(/etc/debian_version)
  fi
  printf 'debian\n' >/etc/debian_version
}

run_detect() {
  local path_override
  path_override=$(wizardry_join_paths "$ROOT_DIR/spells/cantrips" "$uname_stub" "$ORIGINAL_PATH")
  PATH="$path_override" run_spell 'spells/detect-distro' "$@"
}

@test 'detect-distro identifies Debian by default' {
  run_detect
  assert_success
  assert_output --partial 'debian'
}

@test 'detect-distro verbose output for Debian' {
  run_detect -v
  assert_success
  assert_output --partial 'Debian'
}

@test 'detect-distro recognises Arch when markers present' {
  backup_file /etc/debian_version
  backup_file /etc/arch-release
  backup_file /etc/fedora-release
  rm -f /etc/debian_version /etc/arch-release /etc/fedora-release
  printf 'arch' >/etc/arch-release

  run_detect
  assert_success
  assert_output --partial 'arch'
}

@test 'detect-distro recognises Fedora marker' {
  backup_file /etc/debian_version
  backup_file /etc/arch-release
  backup_file /etc/fedora-release
  rm -f /etc/arch-release
  printf 'fedora' >/etc/fedora-release

  run_detect
  assert_success
  assert_output --partial 'fedora'
}

@test 'detect-distro uses uname for Darwin systems' {
  backup_file /etc/debian_version
  backup_file /etc/arch-release
  backup_file /etc/fedora-release
  rm -f /etc/fedora-release
  FAKE_UNAME_OUTPUT=Darwin run_detect
  assert_success
  assert_output --partial 'mac'

  FAKE_UNAME_OUTPUT=Darwin run_detect -v
  assert_success
  assert_output --partial 'MacOS'
}

@test 'detect-distro reports unknown when no hints found' {
  backup_file /etc/debian_version
  backup_file /etc/arch-release
  backup_file /etc/fedora-release
  rm -f /etc/debian_version /etc/arch-release /etc/fedora-release
  FAKE_UNAME_OUTPUT=Unknown run_detect
  assert_failure
  assert_output --partial 'unknown'
}

