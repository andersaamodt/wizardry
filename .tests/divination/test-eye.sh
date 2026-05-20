#!/bin/sh
# Behavioral coverage for the first-class Eye spell shim.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_eye_help() {
  run_spell "spells/divination/eye" --help
  assert_success && assert_output_contains "Usage:"
}

test_eye_delegates_to_project() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/project/spells"
  cat > "$tmp/project/spells/eye" <<'SH'
#!/bin/sh
printf 'delegated:%s\n' "$1"
SH
  chmod +x "$tmp/project/spells/eye"
  EYE_PROJECT_ROOT="$tmp/project" run_spell "spells/divination/eye" cameras
  assert_success && assert_output_contains "delegated:cameras"
}

run_test_case "eye help" test_eye_help
run_test_case "eye delegates to project CLI" test_eye_delegates_to_project

finish_tests
