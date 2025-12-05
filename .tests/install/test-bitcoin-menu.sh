#!/bin/sh
# Behavioral cases (derived from spell behavior):
# - bitcoin-menu prompts to install when bitcoin is absent
# - bitcoin-menu offers service controls when running under systemd
# - bitcoin-menu offers service installation when bitcoin is present without a service

set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


make_stub_menu() {
  tmp=$1
  cat >"$tmp/menu" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >>"$MENU_LOG"
kill -s INT "$PPID"
exit 0
SH
  chmod +x "$tmp/menu"
}

make_stub_colors() {
  tmp=$1
  cat >"$tmp/colors" <<'SH'
#!/bin/sh
BOLD=""
CYAN=""
SH
  chmod +x "$tmp/colors"
}

make_stub_exit_label() {
  tmp=$1
  cat >"$tmp/exit-label" <<'SH'
#!/bin/sh
printf '%s' "Exit"
SH
  chmod +x "$tmp/exit-label"
}

make_status_stub() {
  tmp=$1
  status=$2
  cat >"$tmp/bitcoin-status" <<SH
#!/bin/sh
echo "$status"
SH
  chmod +x "$tmp/bitcoin-status"
}

make_boolean_stub() {
  path=$1
  exit_code=$2
  cat >"$path" <<SH
#!/bin/sh
exit $exit_code
SH
  chmod +x "$path"
}

test_bitcoin_menu_prompts_install_when_missing() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  make_stub_exit_label "$tmp"
  make_status_stub "$tmp" "missing"
  make_boolean_stub "$tmp/is-bitcoin-installed" 1
  make_boolean_stub "$tmp/is-service-installed" 1
  make_boolean_stub "$tmp/is-bitcoin-running" 1

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/install/bitcoin-menu"
  assert_success
  assert_file_contains "$tmp/log" "Bitcoin: missing"
  assert_file_contains "$tmp/log" "Install Bitcoin%install-bitcoin"
}

test_bitcoin_menu_controls_running_service() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  make_stub_exit_label "$tmp"
  make_status_stub "$tmp" "ready"
  make_boolean_stub "$tmp/is-bitcoin-installed" 0
  make_boolean_stub "$tmp/is-service-installed" 0
  make_boolean_stub "$tmp/is-bitcoin-running" 0

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/install/bitcoin-menu"
  assert_success
  assert_file_contains "$tmp/log" "Stop Bitcoin Service%sudo systemctl stop bitcoin"
  assert_file_contains "$tmp/log" "Uninstall Bitcoin Service%remove-service bitcoin"
  assert_file_contains "$tmp/log" "Uninstall Bitcoin%uninstall-bitcoin"
}

test_bitcoin_menu_offers_service_install_when_missing() {
  tmp=$(make_tempdir)
  make_stub_menu "$tmp"
  make_stub_colors "$tmp"
  make_stub_exit_label "$tmp"
  make_status_stub "$tmp" "ready"
  make_boolean_stub "$tmp/is-bitcoin-installed" 0
  make_boolean_stub "$tmp/is-service-installed" 1
  make_boolean_stub "$tmp/is-bitcoin-running" 1
  cat >"$tmp/which" <<'SH'
#!/bin/sh
echo /usr/bin/bitcoind
SH
  chmod +x "$tmp/which"

  run_cmd env PATH="$tmp:$PATH" MENU_LOG="$tmp/log" "$ROOT_DIR/spells/install/bitcoin-menu"
  assert_success
  assert_file_contains "$tmp/log" "Install Bitcoin Service%install-service-template $ROOT_DIR/spells/install/bitcoin/bitcoin.service \"BITCOIND=/usr/bin/bitcoind\""
  assert_file_contains "$tmp/log" "Uninstall Bitcoin%uninstall-bitcoin"
}

run_test_case "bitcoin-menu prompts for install when missing" test_bitcoin_menu_prompts_install_when_missing
run_test_case "bitcoin-menu manages running services" test_bitcoin_menu_controls_running_service
run_test_case "bitcoin-menu installs service when absent" test_bitcoin_menu_offers_service_install_when_missing

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/install/bitcoin-menu" --help
  assert_success
  assert_output_contains "Usage: bitcoin-menu"
}

run_test_case "bitcoin-menu --help shows usage" test_shows_help

finish_tests
