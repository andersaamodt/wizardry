#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  system_stubs=$(wizardry_install_systemd_stubs)
  service_name="wizardry-remove-$$"
  service_file="/etc/systemd/system/$service_name.service"
  rm -f "$service_file"
  tmp_dir="$BATS_TEST_TMPDIR/system"
  mkdir -p "$tmp_dir"
}

teardown() {
  rm -f "$service_file"
  PATH=$ORIGINAL_PATH
  default_teardown
}

with_system_path() {
  PATH="$(wizardry_join_paths "$system_stubs" "$ORIGINAL_PATH")" "$@"
}

@test 'remove-service requires systemctl and existing service' {
  PATH=$ORIGINAL_PATH run_spell 'spells/cantrips/remove-service' "$service_name"
  assert_failure

  with_system_path run_spell 'spells/cantrips/remove-service' "$service_name"
  assert_failure
  assert_output --partial "Service ${service_name}.service does not exist."
}

@test 'remove-service deletes unit file and reloads daemon' {
  printf '[Unit]\nDescription=Remove Service Test\n' | "$system_stubs/sudo" tee "$service_file" >/dev/null
  SYSTEMCTL_STATE_DIR="$tmp_dir" with_system_path run_spell 'spells/cantrips/remove-service' "$service_name"
  assert_success
  assert_output --partial "Service ${service_name}.service removed."
  [ ! -f "$service_file" ]
  [ -f "$tmp_dir/systemctl/daemon-reload" ]
}

@test 'remove-service stops active services before removal' {
  printf '[Unit]\nDescription=Remove Service Test\n' | "$system_stubs/sudo" tee "$service_file" >/dev/null
  mkdir -p "$tmp_dir/systemctl"
  touch "$tmp_dir/systemctl/${service_name}.service.active"
  SYSTEMCTL_STATE_DIR="$tmp_dir" with_system_path run_spell 'spells/cantrips/remove-service' "$service_name"
  assert_success
  [[ "$output" != *'does not exist'* ]]
  [ ! -f "$tmp_dir/systemctl/${service_name}.service.active" ]
}

