#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/web/check-jq --help
  assert_success
  assert_output_contains "Usage: check-jq"
}

test_ok_when_jq_exists() {
  tmp_bin=$(temp-dir check-jq-bin)
  cat > "$tmp_bin/jq" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp_bin/jq"

  PATH="$tmp_bin:/usr/bin:/bin:/usr/sbin:/sbin" run_spell spells/web/check-jq
  assert_success
  assert_output_contains "status=ok"

  rm -rf "$tmp_bin"
}

test_bad_when_jq_missing() {
  tmp_bin=$(temp-dir check-jq-bin)
  PATH="$tmp_bin" run_spell spells/web/check-jq
  assert_success
  assert_output_contains "status=bad"
  assert_output_contains "jq is not installed"
  rm -rf "$tmp_bin"
}

run_test_case "check-jq shows help" test_help
run_test_case "check-jq returns ok when jq exists" test_ok_when_jq_exists
run_test_case "check-jq reports missing jq" test_bad_when_jq_missing

finish_tests
