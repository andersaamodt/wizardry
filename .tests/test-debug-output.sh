#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

failed_subtests_fail_parent_test() {
  tmpdir="$(_make_tempdir)"
  tmpfile="$tmpdir/output.txt"
  
  fixture_dir="$ROOT_DIR/.tests/__temp_test_fixtures"
  mkdir -p "$fixture_dir"
  test_fixture="$fixture_dir/test-with-failures.sh"
  
  cat > "$test_fixture" << 'EOF'
#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pass1() { return 0; }
test_fail1() { TEST_FAILURE_REASON="failure 1"; return 1; }
test_pass2() { return 0; }
test_fail2() { TEST_FAILURE_REASON="failure 2"; return 1; }

_run_test_case "pass 1" test_pass1
_run_test_case "fail 1" test_fail1
_run_test_case "pass 2" test_pass2
_run_test_case "fail 2" test_fail2
_finish_tests
EOF
  chmod +x "$test_fixture"
  
  cd "$ROOT_DIR" || return 1
  
  # DEBUG: Write to stderr which will be visible
  printf "DEBUG: About to run test-magic\n" >&2
  printf "DEBUG: tmpfile=%s\n" "$tmpfile" >&2
  printf "DEBUG: WIZARDRY_TMPDIR=%s\n" "$WIZARDRY_TMPDIR" >&2
  
  sh spells/system/test-magic --only "__temp_test_fixtures/test-with-failures.sh" >"$tmpfile" 2>&1 || true
  
  printf "DEBUG: test-magic finished\n" >&2
  printf "DEBUG: tmpfile size=%s\n" "$(wc -c < "$tmpfile" 2>/dev/null || printf '0')" >&2
  printf "DEBUG: tmpfile exists=%s\n" "$([ -f "$tmpfile" ] && printf 'yes' || printf 'no')" >&2
  
  if [ -f "$tmpfile" ]; then
    printf "DEBUG: first line of tmpfile: %s\n" "$(head -1 "$tmpfile")" >&2
  fi
  
  rm -rf "$fixture_dir"
  
  summary=$(grep "^Tests:" "$tmpfile" || true)
  
  printf "DEBUG: summary=|%s|\n" "$summary" >&2
  
  failed_count=$(printf '%s\n' "$summary" | awk '{for(i=1;i<=NF;i++) if($(i+1)=="failed,") print $i}')
  
  [ -n "$failed_count" ] && [ "$failed_count" -gt 0 ] || {
    TEST_FAILURE_REASON="Test with failing subtests was not counted as failed (summary: $summary)"
    return 1
  }
  
  return 0
}

_run_test_case "debug test" failed_subtests_fail_parent_test
_finish_tests
