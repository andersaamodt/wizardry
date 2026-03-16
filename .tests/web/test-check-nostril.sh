#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell spells/web/check-nostril --help
  assert_success
  assert_output_contains "Usage: check-nostril"
}

test_ok_when_binaries_exist() {
  tmp_bin=$(temp-dir check-nostril-bin)
  cat > "$tmp_bin/nostril" <<'EOF'
#!/bin/sh
exit 0
EOF
  cat > "$tmp_bin/nak" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp_bin/nostril" "$tmp_bin/nak"

  PATH="$tmp_bin:/usr/bin:/bin:/usr/sbin:/sbin" run_spell spells/web/check-nostril
  assert_success
  assert_output_contains "status=ok"

  rm -rf "$tmp_bin"
}

test_bad_when_binary_missing() {
  tmp_bin=$(temp-dir check-nostril-bin)
  cat > "$tmp_bin/nostril" <<'EOF'
#!/bin/sh
exit 0
EOF
  chmod +x "$tmp_bin/nostril"

  PATH="$tmp_bin:/usr/bin:/bin:/usr/sbin:/sbin" run_spell spells/web/check-nostril
  assert_success
  assert_output_contains "status=bad"
  assert_output_contains "nak"

  rm -rf "$tmp_bin"
}

run_test_case "check-nostril shows help" test_help
run_test_case "check-nostril returns ok when nostril and nak exist" test_ok_when_binaries_exist
run_test_case "check-nostril reports missing tooling" test_bad_when_binary_missing

finish_tests
