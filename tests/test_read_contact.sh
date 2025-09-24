#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"

run_script "spells/read-contact"
expect_exit_code 1
expect_in_output "Usage" "$RUN_STDOUT"

tmp_dir=$(make_temp_dir)
card="$tmp_dir/contact.vcf"
cat <<'VCARD' >"$card"
BEGIN:VCARD
VERSION:3.0
FN:Merlin
EMAIL;TYPE=INTERNET:merlin@example.com
ADR;TYPE=HOME:123\\;Wizard Lane;Camelot
X-CUSTOM:enchanted\\,items
END:VCARD
VCARD

run_script "spells/read-contact" "$card"
expect_exit_code 0
expect_in_output "Full Name: Merlin" "$RUN_STDOUT"
expect_in_output "Email: merlin@example.com" "$RUN_STDOUT"
expect_in_output "Address: 123" "$RUN_STDOUT"
expect_in_output "Wizard Lane" "$RUN_STDOUT"
expect_in_output "Custom: enchanted, items" "$RUN_STDOUT"

run_script "spells/read-contact" "$card" "EMAIL"
expect_exit_code 0
expect_in_output "Email: merlin@example.com" "$RUN_STDOUT"

run_script "spells/read-contact" "$card" "TEL"
expect_exit_code 1
expect_in_output "TEL not found" "$RUN_STDERR"

assert_all_expectations_met
