#!/bin/sh
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/node/uninstall-node" ]
}

run_test_case "install/node/uninstall-node is executable" spell_is_executable

renders_usage_information() {
  run_cmd "$ROOT_DIR/spells/install/node/uninstall-node" --help

  assert_success || return 1
  assert_error_contains "Usage: uninstall-node" || return 1
  assert_error_contains "Removes Node.js" || return 1
}

run_test_case "uninstall-node prints usage with --help" renders_usage_information

runs_uninstall_with_default_package() {
  tmp=$(make_tempdir)
  log="$tmp/manage.log"
  cat >"$tmp/manage-system-command" <<SHI
#!/bin/sh
printf '%s ' "\$@" >>"$log"
printf '\n' >>"$log"
SHI
  chmod +x "$tmp/manage-system-command"

  run_cmd env PATH="$tmp:$PATH" MANAGE_SYSTEM_COMMAND="$tmp/manage-system-command" \
    sh -c "printf '\n' | '$ROOT_DIR/spells/install/node/uninstall-node'"

  assert_success || return 1
  assert_file_contains "$log" "--uninstall node nodejs" || return 1
}

run_test_case "uninstall-node removes the default package" runs_uninstall_with_default_package

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
