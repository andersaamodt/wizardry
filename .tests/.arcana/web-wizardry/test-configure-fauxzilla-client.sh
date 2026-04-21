#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_configure_fauxzilla_client_help() {
  run_spell "spells/.arcana/web-wizardry/configure-fauxzilla-client" --help
  assert_success && assert_output_contains "identity.sync.tokenserver.uri"
}

test_configure_fauxzilla_client_configures_default_profile() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  firefox_root="$tmp/firefox"
  profile_dir="$firefox_root/Profiles/abc123.default-release"
  mkdir -p "$profile_dir"
  cat >"$firefox_root/profiles.ini" <<'EOF'
[Install123]
Default=Profiles/abc123.default-release

[Profile0]
Name=default-release
IsRelative=1
Path=Profiles/abc123.default-release
Default=1
EOF

  FAUXZILLA_FIREFOX_ROOT="$firefox_root" \
    HQ_HOST="example.test" \
    run_spell "spells/.arcana/web-wizardry/configure-fauxzilla-client" --non-interactive
  assert_success || return 1
  assert_output_contains "configured=yes" || return 1
  assert_output_contains "tokenserver_uri=https://new.example.test/token/1.0/sync/1.5" || return 1

  user_js="$profile_dir/user.js"
  [ -f "$user_js" ] || {
    TEST_FAILURE_REASON="expected user.js to be created"
    return 1
  }
  grep -F 'user_pref("identity.sync.tokenserver.uri", "https://new.example.test/token/1.0/sync/1.5");' "$user_js" >/dev/null 2>&1 || {
    TEST_FAILURE_REASON="expected Fauxzilla tokenserver pref in $user_js"
    return 1
  }
}

test_configure_fauxzilla_client_check_reports_configured_profile() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  firefox_root="$tmp/firefox"
  profile_dir="$firefox_root/Profiles/abc123.default-release"
  mkdir -p "$profile_dir"
  cat >"$firefox_root/profiles.ini" <<'EOF'
[Profile0]
Name=default-release
IsRelative=1
Path=Profiles/abc123.default-release
Default=1
EOF

  FAUXZILLA_FIREFOX_ROOT="$firefox_root" \
    run_spell "spells/.arcana/web-wizardry/configure-fauxzilla-client" \
      --tokenserver-uri https://sync.example.test/token/1.0/sync/1.5 \
      --non-interactive
  assert_success || return 1

  FAUXZILLA_FIREFOX_ROOT="$firefox_root" \
    run_spell "spells/.arcana/web-wizardry/configure-fauxzilla-client" \
      --tokenserver-uri https://sync.example.test/token/1.0/sync/1.5 \
      --check \
      --non-interactive
  assert_success || return 1
  assert_output_contains "status=ok" || return 1
  assert_output_contains "already points at Fauxzilla" || return 1
}

test_configure_fauxzilla_client_preserves_env_after_bad_config() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  bad_config="$tmp/fauxzilla.conf"
  cat >"$bad_config" <<'EOF'
FAUXZILLA_PUBLIC_SCHEME=https
EOF

  FAUXZILLA_DOMAIN="sync.example.test" \
    run_spell "spells/.arcana/web-wizardry/configure-fauxzilla-client" \
      --config "$bad_config" \
      --print-uri
  assert_success || return 1
  assert_output_contains "https://sync.example.test/token/1.0/sync/1.5" || return 1
}

run_test_case "configure-fauxzilla-client shows help" test_configure_fauxzilla_client_help
run_test_case "configure-fauxzilla-client configures default Firefox profile" test_configure_fauxzilla_client_configures_default_profile
run_test_case "configure-fauxzilla-client check reports configured profile" test_configure_fauxzilla_client_check_reports_configured_profile
run_test_case "configure-fauxzilla-client preserves env fallback after incomplete config" test_configure_fauxzilla_client_preserves_env_after_bad_config
finish_tests
