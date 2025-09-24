#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
  ORIGINAL_PATH=$PATH
  system_stubs=$(wizardry_install_systemd_stubs)
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

  ASK_YN_STUB_RESPONSE=N PATH="$(wizardry_join_paths "$system_stubs" "$ORIGINAL_PATH")" \
    run_spell 'spells/install-service-template' "$template"
  assert_failure
  run cat "$service_path"
  assert_success
  assert_output 'existing service'
}

@test 'install-service-template fills template placeholders and reloads systemd' {
  rm -f "$service_path"
  SYSTEMCTL_STATE_DIR="$tmp_dir" DESCRIPTION='Mystic Service' PORT=7777 \
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

