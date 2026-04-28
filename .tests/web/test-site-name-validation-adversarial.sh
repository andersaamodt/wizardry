#!/bin/sh
# Adversarial site-name validation coverage for web maintenance helpers.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_web_site_helpers_reject_path_shaped_names() {
  skip-if-compiled || return $?

  tmpdir=$(temp-dir web-wizardry-site-name-test)
  web_root="$tmpdir/sites"
  escape_dir="$tmpdir/escape"
  mkdir -p "$web_root" "$escape_dir/nginx"
  cat > "$escape_dir/site.conf" <<EOF
site-name=escape
site-user=$(id -un)
https=true
domain=example.com
port=8080
EOF

  for spell in \
    check-https-status \
    disable-site-daemon \
    enable-site-daemon \
    https \
    is-site-daemon-enabled \
    renew-https \
    restart-site \
    run-site-daemon \
    serve-site \
    setup-https \
    site-menu \
    site-status; do
    WEB_WIZARDRY_ROOT="$web_root" WIZARDRY_SITES_DIR="$web_root" \
      run_spell "spells/web/$spell" ../escape
    assert_failure || return 1
    if ! assert_error_contains "invalid site name"; then
      TEST_FAILURE_REASON="$spell did not reject a path-shaped site name"
      return 1
    fi
  done

  rm -rf "$tmpdir"
}

run_test_case "web site helpers reject path-shaped names" \
  test_web_site_helpers_reject_path_shaped_names

finish_tests
