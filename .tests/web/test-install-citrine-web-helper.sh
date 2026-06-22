#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/web/install-citrine-web-helper --help
  assert_success
  assert_output_contains "Usage: install-citrine-web-helper"
}

test_installs_for_site_static_layout() {
  tmp_root=$(temp-dir citrine-site)
  tmp_source=$(temp-dir citrine-source)
  mkdir -p "$tmp_root/site/static" "$tmp_source"
  printf '%s\n' '/* citrine test */' >"$tmp_source/citrine-nostr-web.js"

  CITRINE_NOSTR_WEB_SOURCE="$tmp_source/citrine-nostr-web.js" run_spell spells/web/install-citrine-web-helper "$tmp_root"
  assert_success
  [ -f "$tmp_root/site/static/vendor/citrine-nostr-web.js" ]
  assert_file_contains "$tmp_root/site/static/vendor/citrine-nostr-web.js" 'citrine test'

  rm -rf "$tmp_root" "$tmp_source"
}

test_installs_for_app_assets_layout() {
  tmp_root=$(temp-dir citrine-app)
  tmp_source=$(temp-dir citrine-source)
  mkdir -p "$tmp_root/app" "$tmp_source"
  printf '%s\n' "var APP_VERSION = 'v1.2.3';" >"$tmp_root/app/script.js"
  printf '%s\n' '/* citrine app test */' >"$tmp_source/citrine-nostr-web.js"

  CITRINE_NOSTR_WEB_SOURCE="$tmp_source/citrine-nostr-web.js" run_spell spells/web/install-citrine-web-helper "$tmp_root"
  assert_success
  [ -f "$tmp_root/app/assets/vendor/citrine-nostr-web.js" ]
  assert_file_contains "$tmp_root/app/assets/vendor/citrine-nostr-web.js" 'citrine app test'

  rm -rf "$tmp_root" "$tmp_source"
}

test_fails_for_unknown_layout() {
  tmp_root=$(temp-dir citrine-unknown)
  tmp_source=$(temp-dir citrine-source)
  printf '%s\n' '/* citrine test */' >"$tmp_source/citrine-nostr-web.js"

  CITRINE_NOSTR_WEB_SOURCE="$tmp_source/citrine-nostr-web.js" run_spell spells/web/install-citrine-web-helper "$tmp_root"
  assert_failure
  assert_output_contains "could not detect a supported web project layout"

  rm -rf "$tmp_root" "$tmp_source"
}

run_test_case "install-citrine-web-helper shows help" test_help
run_test_case "install-citrine-web-helper installs for site/static layout" test_installs_for_site_static_layout
run_test_case "install-citrine-web-helper installs for app/assets layout" test_installs_for_app_assets_layout
run_test_case "install-citrine-web-helper rejects unknown layouts" test_fails_for_unknown_layout

finish_tests
