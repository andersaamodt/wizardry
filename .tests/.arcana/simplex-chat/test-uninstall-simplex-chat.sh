#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="$ROOT_DIR/spells/.arcana/simplex-chat/uninstall-simplex-chat"

spell_is_executable() {
  [ -x "$target" ]
}

run_test_case "install/simplex-chat/uninstall-simplex-chat is executable" spell_is_executable

shows_usage() {
  run_cmd "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: uninstall-simplex-chat" || return 1
}

run_test_case "uninstall-simplex-chat shows usage" shows_usage

write_fake_simplex_binary() {
  fake_bin=$1
  cat >"$fake_bin" <<'SHI'
#!/bin/sh
[ "${1-}" = "-h" ] && exit 0
exit 0
SHI
  chmod +x "$fake_bin"
}

removes_managed_runtime_and_link() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/state/simplex/current" "$tmp/bin"
  write_fake_simplex_binary "$tmp/state/simplex/current/simplex-chat"
  printf '%s\n' wizardry-managed-simplex-cli >"$tmp/state/simplex/.wizardry-simplex-root"
  ln -s "$tmp/state/simplex/current/simplex-chat" "$tmp/bin/simplex-chat"

  run_cmd env \
    PATH="$tmp:$PATH" \
    HOME="$tmp/home" \
    XDG_BIN_HOME="$tmp/bin" \
    WIZARDRY_SIMPLEX_ROOT="$tmp/state/simplex" \
    "$target"

  assert_success || return 1
  [ ! -e "$tmp/state/simplex" ] || {
    TEST_FAILURE_REASON="managed SimpleX root should be removed"
    return 1
  }
  [ ! -e "$tmp/bin/simplex-chat" ] || {
    TEST_FAILURE_REASON="managed simplex-chat link should be removed"
    return 1
  }
}

run_test_case "uninstall-simplex-chat removes managed runtime and link" removes_managed_runtime_and_link

leaves_unmarked_root_unchanged() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/state/simplex/current" "$tmp/bin"
  write_fake_simplex_binary "$tmp/state/simplex/current/simplex-chat"

  run_cmd env \
    PATH="$tmp:$PATH" \
    HOME="$tmp/home" \
    XDG_BIN_HOME="$tmp/bin" \
    WIZARDRY_SIMPLEX_ROOT="$tmp/state/simplex" \
    "$target"

  assert_success || return 1
  [ -d "$tmp/state/simplex" ] || {
    TEST_FAILURE_REASON="unmarked SimpleX root should be preserved"
    return 1
  }
  assert_error_contains "not marked as a Wizardry SimpleX install" || return 1
}

run_test_case "uninstall-simplex-chat preserves unmarked roots" leaves_unmarked_root_unchanged

finish_tests
