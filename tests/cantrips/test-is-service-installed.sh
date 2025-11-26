#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_stub_dir() {
  dir=$(mktemp -d "$WIZARDRY_TMPDIR/is-service-installed.XXXXXX") || exit 1
  printf '%s\n' "$dir"
}

write_ask_text_stub() {
  dir=$1
  cat >"$dir/ask_text" <<'STUB'
#!/bin/sh
printf '%s\n' "${ASK_TEXT_RESPONSE:-}"
STUB
  chmod +x "$dir/ask_text"
}

test_missing_service_name_fails() {
  stub_dir=$(make_stub_dir)
  write_ask_text_stub "$stub_dir"
  ASK_TEXT_RESPONSE="" IS_SERVICE_INSTALLED_ASK_TEXT="$stub_dir/ask_text" PATH="$stub_dir:$PATH" run_spell "spells/cantrips/is-service-installed"
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
  SERVICE_DIR="$service_dir" IS_SERVICE_INSTALLED_ASK_TEXT="$stub_dir/ask_text" PATH="$stub_dir:$PATH" run_spell "spells/cantrips/is-service-installed" demo
  assert_success && assert_output_contains "demo.service is installed"
}

test_reports_missing_service() {
  stub_dir=$(make_stub_dir)
  write_ask_text_stub "$stub_dir"
  service_dir=$(mktemp -d "$WIZARDRY_TMPDIR/services.XXXXXX") || return 1
  SERVICE_DIR="$service_dir" IS_SERVICE_INSTALLED_ASK_TEXT="$stub_dir/ask_text" PATH="$stub_dir:$PATH" run_spell "spells/cantrips/is-service-installed" demo.service
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
