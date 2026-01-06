#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/mud/toggle-parse" --help
  assert_success && assert_output_contains "Usage:"
}

test_requires_mud_config() {
  # When mud-config is not available, should fail gracefully
  tmpdir=$(make_tempdir)
  
  # Create minimal PATH without mud-config
  PATH="$ROOT_DIR/spells/.imps:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:/usr/local/bin:/usr/bin:/bin" \
    run_spell "spells/.arcana/mud/toggle-parse"
  
  assert_failure
  assert_error_contains "mud-config not found"
}

test_calls_mud_config_toggle() {
  # Create a stub mud-config that records being called
  tmpdir=$(make_tempdir)
  stub_dir="$tmpdir/stubs"
  mkdir -p "$stub_dir"
  
  # Create stub mud-config
  cat > "$stub_dir/mud-config" <<'STUB'
#!/bin/sh
printf 'mud-config called with args: %s\n' "$*"
# Just output something to verify it was called with "toggle parse-enabled"
if [ "$1" = "toggle" ] && [ "$2" = "parse-enabled" ]; then
  printf 'Parse-enabled toggled\n'
  exit 0
fi
exit 1
STUB
  chmod +x "$stub_dir/mud-config"
  
  # Run toggle-parse with stub in PATH
  PATH="$stub_dir:$ROOT_DIR/spells/.imps:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:/usr/local/bin:/usr/bin:/bin" \
    run_spell "spells/.arcana/mud/toggle-parse"
  
  assert_success
  assert_output_contains "toggle parse-enabled"
}

run_test_case "toggle-parse shows usage" test_help
run_test_case "toggle-parse requires mud-config" test_requires_mud_config
run_test_case "toggle-parse calls mud-config toggle" test_calls_mud_config_toggle

# Test via source-then-invoke pattern

finish_tests
