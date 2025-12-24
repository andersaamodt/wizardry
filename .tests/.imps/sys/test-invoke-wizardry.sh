#!/bin/sh
# Tests for invoke-wizardry initialization

# Locate repository root and source test-bootstrap
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_invoke_wizardry_zsh_handles_empty_spellbook() {
  if ! command -v zsh >/dev/null 2>&1; then
    TEST_SKIP_REASON="zsh not installed"
    return 222
  fi

  tmp_spellbook=$(_make_tempdir)
  WIZARDRY_DIR=$ROOT_DIR SPELLBOOK_DIR=$tmp_spellbook _run_cmd zsh -f -c 'unset _WIZARDRY_INVOKED; . "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry"'
  _assert_success || return 1

  case "$ERROR" in
    *"no matches found"*)
      TEST_FAILURE_REASON="glob failure when spellbook empty"
      return 1
      ;;
  esac

  case "$ERROR" in
    *"Spell sourcing complete: total=0"*)
      TEST_FAILURE_REASON="invoke-wizardry skipped spells"
      return 1
      ;;
  esac
}

_run_test_case "invoke-wizardry handles empty spellbook in zsh" test_invoke_wizardry_zsh_handles_empty_spellbook

_finish_tests
