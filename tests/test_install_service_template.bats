#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  system_stubs=$(wizardry_install_systemd_stubs)
  ask_text_stub="$BATS_TEST_TMPDIR/ask_text_stub"
  cat <<'STUB' >"$ask_text_stub"
#!/usr/bin/env bash
set -euo pipefail
response_file="${ASK_TEXT_STUB_FILE:-}"
if [ -n "$response_file" ] && [ -s "$response_file" ]; then
  response=$(head -n1 "$response_file")
  if [ "$(wc -l <"$response_file")" -gt 1 ]; then
    tail -n +2 "$response_file" >"$response_file.tmp"
    mv "$response_file.tmp" "$response_file"
  else
    : >"$response_file"
  fi
  printf '%s\n' "$response"
  exit 0
fi
printf '%s\n' "${ASK_TEXT_STUB_RESPONSE:-}"
STUB
  chmod +x "$ask_text_stub"
  tmp_dir="$BATS_TEST_TMPDIR/service"
  mkdir -p "$tmp_dir"
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
}

teardown() {
  rm -f "$service_path"
  PATH=$ORIGINAL_PATH
  default_teardown
}

@test 'install-service-template overwrites file even when overwrite declined' {
  printf 'existing service' | "$system_stubs/sudo" tee "$service_path" >/dev/null

  ASK_YN_STUB_RESPONSE=N \
    INSTALL_SERVICE_TEMPLATE_ASK_YN="$system_stubs/ask_yn" \
    PATH="$(wizardry_join_paths "$system_stubs" "$ORIGINAL_PATH")" \
    run_spell 'spells/install-service-template' "$template"
  assert_failure
  run cat "$service_path"
  assert_success
  assert_output 'existing service'
}

@test 'install-service-template fills template placeholders and reloads systemd' {
  rm -f "$service_path"
  placeholder_input="$BATS_TEST_TMPDIR/service_placeholders"
  printf 'Mystic Service\n7777\n' >"$placeholder_input"

  SYSTEMCTL_STATE_DIR="$tmp_dir" \
    INSTALL_SERVICE_TEMPLATE_ASK_TEXT="$ask_text_stub" \
    ASK_TEXT_STUB_FILE="$placeholder_input" \
    PATH="$(wizardry_join_paths "$system_stubs" "$ORIGINAL_PATH")" \
    run_spell 'spells/install-service-template' "$template" EXECUTABLE=magic
  assert_success
  assert_output --partial 'Service installed'

  run grep '^Description=' "$service_path"
  assert_success
  assert_output 'Description=Mystic Service'

  run grep '^Environment=' "$service_path"
  assert_success
  assert_output 'Environment=PORT=7777'

  run grep '^ExecStart' "$service_path"
  assert_success
  assert_output --partial 'magic'

  [ -f "$tmp_dir/systemctl/daemon-reload" ]
}

