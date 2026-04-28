#!/bin/sh
# Test disable-https spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_disable_https_help() {
  run_spell spells/web/disable-https --help
  assert_success
  assert_output_contains "Usage:"
}

test_disable_https_rejects_path_shaped_site_name() {
  skip-if-compiled || return $?

  tmpdir=$(make_tempdir)
  web_root="$tmpdir/sites"
  escape_dir="$tmpdir/escape"
  cert_file="$tmpdir/cert.pem"
  mkdir -p "$web_root" "$escape_dir"
  : > "$cert_file"
  cat > "$escape_dir/site.conf" <<EOF
site-user=$(id -un)
https=true
cert-path=$cert_file
domain=localhost
port=8080
EOF

  WEB_WIZARDRY_ROOT="$web_root" run_spell spells/web/disable-https ../escape

  assert_failure || return 1
  assert_error_contains "invalid site name" || return 1
  if ! grep -q '^https=true$' "$escape_dir/site.conf"; then
    TEST_FAILURE_REASON="disable-https modified config outside WEB_WIZARDRY_ROOT"
    return 1
  fi

  rm -rf "$tmpdir"
}

run_test_case "disable-https --help" test_disable_https_help
run_test_case "disable-https rejects path-shaped site names" \
  test_disable_https_rejects_path_shaped_site_name

finish_tests
