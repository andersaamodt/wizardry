#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

make_artificer_site_stub() {
  tmp=$1
  site_dir="$tmp/home/sites/daimon/cgi"
  mkdir -p "$site_dir"
  cat >"$site_dir/artificer-api" <<'SH'
#!/bin/sh
payload=$(cat)
printf '%s\n' "$payload" >>"$ARTIFICER_PROGRAM_TEST_LOG"
case "$payload" in
*action=add_workspace*)
  printf '%s\r\n\r\n' 'Content-Type: application/json'
  printf '%s\n' '{"success":true,"workspace":{"id":"ws_test"}}'
  ;;
*action=new_conversation*)
  printf '%s\r\n\r\n' 'Content-Type: application/json'
  printf '%s\n' '{"success":true,"conversation":{"id":"conv_test"}}'
  ;;
*action=run*)
  printf '%s\r\n\r\n' 'Content-Type: application/json'
  printf '%s\n' '{"success":true,"assistant":"programmed from Artificer"}'
  ;;
*)
  printf '%s\r\n\r\n' 'Content-Type: application/json'
  printf '%s\n' '{"success":false,"error":"unknown action"}'
  ;;
esac
SH
  chmod +x "$site_dir/artificer-api"
}

test_help() {
  run_spell "spells/spellcraft/program" --help
  assert_success || return 1
  assert_output_contains "Usage: program" || return 1
  assert_output_contains "without opening the GUI" || return 1
}

test_program_invokes_artificer_programming_mode() {
  tmp=$(make_tempdir)
  make_artificer_site_stub "$tmp"
  mkdir -p "$tmp/project"

  RUN_CMD_WORKDIR="$tmp/project" run_cmd env \
    HOME="$tmp/home" \
    ARTIFICER_PROGRAM_TEST_LOG="$tmp/artificer.log" \
    "$ROOT_DIR/spells/spellcraft/program" fix the bug

  assert_success || return 1
  assert_output_contains "programmed from Artificer" || return 1
  grep -F 'action=run' "$tmp/artificer.log" >/dev/null || {
    TEST_FAILURE_REASON="program should call the Artificer run action"
    return 1
  }
  grep -F 'run_mode=programming' "$tmp/artificer.log" >/dev/null || {
    TEST_FAILURE_REASON="program should use Artificer programming mode"
    return 1
  }
  grep -F 'compute_budget=long' "$tmp/artificer.log" >/dev/null || {
    TEST_FAILURE_REASON="program should default to long budget"
    return 1
  }
  grep -F 'max_iterations=6' "$tmp/artificer.log" >/dev/null || {
    TEST_FAILURE_REASON="program should default to six iterations"
    return 1
  }
  grep -F 'prompt=fix%20the%20bug' "$tmp/artificer.log" >/dev/null || {
    TEST_FAILURE_REASON="program should join freeform args into one prompt"
    return 1
  }
}

test_program_honors_model_budget_iterations_and_json() {
  tmp=$(make_tempdir)
  make_artificer_site_stub "$tmp"
  mkdir -p "$tmp/project"

  RUN_CMD_WORKDIR="$tmp/project" run_cmd env \
    HOME="$tmp/home" \
    ARTIFICER_PROGRAM_TEST_LOG="$tmp/artificer.log" \
    "$ROOT_DIR/spells/spellcraft/program" \
      --model qwen3.6:35b-a3b \
      --budget quick \
      --iterations 2 \
      --json \
      refactor safely

  assert_success || return 1
  assert_output_contains '"assistant":"programmed from Artificer"' || return 1
  grep -F 'model=qwen3.6%3A35b-a3b' "$tmp/artificer.log" >/dev/null || {
    TEST_FAILURE_REASON="program should pass selected model to Artificer"
    return 1
  }
  grep -F 'compute_budget=quick' "$tmp/artificer.log" >/dev/null || {
    TEST_FAILURE_REASON="program should honor selected budget"
    return 1
  }
  grep -F 'max_iterations=2' "$tmp/artificer.log" >/dev/null || {
    TEST_FAILURE_REASON="program should honor selected iterations"
    return 1
  }
}

test_program_rejects_bad_budget() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/project"
  RUN_CMD_WORKDIR="$tmp/project" run_cmd env \
    HOME="$tmp/home" \
    "$ROOT_DIR/spells/spellcraft/program" --budget forever fix bug

  assert_failure || return 1
  assert_error_contains "budget must be" || return 1
}

run_test_case "program shows help" test_help
run_test_case "program invokes Artificer programming mode" \
  test_program_invokes_artificer_programming_mode
run_test_case "program honors model budget iterations and json" \
  test_program_honors_model_budget_iterations_and_json
run_test_case "program rejects bad budget" test_program_rejects_bad_budget
