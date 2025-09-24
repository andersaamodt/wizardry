#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"
source "$(dirname "$0")/lib/stub_helpers.sh"

BASE_PATH=$PATH
system_stubs=$(wizardry_install_systemd_stubs)

tmp_dir=$(make_temp_dir)
template="$tmp_dir/example.service"
cat <<'SERVICE' >"$template"
[Unit]
Description=$DESCRIPTION

[Service]
ExecStart=/usr/bin/$EXECUTABLE
Environment=PORT=$PORT
SERVICE

service_name=$(basename "$template")
service_path="/etc/systemd/system/$service_name"
rm -f "$service_path"

printf 'existing service' | "$system_stubs/sudo" tee "$service_path" >/dev/null
ASK_YN_STUB_RESPONSE=N RUN_PATH_OVERRIDE="$(wizardry_join_paths "$system_stubs" "$BASE_PATH")" \
  run_script "spells/install-service-template" "$template"
expect_exit_code 1
expect_eq "existing service" "$(cat "$service_path")" "Declining overwrite should preserve the original service file"
rm -f "$service_path"

SYSTEMCTL_STATE_DIR="$tmp_dir" DESCRIPTION="Mystic Service" PORT=7777 \
  RUN_PATH_OVERRIDE="$(wizardry_join_paths "$system_stubs" "$BASE_PATH")" \
  run_script "spells/install-service-template" "$template" EXECUTABLE=magic
expect_exit_code 0
expect_in_output "Service installed" "$RUN_STDOUT"
expect_eq "Mystic Service" "$(grep '^Description=' "$service_path" | cut -d'=' -f2)" "Template should substitute DESCRIPTION"
expect_eq "Environment=PORT=7777" "$(grep '^Environment=' "$service_path")" "Missing vars should be filled from environment"
expect_eq "magic" "$(grep '^ExecStart' "$service_path" | awk -F/ '{print $NF}')" "Key=value arguments should replace placeholders"
daemon_reload_marker=$([ -f "$tmp_dir/systemctl/daemon-reload" ] && echo yes || echo no)
expect_eq yes "$daemon_reload_marker" "systemctl daemon-reload should be invoked"

rm -f "$service_path"

assert_all_expectations_met
