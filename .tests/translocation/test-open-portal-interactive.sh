#!/bin/sh
# Behavioral cases:
# - open-portal-interactive shows usage
# - open-portal-interactive opens a direct portal from prompts
# - open-portal-interactive opens a Tor portal when requested
# - open-portal-interactive cancels when required fields are blank

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/translocation/open-portal-interactive" --help
  assert_success || return 1
  assert_output_contains "Usage: open-portal-interactive" || return 1
}

test_direct_portal() {
  tmp=$(make_tempdir)
  cat >"$tmp/open-portal" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >"$PORTAL_LOG"
SH
  chmod +x "$tmp/open-portal"

  run_cmd env PATH="$tmp:$PATH" PORTAL_LOG="$tmp/log" ASK_CANTRIP_INPUT=stdin \
    sh -c "printf 'n\\nhero\\nexample.com\\n~/shared\\n' | \"$ROOT_DIR/spells/translocation/open-portal-interactive\""
  assert_success || return 1
  assert_file_contains "$tmp/log" "hero@example.com:~/shared"
}

test_tor_portal() {
  tmp=$(make_tempdir)
  cat >"$tmp/open-portal" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >"$PORTAL_LOG"
SH
  chmod +x "$tmp/open-portal"

  run_cmd env PATH="$tmp:$PATH" PORTAL_LOG="$tmp/log" ASK_CANTRIP_INPUT=stdin \
    sh -c "printf 'y\\nhero\\nhidden.onion\\n~/world\\n' | \"$ROOT_DIR/spells/translocation/open-portal-interactive\""
  assert_success || return 1
  assert_file_contains "$tmp/log" "--tor hero@hidden.onion:~/world"
}

test_blank_fields_cancel() {
  tmp=$(make_tempdir)
  cat >"$tmp/open-portal" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >"$PORTAL_LOG"
SH
  chmod +x "$tmp/open-portal"

  run_cmd env PATH="$tmp:$PATH" PORTAL_LOG="$tmp/log" ASK_CANTRIP_INPUT=stdin \
    sh -c "printf 'n\\n\\nexample.com\\n~/shared\\n' | \"$ROOT_DIR/spells/translocation/open-portal-interactive\""
  assert_success || return 1
  assert_error_contains "cancelled" || return 1
  assert_path_missing "$tmp/log"
}

run_test_case "open-portal-interactive shows usage" test_help
run_test_case "open-portal-interactive opens direct portals" test_direct_portal
run_test_case "open-portal-interactive opens Tor portals" test_tor_portal
run_test_case "open-portal-interactive cancels on blank fields" test_blank_fields_cancel

finish_tests
