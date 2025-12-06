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
  [ -x "$ROOT_DIR/spells/.arcana/node/install-node" ]
}

_run_test_case "install/node/install-node is executable" spell_is_executable

renders_usage_information() {
  _run_cmd "$ROOT_DIR/spells/.arcana/node/install-node" --help

  _assert_success || return 1
  _assert_error_contains "Usage: install-node" || return 1
  _assert_error_contains "install Node.js" || return 1
}

_run_test_case "install-node prints usage with --help" renders_usage_information

runs_install_with_default_package() {
  tmp=$(_make_tempdir)
  log="$tmp/manage.log"
  cat >"$tmp/manage-system-command" <<SHI
#!/bin/sh
printf '%s ' "\$@" >>"$log"
printf '\n' >>"$log"
SHI
  chmod +x "$tmp/manage-system-command"

  _run_cmd env PATH="$tmp:$PATH" MANAGE_SYSTEM_COMMAND="$tmp/manage-system-command" NODE_PACKAGE_DEFAULT="nodejs-lts" \
    sh -c "printf '\n' | '$ROOT_DIR/spells/.arcana/node/install-node'"

  _assert_success || return 1
  _assert_file_contains "$log" "node nodejs-lts" || return 1
  _assert_output_contains "Installing Node.js" || return 1
}

_run_test_case "install-node installs the default package via manage-system-command" runs_install_with_default_package

respects_user_selected_package() {
  tmp=$(_make_tempdir)
  log="$tmp/manage.log"
  cat >"$tmp/manage-system-command" <<SHI
#!/bin/sh
printf '%s ' "\$@" >>"$log"
printf '\n' >>"$log"
SHI
  chmod +x "$tmp/manage-system-command"

  _run_cmd env PATH="$tmp:$PATH" MANAGE_SYSTEM_COMMAND="$tmp/manage-system-command" \
    sh -c "printf 'custompkg\\n' | '$ROOT_DIR/spells/.arcana/node/install-node'"

  _assert_success || return 1
  _assert_file_contains "$log" "node custompkg" || return 1
}

_run_test_case "install-node accepts a custom package choice" respects_user_selected_package

_finish_tests
