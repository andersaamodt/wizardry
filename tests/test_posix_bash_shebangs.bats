#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
}

teardown() {
  default_teardown
}

@test 'check_posix_bash warns for known Bash-only spells' {
  COVERAGE_TARGETS='spells/bind-tome spells/cantrips/ask spells/cantrips/await-keypress spells/copy spells/enchantment-to-yaml' \
    run --separate-stderr -- "$ROOT_DIR/tests/check_posix_bash.sh"
  assert_success
  assert_error --partial 'Warning: spells/bind-tome'
  assert_error --partial 'Warning: spells/cantrips/await-keypress'
  assert_error --partial 'Warning: spells/enchantment-to-yaml'
  [[ "$stderr" != *'spells/copy'* ]]
}

