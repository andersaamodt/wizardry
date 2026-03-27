#!/bin/sh
# Behavioral coverage for start-docker-daemon spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/docker/start-docker-daemon"

test_start_docker_daemon_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_start_docker_daemon_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_start_docker_daemon_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

run_test_case "start-docker-daemon spell exists" test_start_docker_daemon_exists
run_test_case "start-docker-daemon spell is executable" test_start_docker_daemon_executable
run_test_case "start-docker-daemon spell --help is callable" test_start_docker_daemon_help_callable

finish_tests
