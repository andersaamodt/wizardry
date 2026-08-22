#!/bin/sh
# Behavioral coverage for list-contacts:
# - shows usage with --help
# - shows usage with -h
# - creates directory if it doesn't exist
# - handles empty directory gracefully

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/psi/list-contacts" ]
}

shows_help() {
  run_spell spells/psi/list-contacts --help
  assert_success
  assert_output_contains "Usage:"
}

shows_help_h_flag() {
  run_spell spells/psi/list-contacts -h
  assert_success
  assert_output_contains "Usage:"
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/psi/list-contacts" ]
}

test_handles_empty_directory() {
  tmpdir=$(make_tempdir)
  contacts_dir="$tmpdir/empty-contacts"
  mkdir -p "$contacts_dir"
  run_spell spells/psi/list-contacts "$contacts_dir"
  assert_success
}

parses_vcards_portably() {
  tmpdir=$(make_tempdir)
  contacts_dir="$tmpdir/contacts"
  mkdir -p "$contacts_dir"

  cat > "$contacts_dir/alice.vcf" <<'EOF'
BEGIN:VCARD
VERSION:3.0
FN:Alice Example
END:VCARD
EOF

  cat > "$contacts_dir/org-only.vcf" <<'EOF'
BEGIN:VCARD
VERSION:3.0
ORG:Wizardry Guild
END:VCARD
EOF

  cat > "$contacts_dir/tel-only.vcf" <<'EOF'
BEGIN:VCARD
VERSION:3.0
TEL:+1-555-0100
END:VCARD
EOF

  cat > "$contacts_dir/folded.vcf" <<'EOF'
BEGIN:VCARD
VERSION:3.0
FN:Folded Long
 Name
END:VCARD
EOF

  cat > "$contacts_dir/escaped.vcf" <<'EOF'
BEGIN:VCARD
VERSION:3.0
FN:Escaped\, Person\; Friend
END:VCARD
EOF

  cat > "$contacts_dir/unknown.vcf" <<'EOF'
BEGIN:VCARD
VERSION:3.0
NOTE:No display fields here
END:VCARD
EOF

  run_spell spells/psi/list-contacts "$contacts_dir"
  assert_success
  assert_output_contains "Alice Example"
  assert_output_contains "Wizardry Guild"
  assert_output_contains "+1-555-0100"
  assert_output_contains "Folded LongName"
  assert_output_contains "Escaped, Person; Friend"
  assert_output_contains "<unknown.vcf>"
}

run_test_case "psi/list-contacts is executable" spell_is_executable
run_test_case "list-contacts shows help" shows_help
run_test_case "list-contacts shows help with -h" shows_help_h_flag
run_test_case "psi/list-contacts has content" spell_has_content
run_test_case "list-contacts handles empty directory" test_handles_empty_directory
run_test_case "list-contacts parses vcards portably" parses_vcards_portably


# Test via source-then-invoke pattern  

finish_tests
