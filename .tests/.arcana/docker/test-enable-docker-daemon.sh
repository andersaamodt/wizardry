#!/bin/sh
# Behavioral coverage for enable-docker-daemon spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/docker/enable-docker-daemon"

test_enable_docker_daemon_exists() {
  [ -f "$target" ] || {
    TEST_FAILURE_REASON="missing spell: $target"
    return 1
  }
}

test_enable_docker_daemon_executable() {
  [ -x "$target" ] || {
    TEST_FAILURE_REASON="spell not executable: $target"
    return 1
  }
}

test_enable_docker_daemon_help_callable() {
  run_spell "$target" --help
  case "$STATUS" in
    0|1|2) return 0 ;;
  esac
  TEST_FAILURE_REASON="unexpected --help status $STATUS for $target"
  return 1
}

test_enable_docker_daemon_requires_explicit_macos_login_autostart() {
  grep -F 'WIZARDRY_DOCKER_DESKTOP_LOGIN_AUTOSTART=1' "$target" >/dev/null || {
    TEST_FAILURE_REASON="macOS Docker Desktop login autostart must require explicit opt-in"
    return 1
  }
  grep -F 'refusing to enable Docker Desktop login autostart' "$target" >/dev/null || {
    TEST_FAILURE_REASON="macOS Docker Desktop login autostart refusal message missing"
    return 1
  }
}

run_test_case "enable-docker-daemon spell exists" test_enable_docker_daemon_exists
run_test_case "enable-docker-daemon spell is executable" test_enable_docker_daemon_executable
run_test_case "enable-docker-daemon spell --help is callable" test_enable_docker_daemon_help_callable
run_test_case "enable-docker-daemon requires explicit macOS login autostart opt-in" test_enable_docker_daemon_requires_explicit_macos_login_autostart

finish_tests
