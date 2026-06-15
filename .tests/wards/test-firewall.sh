#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_spell spells/wards/firewall --help
  assert_success
  assert_output_contains "Usage: firewall"
}

delegates_to_platform_backend() {
  tmpdir=$(make_tempdir)
  backend_name=firewall-darwin

  cat >"$tmpdir/$backend_name" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${FIREWALL_BACKEND_LOG:?}"
exit 0
SH
  chmod +x "$tmpdir/$backend_name"

  FIREWALL_BACKEND_LOG="$tmpdir/backend.log" run_cmd env PATH="$tmpdir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" FIREWALL_BACKEND_LOG="$tmpdir/backend.log" \
    "$ROOT_DIR/spells/wards/firewall" --allow-localhost --allow 127.0.0.1:5555 -- /usr/bin/true

  assert_success || return 1
  assert_path_exists "$tmpdir/backend.log" || return 1
  assert_file_contains "$tmpdir/backend.log" "--allow-localhost"
  assert_file_contains "$tmpdir/backend.log" "127.0.0.1:5555"
}

finds_installed_backend_without_path_entry() {
  tmpdir=$(make_tempdir)
  backend_name=firewall-darwin
  home_dir="$tmpdir/home"
  bin_dir="$home_dir/.local/bin"
  mkdir -p "$bin_dir"

  cat >"$bin_dir/$backend_name" <<'SH'
#!/bin/sh
printf '%s\n' "$@" >"${FIREWALL_BACKEND_LOG:?}"
exit 0
SH
  chmod +x "$bin_dir/$backend_name"

  FIREWALL_BACKEND_LOG="$tmpdir/backend.log" run_cmd env HOME="$home_dir" PATH="$WIZARDRY_IMPS_PATH:/bin:/usr/bin" FIREWALL_BACKEND_LOG="$tmpdir/backend.log" \
    "$ROOT_DIR/spells/wards/firewall" --allow-localhost -- /usr/bin/true

  assert_success || return 1
  assert_path_exists "$tmpdir/backend.log" || return 1
  assert_file_contains "$tmpdir/backend.log" "--allow-localhost"
}

run_test_case "firewall shows help" shows_help
run_test_case "firewall delegates to platform backend" delegates_to_platform_backend
run_test_case "firewall finds installed backend without PATH entry" finds_installed_backend_without_path_entry

finish_tests
