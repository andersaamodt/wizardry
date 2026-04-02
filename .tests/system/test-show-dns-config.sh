#!/bin/sh
# Behavioral cases:
# - show-dns-config shows usage
# - show-dns-config prefers scutil --dns
# - show-dns-config falls back to resolvectl status

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/system/show-dns-config" --help
  assert_success || return 1
  assert_output_contains "Usage: show-dns-config" || return 1
}

test_prefers_scutil() {
  tmp=$(make_tempdir)
  cat >"$tmp/scutil" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >"$SCUTIL_LOG"
printf '%s\n' "scutil-ran"
SH
  chmod +x "$tmp/scutil"

  run_cmd env PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips:/bin:/usr/bin" SCUTIL_LOG="$tmp/log" \
    "$ROOT_DIR/spells/system/show-dns-config"
  assert_success || return 1
  assert_output_contains "scutil-ran" || return 1
  assert_file_contains "$tmp/log" "--dns"
}

test_falls_back_to_resolvectl() {
  tmp=$(make_tempdir)
  cat >"$tmp/resolvectl" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >"$RESOLVE_LOG"
printf '%s\n' "resolvectl-ran"
SH
  chmod +x "$tmp/resolvectl"

  run_cmd env PATH="$tmp:$WIZARDRY_IMPS_PATH:$ROOT_DIR/spells/cantrips" RESOLVE_LOG="$tmp/log" \
    "$ROOT_DIR/spells/system/show-dns-config"
  assert_success || return 1
  assert_output_contains "resolvectl-ran" || return 1
  assert_file_contains "$tmp/log" "status"
}

run_test_case "show-dns-config shows usage" test_help
run_test_case "show-dns-config prefers scutil" test_prefers_scutil
run_test_case "show-dns-config falls back to resolvectl" test_falls_back_to_resolvectl

finish_tests
