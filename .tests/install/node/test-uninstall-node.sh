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
  [ -x "$ROOT_DIR/spells/install/node/uninstall-node" ]
}

run_test_case "install/node/uninstall-node is executable" spell_is_executable

runs_uninstall_with_package_override() {
  tmp=$(make_tempdir)
  log="$tmp/manage.log"
  cat >"$tmp/manage-system-command" <<SHI
#!/bin/sh
printf '%s ' "\$@" >>"$log"
printf '\n' >>"$log"
SHI
  chmod +x "$tmp/manage-system-command"

  run_cmd env PATH="$tmp:$PATH" MANAGE_SYSTEM_COMMAND="$tmp/manage-system-command" NODE_PACKAGE="node-custom" \
    sh -c "printf '\n' | '$ROOT_DIR/spells/install/node/uninstall-node'"

  assert_success || return 1
  assert_file_contains "$log" "--uninstall node node-custom" || return 1
  assert_output_contains "removal" || return 1
}

run_test_case "uninstall-node removes the requested package" runs_uninstall_with_package_override

finish_tests
