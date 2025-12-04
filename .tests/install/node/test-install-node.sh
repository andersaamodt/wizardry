#!/bin/sh
set -eu

# Locate test helpers
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/node/install-node" ]
}

run_test_case "install/node/install-node is executable" spell_is_executable

runs_install_with_default_package() {
  tmp=$(make_tempdir)
  log="$tmp/manage.log"
  cat >"$tmp/manage-system-command" <<SHI
#!/bin/sh
printf '%s ' "\$@" >>"$log"
printf '\n' >>"$log"
SHI
  chmod +x "$tmp/manage-system-command"

  run_cmd env PATH="$tmp:$PATH" MANAGE_SYSTEM_COMMAND="$tmp/manage-system-command" NODE_PACKAGE_DEFAULT="nodejs-lts" \
    sh -c "printf '\n' | '$ROOT_DIR/spells/install/node/install-node'"

  assert_success || return 1
  assert_file_contains "$log" "node nodejs-lts" || return 1
  assert_output_contains "Installing Node.js" || return 1
}

run_test_case "install-node installs the default package via manage-system-command" runs_install_with_default_package

respects_user_selected_package() {
  tmp=$(make_tempdir)
  log="$tmp/manage.log"
  cat >"$tmp/manage-system-command" <<SHI
#!/bin/sh
printf '%s ' "\$@" >>"$log"
printf '\n' >>"$log"
SHI
  chmod +x "$tmp/manage-system-command"

  run_cmd env PATH="$tmp:$PATH" MANAGE_SYSTEM_COMMAND="$tmp/manage-system-command" \
    sh -c "printf 'custompkg\\n' | '$ROOT_DIR/spells/install/node/install-node'"

  assert_success || return 1
  assert_file_contains "$log" "node custompkg" || return 1
}

run_test_case "install-node accepts a custom package choice" respects_user_selected_package

finish_tests
