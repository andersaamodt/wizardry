#!/bin/sh
# Behavioral coverage for wizardry-apps-common spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/wizardry-apps/wizardry-apps-common"

test_wizardry_apps_common_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_wizardry_apps_common_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_wizardry_apps_common_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

test_wizardry_apps_common_prefers_current_component_paths() {
  apps_root=$(temp-dir wizardry-apps-current)
  mkdir -p "$apps_root/apps" "$apps_root/web"

  run_cmd env ROOT_DIR="$ROOT_DIR" WIZARDRY_APPS_DIR="$apps_root" /bin/sh -c '
    . "$ROOT_DIR/spells/.arcana/wizardry-apps/wizardry-apps-common"
    printf "apps=%s\n" "$(wizardry_apps_component_path apps)"
    printf "web=%s\n" "$(wizardry_apps_component_path web-templates)"
  '
  assert_success || return 1
  assert_output_contains "apps=$apps_root/apps" || return 1
  assert_output_contains "web=$apps_root/web" || return 1
}

test_wizardry_apps_common_supports_legacy_component_paths() {
  apps_root=$(temp-dir wizardry-apps-legacy)
  mkdir -p "$apps_root/.apps" "$apps_root/.web"

  run_cmd env ROOT_DIR="$ROOT_DIR" WIZARDRY_APPS_DIR="$apps_root" /bin/sh -c '
    . "$ROOT_DIR/spells/.arcana/wizardry-apps/wizardry-apps-common"
    printf "apps=%s\n" "$(wizardry_apps_component_path apps)"
    printf "web=%s\n" "$(wizardry_apps_component_path web-templates)"
  '
  assert_success || return 1
  assert_output_contains "apps=$apps_root/.apps" || return 1
  assert_output_contains "web=$apps_root/.web" || return 1
}

test_wizardry_apps_common_detects_current_apps_component() {
  apps_root=$(temp-dir wizardry-apps-installed)
  mkdir -p "$apps_root/apps"
  : > "$apps_root/apps/.sentinel"

  run_cmd env ROOT_DIR="$ROOT_DIR" WIZARDRY_APPS_DIR="$apps_root" /bin/sh -c '
    . "$ROOT_DIR/spells/.arcana/wizardry-apps/wizardry-apps-common"
    wizardry_apps_component_installed apps
  '
  assert_success
}

run_test_case "wizardry-apps-common spell exists" test_wizardry_apps_common_exists
run_test_case "wizardry-apps-common spell is executable" test_wizardry_apps_common_executable
run_test_case "wizardry-apps-common spell --help is callable" test_wizardry_apps_common_help_callable
run_test_case "wizardry-apps-common prefers current repo paths" test_wizardry_apps_common_prefers_current_component_paths
run_test_case "wizardry-apps-common supports legacy repo paths" test_wizardry_apps_common_supports_legacy_component_paths
run_test_case "wizardry-apps-common detects current apps install" test_wizardry_apps_common_detects_current_apps_component

finish_tests
