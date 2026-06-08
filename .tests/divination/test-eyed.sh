#!/bin/sh
# Behavioral coverage for the first-class eyed spell shim.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_eyed_help() {
  run_spell "spells/divination/eyed" --help
  assert_success && assert_output_contains "Usage:"
}

test_eyed_delegates_to_project() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/project/spells"
  cat > "$tmp/project/spells/eyed" <<'SH'
#!/bin/sh
printf 'daemon:%s\n' "$1"
SH
  chmod +x "$tmp/project/spells/eyed"
  EYE_PROJECT_ROOT="$tmp/project" run_spell "spells/divination/eyed" status
  assert_success && assert_output_contains "daemon:status"
}

run_test_case "eyed help" test_eyed_help
run_test_case "eyed delegates to project daemon" test_eyed_delegates_to_project

finish_tests
