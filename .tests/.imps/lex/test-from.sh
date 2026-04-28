#!/bin/sh
# Tests for the 'from' linking word imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_from_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/from" ]
}

test_from_prepends_source() {
  tmp=$(make_tempdir)
  echo "content" > "$tmp/source.txt"
  
  run_spell spells/.imps/lex/from "cp" "$tmp/dest.txt" "$tmp/source.txt"
  assert_success || return 1
  
  if [ ! -f "$tmp/dest.txt" ]; then
    TEST_FAILURE_REASON="File not copied from source"
    return 1
  fi
}

test_from_preserves_source_with_spaces() {
  tmp=$(make_tempdir)
  printf '%s\n' "content" > "$tmp/source file.txt"

  run_spell spells/.imps/lex/from "cp" "$tmp/dest.txt" "$tmp/source file.txt"
  assert_success || return 1

  if [ ! -f "$tmp/dest.txt" ]; then
    TEST_FAILURE_REASON="File not copied from source containing spaces"
    return 1
  fi
}

test_from_sources_parse_for_remaining_words() {
  saved_wizdir="${WIZARDRY_DIR-}"
  tmp=$(make_tempdir)
  mkdir -p "$tmp/wizardry/spells/test"

  cat > "$tmp/wizardry/spells/test/show-args" <<'EOF'
#!/bin/sh
printf 'args: [%s]\n' "$*"
EOF
  chmod +x "$tmp/wizardry/spells/test/show-args"

  WIZARDRY_DIR="$tmp/wizardry" run_spell spells/.imps/lex/from "show-args" "dest value" "source value" "after"

  if [ -n "$saved_wizdir" ]; then export WIZARDRY_DIR="$saved_wizdir"; else unset WIZARDRY_DIR; fi

  assert_success || return 1
  assert_output_contains "args: [source value dest value after]" || return 1
}

test_from_requires_source() {
  run_spell spells/.imps/lex/from "echo" "hello"
  assert_failure || return 1
}

test_from_requires_command() {
  run_spell spells/.imps/lex/from "" "" "/tmp/source"
  assert_failure || return 1
}

run_test_case "from is executable" test_from_is_executable
run_test_case "from prepends source to args" test_from_prepends_source
run_test_case "from preserves source with spaces" test_from_preserves_source_with_spaces
run_test_case "from sources parse for remaining words" test_from_sources_parse_for_remaining_words
run_test_case "from requires source" test_from_requires_source
run_test_case "from requires command" test_from_requires_command

finish_tests
