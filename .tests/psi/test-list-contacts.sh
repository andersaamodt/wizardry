#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/psi/list-contacts" ]
}

shows_help() {
  run_spell spells/psi/list-contacts --help
  assert_success
  assert_output_contains "Usage:"
}

lists_names_and_fallbacks() {
  contacts_dir=$(mktemp -d "$WIZARDRY_TMPDIR/contacts.XXXXXX")

  cat >"$contacts_dir/alice.vcf" <<'VCF'
BEGIN:VCARD
FN:Alice Example
END:VCARD
VCF

  cat >"$contacts_dir/org-only.vcf" <<'VCF'
BEGIN:VCARD
ORG:Example Org
END:VCARD
VCF

  cat >"$contacts_dir/phone-only.vcf" <<'VCF'
BEGIN:VCARD
TEL:+15551234567
END:VCARD
VCF

  cat >"$contacts_dir/unknown.vcf" <<'VCF'
BEGIN:VCARD
NOTE:No identifying fields
END:VCARD
VCF

  run_spell spells/psi/list-contacts "$contacts_dir"
  assert_success
  assert_output_contains "Alice Example"
  assert_output_contains "Example Org"
  assert_output_contains "+15551234567"
  assert_output_contains "<unknown.vcf>"
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/psi/list-contacts" ]
}

run_test_case "psi/list-contacts is executable" spell_is_executable
run_test_case "list-contacts shows help" shows_help
run_test_case "psi/list-contacts has content" spell_has_content
run_test_case "list-contacts lists names and fallbacks" lists_names_and_fallbacks

finish_tests
