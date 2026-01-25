#!/bin/sh
set -eu

# Locate test helpers
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/web-wizardry/is-web-component-installed" ]
}

run_test_case "is-web-component-installed is executable" spell_is_executable

renders_usage_information() {
  skip-if-compiled || return $?
  run_cmd "$ROOT_DIR/spells/.arcana/web-wizardry/is-web-component-installed" --help

  assert_success || return 1
  assert_output_contains "Usage: is-web-component-installed" || return 1
}

run_test_case "is-web-component-installed prints usage with --help" renders_usage_information

detects_pandoc_installed() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  link_tools "$tmp" sh cat printf test env basename dirname pwd
  
  # Create pandoc stub
  cat >"$tmp/pandoc" <<'SHI'
#!/bin/sh
exit 0
SHI
  chmod +x "$tmp/pandoc"

  run_cmd env PATH="$tmp:$WIZARDRY_IMPS_PATH" \
    "$ROOT_DIR/spells/.arcana/web-wizardry/is-web-component-installed" pandoc

  assert_success
}

run_test_case "is-web-component-installed detects pandoc" detects_pandoc_installed

finish_tests
