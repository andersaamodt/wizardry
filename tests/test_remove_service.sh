#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"
source "$(dirname "$0")/lib/stub_helpers.sh"

BASE_PATH=$PATH
system_stubs=$(wizardry_install_systemd_stubs)

service_name="wizardry-remove-$$"
service_file="/etc/systemd/system/$service_name.service"
rm -f "$service_file"
tmp_dir=$(make_temp_dir)
state_dir="$tmp_dir/system"
mkdir -p "$state_dir"

RUN_PATH_OVERRIDE="$BASE_PATH" run_script "spells/remove-service" "$service_name"
expect_exit_code 1

RUN_PATH_OVERRIDE="$(wizardry_join_paths "$system_stubs" "$BASE_PATH")" run_script "spells/remove-service" "$service_name"
expect_exit_code 1
expect_in_output "Service ${service_name}.service does not exist." "$RUN_STDOUT"

printf '[Unit]\nDescription=Remove Service Test\n' | "$system_stubs/sudo" tee "$service_file" >/dev/null
SYSTEMCTL_STATE_DIR="$tmp_dir" RUN_PATH_OVERRIDE="$(wizardry_join_paths "$system_stubs" "$BASE_PATH")" \
  run_script "spells/remove-service" "$service_name"
expect_exit_code 0
expect_in_output "Service ${service_name}.service removed." "$RUN_STDOUT"
expect_eq "no" "$( [ -f "$service_file" ] && echo yes || echo no )" "Service file should be deleted"
expect_eq "yes" "$( [ -f "$tmp_dir/systemctl/daemon-reload" ] && echo yes || echo no )" "systemctl daemon-reload should run"

printf '[Unit]\nDescription=Remove Service Test\n' | "$system_stubs/sudo" tee "$service_file" >/dev/null
touch "$tmp_dir/systemctl/${service_name}.service.active"
SYSTEMCTL_STATE_DIR="$tmp_dir" RUN_PATH_OVERRIDE="$(wizardry_join_paths "$system_stubs" "$BASE_PATH")" \
  run_script "spells/remove-service" "$service_name"
expect_exit_code 0
expect_not_in_output "does not exist" "$RUN_STDOUT"
expect_eq "no" "$( [ -f "$tmp_dir/systemctl/${service_name}.service.active" ] && echo yes || echo no )" "Active marker should be removed after stop"

rm -f "$service_file"

assert_all_expectations_met
