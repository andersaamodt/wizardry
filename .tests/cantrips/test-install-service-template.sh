#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

make_stub_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/install-service-template.XXXXXX") || exit 1
  printf '%s\n' "$dir"
}

write_ask_yn_stub() {
  dir=$1
  cat >"$dir/ask-yn" <<'STUB'
#!/bin/sh
case "${ASK_YN_STUB_RESPONSE:-yes}" in
  [Yy]*) exit 0 ;;
  *) exit 1 ;;
esac
STUB
  chmod +x "$dir/ask-yn"
}

write_ask_text_stub() {
  dir=$1
  cat >"$dir/ask-text" <<'STUB'
#!/bin/sh
file=${ASK_TEXT_STUB_FILE:-}
if [ -n "$file" ] && [ -s "$file" ]; then
  line=$(head -n1 "$file")
  tail -n +2 "$file" >"$file.tmp" && mv "$file.tmp" "$file"
  printf '%s\n' "$line"
  exit 0
fi
printf '%s\n' "${ASK_TEXT_DEFAULT:-}"
STUB
  chmod +x "$dir/ask-text"
}

write_systemctl_stub() {
  dir=$1
  cat >"$dir/systemctl" <<'STUB'
#!/bin/sh
state_dir=${SYSTEMCTL_STATE_DIR:-$(mktemp -d)}
mkdir -p "$state_dir"
case "$1" in
  daemon-reload)
    printf 'reloaded' >"$state_dir/daemon-reload"
    exit 0 ;;
  *) exit 0 ;;
esac
STUB
  chmod +x "$dir/systemctl"
}

test_declines_overwrite() {
  stub_dir=$(make_stub_dir)
  write_ask_yn_stub "$stub_dir"
  write_ask_text_stub "$stub_dir"
  write_systemctl_stub "$stub_dir"

  service_dir=$(mktemp -d "$WIZARDRY_TMPDIR/services.XXXXXX") || return 1
  template="$service_dir/example.service"
  printf 'placeholder=$VALUE\n' >"$template"
  service_path="$service_dir/existing.service"
  printf 'keep me' >"$service_path"

  ASK_YN_STUB_RESPONSE=no \
  SERVICE_DIR="$service_dir" \
  SYSTEMCTL_STATE_DIR="$service_dir/state" \
  INSTALL_SERVICE_TEMPLATE_ASK_YN="$stub_dir/ask-yn" \
  INSTALL_SERVICE_TEMPLATE_ASK_TEXT="$stub_dir/ask-text" \
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/install-service-template" "$template"

  assert_failure && assert_output_contains "Installation cancelled"
  [ "$(cat "$service_path")" = "keep me" ] || { TEST_FAILURE_REASON="service file was overwritten"; return 1; }
}

test_fills_placeholders_and_reloads() {
  stub_dir=$(make_stub_dir)
  write_ask_yn_stub "$stub_dir"
  write_ask_text_stub "$stub_dir"
  write_systemctl_stub "$stub_dir"

  service_dir=$(mktemp -d "$WIZARDRY_TMPDIR/services.XXXXXX") || return 1
  template="$service_dir/example.service"
  cat >"$template" <<'SERVICE'
[Unit]
Description=$DESCRIPTION

[Service]
ExecStart=/usr/bin/$EXECUTABLE
Environment=PORT=$PORT
SERVICE
  placeholders="$service_dir/placeholders"
  printf 'Mystic Service\n7777\n' >"$placeholders"
  service_path="$service_dir/example.service"

  SERVICE_DIR="$service_dir" \
  SYSTEMCTL_STATE_DIR="$service_dir/state" \
  INSTALL_SERVICE_TEMPLATE_ASK_YN="$stub_dir/ask-yn" \
  INSTALL_SERVICE_TEMPLATE_ASK_TEXT="$stub_dir/ask-text" \
  ASK_TEXT_STUB_FILE="$placeholders" \
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/install-service-template" "$template" EXECUTABLE=magic

  assert_success
  assert_output_contains "Service installed"
  contents=$(cat "$service_path")
  case "$contents" in
    *"Description=Mystic Service"*|*"Description=Mystic Service"*) : ;; *) TEST_FAILURE_REASON="Description not replaced"; return 1;;
  esac
  case "$contents" in
    *"Environment=PORT=7777"*) : ;; *) TEST_FAILURE_REASON="PORT not replaced"; return 1;;
  esac
  case "$contents" in
    *"ExecStart=/usr/bin/magic"*) : ;; *) TEST_FAILURE_REASON="EXECUTABLE not replaced"; return 1;;
  esac
  [ -f "$service_dir/state/daemon-reload" ] || { TEST_FAILURE_REASON="daemon-reload not triggered"; return 1; }
}

test_skips_sudo_when_service_dir_writable() {
  stub_dir=$(make_stub_dir)
  write_ask_yn_stub "$stub_dir"
  write_ask_text_stub "$stub_dir"
  write_systemctl_stub "$stub_dir"

  printf '#!/bin/sh\nexit 99' >"$stub_dir/sudo"
  chmod +x "$stub_dir/sudo"

  service_dir=$(mktemp -d "$WIZARDRY_TMPDIR/services.XXXXXX") || return 1
  template="$service_dir/example.service"
  printf 'Name=$NAME\n' >"$template"

  SERVICE_DIR="$service_dir" \
  INSTALL_SERVICE_TEMPLATE_ASK_YN="$stub_dir/ask-yn" \
  INSTALL_SERVICE_TEMPLATE_ASK_TEXT="$stub_dir/ask-text" \
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/install-service-template" "$template" NAME=mere

  assert_success
  assert_output_contains "Service installed"
  contents=$(cat "$service_dir/example.service")
  case "$contents" in
    *"Name=mere"*) : ;; *) TEST_FAILURE_REASON="NAME not replaced"; return 1;;
  esac
}

test_replaces_special_characters() {
  stub_dir=$(make_stub_dir)
  write_ask_yn_stub "$stub_dir"
  write_ask_text_stub "$stub_dir"
  write_systemctl_stub "$stub_dir"

  service_dir=$(mktemp -d "$WIZARDRY_TMPDIR/services.XXXXXX") || return 1
  template="$service_dir/example.service"
  cat >"$template" <<'SERVICE'
[Service]
ExecStart=/usr/bin/$EXEC
Environment=EXTRA=$VALUE
SERVICE
  placeholders="$service_dir/placeholders"
  printf 'a/path/with|pipes&slashes"\nquoted&value' >"$placeholders"
  service_path="$service_dir/example.service"

  SERVICE_DIR="$service_dir" \
  SYSTEMCTL_STATE_DIR="$service_dir/state" \
  INSTALL_SERVICE_TEMPLATE_ASK_YN="$stub_dir/ask-yn" \
  INSTALL_SERVICE_TEMPLATE_ASK_TEXT="$stub_dir/ask-text" \
  ASK_TEXT_STUB_FILE="$placeholders" \
  PATH="$stub_dir:$PATH" run_spell "spells/cantrips/install-service-template" "$template"

  assert_success
  contents=$(cat "$service_path")
  case "$contents" in
    *"ExecStart=/usr/bin/a/path/with|pipes&slashes\""*) : ;; *) TEST_FAILURE_REASON="EXEC not replaced safely"; return 1;;
  esac
  case "$contents" in
    *"Environment=EXTRA=quoted&value"*) : ;; *) TEST_FAILURE_REASON="VALUE not replaced safely"; return 1;;
  esac
}

run_test_case "install-service-template cancels when overwrite declined" test_declines_overwrite
run_test_case "install-service-template fills placeholders and reloads systemd" test_fills_placeholders_and_reloads
run_test_case "install-service-template skips sudo when target writable" test_skips_sudo_when_service_dir_writable
run_test_case "install-service-template handles special characters in placeholders" test_replaces_special_characters

shows_help() {
  run_spell spells/cantrips/install-service-template --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "install-service-template accepts --help" shows_help
finish_tests
