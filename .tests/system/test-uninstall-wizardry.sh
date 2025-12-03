#!/bin/sh
# Behavioral cases (derived from --help):
# - uninstall-wizardry prints usage
# - uninstall-wizardry uses WIZARDRY_DIR when provided
# - uninstall-wizardry rejects non-existent WIZARDRY_DIR
# - uninstall-wizardry auto-detects the install and runs uninstall
# - uninstall-wizardry fails when detection fails
# - uninstall-wizardry fails when install script is missing

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

make_stub_dir() {
  dir=$(make_tempdir)
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

test_help() {
  run_spell "spells/system/uninstall-wizardry" --help
  assert_success && assert_output_contains "Usage: uninstall-wizardry"
}

test_uses_env_directory() {
  stub_dir=$(make_stub_dir)
  wizard_dir=$(make_tempdir)
  install_log="$stub_dir/install.log"

  # Create a mock install script
  cat >"$wizard_dir/install" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$INSTALL_LOG"
exit 0
STUB
  chmod +x "$wizard_dir/install"

  INSTALL_LOG="$install_log" WIZARDRY_DIR="$wizard_dir" \
    run_spell "spells/system/uninstall-wizardry"
  assert_success
  assert_file_contains "$install_log" "--uninstall"
}

test_rejects_missing_env_directory() {
  stub_dir=$(make_stub_dir)
  missing_dir="$stub_dir/nowhere"

  WIZARDRY_DIR="$missing_dir" run_spell "spells/system/uninstall-wizardry"
  assert_failure
  assert_error_contains "does not exist or is not a directory"
}

test_detects_install_and_runs_uninstall() {
  # This test uses the actual spell location to detect the install script
  # We create a temporary directory structure that mirrors the actual layout
  stub_dir=$(make_stub_dir)
  wizard_dir="$stub_dir/wizardry"
  mkdir -p "$wizard_dir/spells/system"
  install_log="$stub_dir/install.log"

  # Create mock install script
  cat >"$wizard_dir/install" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"$INSTALL_LOG"
exit 0
STUB
  chmod +x "$wizard_dir/install"

  # Copy the uninstall-wizardry spell to the test directory
  cp "$ROOT_DIR/spells/system/uninstall-wizardry" "$wizard_dir/spells/system/"
  chmod +x "$wizard_dir/spells/system/uninstall-wizardry"

  INSTALL_LOG="$install_log" "$wizard_dir/spells/system/uninstall-wizardry"
  status=$?
  [ "$status" -eq 0 ] || { TEST_FAILURE_REASON="expected success, got exit $status"; return 1; }
  assert_file_contains "$install_log" "--uninstall"
}

test_detection_failure() {
  stub_dir=$(make_stub_dir)
  wizard_dir="$stub_dir/wizardry"
  mkdir -p "$wizard_dir/spells/system"

  # Copy the uninstall-wizardry spell but don't create install script
  cp "$ROOT_DIR/spells/system/uninstall-wizardry" "$wizard_dir/spells/system/"
  chmod +x "$wizard_dir/spells/system/uninstall-wizardry"

  "$wizard_dir/spells/system/uninstall-wizardry" 2>"$stub_dir/stderr" || true
  stderr=$(cat "$stub_dir/stderr")
  case "$stderr" in
    *"Unable to determine"*) : ;;
    *) TEST_FAILURE_REASON="expected detection failure message, got: $stderr"; return 1 ;;
  esac
}

test_missing_install_script() {
  stub_dir=$(make_stub_dir)
  wizard_dir=$(make_tempdir)

  # Don't create the install script

  WIZARDRY_DIR="$wizard_dir" run_spell "spells/system/uninstall-wizardry"
  assert_failure
  assert_error_contains "Install script not found"
}

run_test_case "uninstall-wizardry prints usage" test_help
run_test_case "uninstall-wizardry uses WIZARDRY_DIR when provided" test_uses_env_directory
run_test_case "uninstall-wizardry rejects missing WIZARDRY_DIR" test_rejects_missing_env_directory
run_test_case "uninstall-wizardry auto-detects the install and runs uninstall" test_detects_install_and_runs_uninstall
run_test_case "uninstall-wizardry fails when detection fails" test_detection_failure
run_test_case "uninstall-wizardry fails when install script is missing" test_missing_install_script
finish_tests
