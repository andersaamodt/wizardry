#!/usr/bin/env bats

load 'test_helper/load'

setup() {
  default_setup
}

teardown() {
  default_teardown
}

@test 'read-contact requires a card argument' {
  run_spell 'spells/read-contact'
  assert_failure
  assert_output --partial 'Usage'
}

@test 'read-contact formats vCard fields and filters by type' {
  card="$BATS_TEST_TMPDIR/contact.vcf"
  cat <<'VCARD' >"$card"
BEGIN:VCARD
VERSION:3.0
FN:Merlin
EMAIL;TYPE=INTERNET:merlin@example.com
ADR;TYPE=HOME:123\;Wizard Lane;Camelot
X-CUSTOM:enchanted\,items
END:VCARD
VCARD

  run_spell 'spells/read-contact' "$card"
  assert_success
  assert_output --partial 'Full Name: Merlin'
  assert_output --partial 'Email: merlin@example.com'
  assert_output --partial 'Address: 123'
  assert_output --partial 'Wizard Lane'
  assert_output --partial 'Custom: enchanted, items'

  run_spell 'spells/read-contact' "$card" 'EMAIL'
  assert_success
  assert_output --partial 'Email: merlin@example.com'

  run_spell 'spells/read-contact' "$card" 'TEL'
  assert_failure
  assert_error --partial 'TEL not found'
}

