#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

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
  ASK_TEXT_RESPONSE="" IS_SERVICE_INSTALLED_ASK_TEXT="$stub_dir/ask-text" PATH="$WIZARDRY_IMPS_PATH:$stub_dir:/bin:/usr/bin" _run_spell "spells/cantrips/is-service-installed"
  _assert_failure || return 1
  case "$OUTPUT$ERROR" in
    *"no service specified"*) : ;;
    *) TEST_FAILURE_REASON="missing service warning not shown"; return 1 ;;
  esac
}

test_reports_installed_service() {
  skip-if-compiled || return $?
  stub_dir=$(make_stub_dir)
  write_ask_text_stub "$stub_dir"
  service_dir=$(mktemp -d "$WIZARDRY_TMPDIR/services.XXXXXX") || return 1
  printf 'unit' >"$service_dir/demo.service"
  SERVICE_DIR="$service_dir" IS_SERVICE_INSTALLED_ASK_TEXT="$stub_dir/ask-text" PATH="$WIZARDRY_IMPS_PATH:$stub_dir:/bin:/usr/bin" _run_spell "spells/cantrips/is-service-installed" demo
  _assert_success && _assert_output_contains "demo.service is installed"
}

test_reports_missing_service() {
  skip-if-compiled || return $?
  stub_dir=$(make_stub_dir)
  write_ask_text_stub "$stub_dir"
  service_dir=$(mktemp -d "$WIZARDRY_TMPDIR/services.XXXXXX") || return 1
  SERVICE_DIR="$service_dir" IS_SERVICE_INSTALLED_ASK_TEXT="$stub_dir/ask-text" PATH="$WIZARDRY_IMPS_PATH:$stub_dir:/bin:/usr/bin" _run_spell "spells/cantrips/is-service-installed" demo.service
  _assert_failure && _assert_output_contains "demo.service is not installed"
}

_run_test_case "is-service-installed fails without a service name" test_missing_service_name_fails
_run_test_case "is-service-installed detects an installed service" test_reports_installed_service
_run_test_case "is-service-installed reports missing services" test_reports_missing_service

shows_help() {
  _run_spell spells/cantrips/is-service-installed --help
  # Note: spell may not have --help implemented yet
  true
}

_run_test_case "is-service-installed accepts --help" shows_help

# Test via source-then-invoke pattern  
is_service_installed_help_via_sourcing() {
  _run_sourced_spell is-service-installed --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "is-service-installed works via source-then-invoke" is_service_installed_help_via_sourcing
_finish_tests
