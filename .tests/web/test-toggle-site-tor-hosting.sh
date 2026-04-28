#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/web/toggle-site-tor-hosting" ]
}

run_test_case "web/toggle-site-tor-hosting is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/web/toggle-site-tor-hosting" ]
}

run_test_case "web/toggle-site-tor-hosting has content" spell_has_content

shows_help() {
  run_spell spells/web/toggle-site-tor-hosting --help
  true
}

run_test_case "toggle-site-tor-hosting shows help" shows_help

rejects_path_shaped_site_name() {
  tmpdir=$(temp-dir toggle-site-tor-hosting-path-test)
  web_root="$tmpdir/sites"
  escape_dir="$tmpdir/escape"
  mkdir -p "$web_root" "$escape_dir"
  printf 'site-name=escape\nport=8080\n' > "$escape_dir/site.conf"

  WIZARDRY_SITES_DIR="$web_root" run_spell spells/web/toggle-site-tor-hosting ../escape
  assert_failure || return 1
  assert_error_contains "invalid site name" || return 1

  rm -rf "$tmpdir"
}

run_test_case "toggle-site-tor-hosting rejects path-shaped site names" \
  rejects_path_shaped_site_name
finish_tests
