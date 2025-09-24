#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  system_stubs=$(wizardry_install_systemd_stubs)
  service_name="wizardry-test-$$"
  service_file="/etc/systemd/system/$service_name.service"
  rm -f "$service_file"
}

teardown() {
  rm -f "$service_file"
  PATH=$ORIGINAL_PATH
  default_teardown
}

@test 'is-service-installed fails when systemctl unavailable or service missing' {
  PATH=$ORIGINAL_PATH run_spell 'spells/is-service-installed' "$service_name"
  assert_failure

  PATH="$(wizardry_join_paths "$system_stubs" "$ORIGINAL_PATH")" run_spell 'spells/is-service-installed' "$service_name"
  assert_failure
}

@test 'is-service-installed detects installed services with optional suffix' {
  printf '[Unit]\nDescription=Wizardry test service\n' | "$system_stubs/sudo" tee "$service_file" >/dev/null

  PATH="$(wizardry_join_paths "$system_stubs" "$ORIGINAL_PATH")" run_spell 'spells/is-service-installed' "$service_name"
  assert_success

  PATH="$(wizardry_join_paths "$system_stubs" "$ORIGINAL_PATH")" run_spell 'spells/is-service-installed' "$service_name.service"
  assert_success
}

