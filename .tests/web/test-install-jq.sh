#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/web/install-jq --help
  assert_success
  assert_output_contains "Usage: install-jq"
}

test_success_when_jq_already_present() {
  tmp_bin=$(temp-dir install-jq-bin)
  cat > "$tmp_bin/jq" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp_bin/jq"

  PATH="$tmp_bin:/usr/bin:/bin:/usr/sbin:/sbin" run_spell spells/web/install-jq
  assert_success
  assert_output_contains "already installed"

  rm -rf "$tmp_bin"
}

test_failure_without_supported_package_manager() {
  tmp_bin=$(temp-dir install-jq-bin)
  PATH="$tmp_bin" run_spell spells/web/install-jq
  assert_failure
  assert_output_contains "no supported package manager"
  rm -rf "$tmp_bin"
}

run_test_case "install-jq shows help" test_help
run_test_case "install-jq succeeds when jq already exists" test_success_when_jq_already_present
run_test_case "install-jq fails clearly without package manager" test_failure_without_supported_package_manager

finish_tests
