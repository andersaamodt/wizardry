#!/bin/sh
# Behavioral coverage for start-docker-desktop spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/docker/start-docker-desktop"

test_start_docker_desktop_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_start_docker_desktop_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_start_docker_desktop_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "start-docker-desktop spell exists" test_start_docker_desktop_exists
run_test_case "start-docker-desktop spell is executable" test_start_docker_desktop_executable
run_test_case "start-docker-desktop spell --help is callable" test_start_docker_desktop_help_callable

finish_tests
