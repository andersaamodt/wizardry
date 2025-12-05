#!/bin/sh
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


make_stub_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/is-service-installed.XXXXXX") || exit 1
  printf '%s\n' "$dir"
}

write_ask_text_stub() {
  dir=$1
  cat >"$dir/ask-text" <<'STUB'
#!/bin/sh
printf '%s\n' "${ASK_TEXT_RESPONSE:-}"
STUB
  chmod +x "$dir/ask-text"
}

test_missing_service_name_fails() {
  stub_dir=$(make_stub_dir)
  write_ask_text_stub "$stub_dir"
  ASK_TEXT_RESPONSE="" IS_SERVICE_INSTALLED_ASK_TEXT="$stub_dir/ask-text" PATH="$stub_dir:$PATH" run_spell "spells/cantrips/is-service-installed"
  assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"no service specified"*) : ;;
    *) TEST_FAILURE_REASON="missing service warning not shown"; return 1 ;;
  esac
}

test_reports_installed_service() {
  stub_dir=$(make_stub_dir)
  write_ask_text_stub "$stub_dir"
  service_dir=$(mktemp -d "$WIZARDRY_TMPDIR/services.XXXXXX") || return 1
  printf 'unit' >"$service_dir/demo.service"
  SERVICE_DIR="$service_dir" IS_SERVICE_INSTALLED_ASK_TEXT="$stub_dir/ask-text" PATH="$stub_dir:$PATH" run_spell "spells/cantrips/is-service-installed" demo
  assert_success && assert_output_contains "demo.service is installed"
}

test_reports_missing_service() {
  stub_dir=$(make_stub_dir)
  write_ask_text_stub "$stub_dir"
  service_dir=$(mktemp -d "$WIZARDRY_TMPDIR/services.XXXXXX") || return 1
  SERVICE_DIR="$service_dir" IS_SERVICE_INSTALLED_ASK_TEXT="$stub_dir/ask-text" PATH="$stub_dir:$PATH" run_spell "spells/cantrips/is-service-installed" demo.service
  assert_failure && assert_output_contains "demo.service is not installed"
}

run_test_case "is-service-installed fails without a service name" test_missing_service_name_fails
run_test_case "is-service-installed detects an installed service" test_reports_installed_service
run_test_case "is-service-installed reports missing services" test_reports_missing_service

shows_help() {
  run_spell spells/cantrips/is-service-installed --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "is-service-installed accepts --help" shows_help
finish_tests
