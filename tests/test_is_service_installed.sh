#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"
source "$(dirname "$0")/lib/stub_helpers.sh"

BASE_PATH=$PATH
system_stubs=$(wizardry_install_systemd_stubs)

service_name="wizardry-test-$$"
service_file="/etc/systemd/system/$service_name.service"
rm -f "$service_file"

RUN_PATH_OVERRIDE="$BASE_PATH" run_script "spells/is-service-installed" "$service_name"
expect_exit_code 1

RUN_PATH_OVERRIDE="$(wizardry_join_paths "$system_stubs" "$BASE_PATH")" run_script "spells/is-service-installed" "$service_name"
expect_exit_code 1

printf '[Unit]\nDescription=Wizardry test service\n' | "$system_stubs/sudo" tee "$service_file" >/dev/null
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$system_stubs" "$BASE_PATH")" run_script "spells/is-service-installed" "$service_name"
expect_exit_code 0

RUN_PATH_OVERRIDE="$(wizardry_join_paths "$system_stubs" "$BASE_PATH")" run_script "spells/is-service-installed" "$service_name.service"
expect_exit_code 0

rm -f "$service_file"

assert_all_expectations_met
