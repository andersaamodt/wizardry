#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/test_framework.sh"

export COVERAGE_TARGETS="spells/bind-tome spells/cantrips/ask spells/cantrips/await-keypress spells/copy spells/enchantment-to-yaml"
run_script tests/check_posix_bash.sh
expect_exit_code 0
expect_in_output "Warning: spells/bind-tome" "$RUN_STDERR"
expect_in_output "Warning: spells/cantrips/await-keypress" "$RUN_STDERR"
expect_in_output "Warning: spells/enchantment-to-yaml" "$RUN_STDERR"
expect_not_in_output "spells/copy" "$RUN_STDERR"
assert_all_expectations_met
