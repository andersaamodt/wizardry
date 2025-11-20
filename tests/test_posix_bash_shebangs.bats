#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
}

teardown() {
  default_teardown
}

@test 'check_posix_bash is quiet once spells use POSIX shebangs' {
  COVERAGE_TARGETS='spells/bind-tome spells/cantrips/ask spells/cantrips/await-keypress spells/copy spells/enchantment-to-yaml' \
    run --separate-stderr -- "$ROOT_DIR/tests/check_posix_bash.sh"
  assert_success
  [ -z "$stderr" ]
}

