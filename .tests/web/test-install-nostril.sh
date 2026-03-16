#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/web/install-nostril --help
  assert_success
  assert_output_contains "Usage: install-nostril"
}

test_success_when_tooling_already_present() {
  tmp_bin=$(temp-dir install-nostril-bin)
  cat > "$tmp_bin/nostril" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat > "$tmp_bin/nak" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp_bin/nostril" "$tmp_bin/nak"

  PATH="$tmp_bin:/usr/bin:/bin:/usr/sbin:/sbin" run_spell spells/web/install-nostril
  assert_success
  assert_output_contains "already installed"

  rm -rf "$tmp_bin"
}

test_failure_without_supported_package_manager() {
  tmp_bin=$(temp-dir install-nostril-bin)
  PATH="$tmp_bin" run_spell spells/web/install-nostril
  assert_failure
  assert_output_contains "no supported package manager"
  rm -rf "$tmp_bin"
}

run_test_case "install-nostril shows help" test_help
run_test_case "install-nostril succeeds when tooling already exists" test_success_when_tooling_already_present
run_test_case "install-nostril fails clearly without package manager" test_failure_without_supported_package_manager

finish_tests
