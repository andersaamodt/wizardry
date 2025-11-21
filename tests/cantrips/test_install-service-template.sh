#!/bin/sh
. "$(CDPATH= cd "$(dirname "$0")" && pwd)/../lib/test_common.sh"

make_stub_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/install-service-template.XXXXXX") || exit 1
  printf '%s\n' "$dir"
}

write_ask_yn_stub() {
  dir=$1
  cat >"$dir/ask_yn" <<'STUB'
#!/bin/sh
case "${ASK_YN_STUB_RESPONSE:-yes}" in
  [Yy]*) exit 0 ;;
  *) exit 1 ;;
esac
STUB
  chmod +x "$dir/ask_yn"
}

write_ask_text_stub() {
  dir=$1
  cat >"$dir/ask_text" <<'STUB'
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
  chmod +x "$dir/ask_text"
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
  INSTALL_SERVICE_TEMPLATE_ASK_YN="$stub_dir/ask_yn" \
  INSTALL_SERVICE_TEMPLATE_ASK_TEXT="$stub_dir/ask_text" \
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
  INSTALL_SERVICE_TEMPLATE_ASK_YN="$stub_dir/ask_yn" \
  INSTALL_SERVICE_TEMPLATE_ASK_TEXT="$stub_dir/ask_text" \
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

run_test_case "install-service-template cancels when overwrite declined" test_declines_overwrite
run_test_case "install-service-template fills placeholders and reloads systemd" test_fills_placeholders_and_reloads

finish_tests
