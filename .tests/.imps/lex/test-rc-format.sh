#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_nix_format() {
  _run_spell "spells/.imps/lex/rc-format" "/home/user/.config/home-manager/home.nix"
  _assert_success && _assert_output_contains "nix"
}

test_shell_format() {
  _run_spell "spells/.imps/lex/rc-format" "/home/user/.bashrc"
  _assert_success && _assert_output_contains "shell"
}

test_profile_is_shell() {
  _run_spell "spells/.imps/lex/rc-format" "/home/user/.profile"
  _assert_success && _assert_output_contains "shell"
}

_run_test_case "rc-format detects nix format" test_nix_format
_run_test_case "rc-format detects shell format" test_shell_format
_run_test_case "rc-format treats .profile as shell" test_profile_is_shell
_finish_tests
