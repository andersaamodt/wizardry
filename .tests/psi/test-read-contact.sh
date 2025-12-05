#!/bin/sh
# Behavioral cases (derived from --help):
# - read-contact prints usage
# - read-contact requires a vcard path
# - read-contact prints friendly field labels and normalizes escapes
# - read-contact can extract a single requested field
# - read-contact reports missing fields clearly

set -eu

# Setup test environment
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
ROOT_DIR=$_test_dir
_sys_path=${PATH:-/usr/local/bin:/usr/bin:/bin}
PATH="$ROOT_DIR/spells:$ROOT_DIR/spells/.imps"
for _d in "$ROOT_DIR/spells/.imps"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
for _d in "$ROOT_DIR/spells"/*; do [ -d "$_d" ] && PATH="$PATH:$_d"; done
PATH="$PATH:$_sys_path"
WIZARDRY_TMPDIR=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")
export ROOT_DIR PATH WIZARDRY_TMPDIR

# Test state
_pass=0 _fail=0

# Run command and capture output
run_cmd() {
  _o=$(mktemp "$WIZARDRY_TMPDIR/o.XXXXXX"); _e=$(mktemp "$WIZARDRY_TMPDIR/e.XXXXXX")
  STATUS=0; "$@" >"$_o" 2>"$_e" || STATUS=$?
  OUTPUT=$(cat "$_o"); ERROR=$(cat "$_e"); rm -f "$_o" "$_e"
}
run_spell() { _s=$1; shift; run_cmd "$ROOT_DIR/$_s" "$@"; }

# Assertions (call imps with captured state)
assert_success() { test-assert-success "$STATUS" "$ERROR"; }
assert_failure() { test-assert-failure "$STATUS"; }
assert_status() { test-assert-status "$STATUS" "$1" "$ERROR"; }
assert_output_contains() { test-assert-output-contains "$OUTPUT" "$1"; }
assert_error_contains() { test-assert-error-contains "$ERROR" "$1"; }
assert_file_contains() { test-assert-file-contains "$1" "$2"; }
assert_path_exists() { test-assert-path-exists "$1"; }
assert_path_missing() { test-assert-path-missing "$1"; }

# Fixture helpers
make_tempdir() { test-make-tempdir; }
make_fixture() { test-make-fixture; }
write_apt_stub() { test-write-apt-stub "$1"; }
write_sudo_stub() { test-write-sudo-stub "$1"; }
write_command_stub() { test-write-command-stub "$1" "$2"; }
write_pkgin_stub() { test-write-pkgin-stub "$1"; }
provide_basic_tools() { test-provide-basic-tools "$1"; }
link_tools() { test-link-tools "$@"; }

# Test runner
run_test_case() {
  _d=$1; _f=$2
  if "$_f"; then _pass=$((_pass+1)); printf 'PASS %s\n' "$_d"
  else _fail=$((_fail+1)); printf 'FAIL %s\n' "$_d"; fi
}
finish_tests() {
  _t=$((_pass+_fail))
  printf '%s/%s tests passed' "$_pass" "$_t"
  [ "$_fail" -gt 0 ] && printf ' (%s failed)\n' "$_fail" && return 1
  printf '\n'
}


test_help() {
  run_spell "spells/psi/read-contact" --help
  assert_success || return 1
  assert_output_contains "Usage: read-contact" || return 1
  assert_output_contains "Print all fields from a vCard file" || return 1
}

read_contact_requires_path() {
  run_spell "spells/psi/read-contact"
  assert_failure || return 1
  assert_error_contains "Usage: read-contact" || return 1
}

read_contact_formats_fields() {
  vcard_dir=$(make_tempdir)
  card="$vcard_dir/alex.vcf"
  cat <<'CARD' >"$card"
BEGIN:VCARD
VERSION:3.0
FN:Alex Example
EMAIL:alex@example.com
ADR;TYPE=home:;;123\, Main St;Town;ST;12345;Country
URL:https\://example.com/profile
END:VCARD
CARD

  run_spell "spells/psi/read-contact" "$card"
  assert_success || return 1
  assert_output_contains "Full Name: Alex Example" || return 1
  assert_output_contains "Email: alex@example.com" || return 1
  assert_output_contains "Address: ;;123,  Main St;Town;ST;12345;Country" || return 1
  assert_output_contains "URL: https\\://example.com/profile" || return 1
}

read_contact_extracts_single_field() {
  vcard_dir=$(make_tempdir)
  card="$vcard_dir/alex.vcf"
  cat <<'CARD' >"$card"
BEGIN:VCARD
VERSION:3.0
FN:Alex Example
TEL;TYPE=cell:+123456789
END:VCARD
CARD

  run_spell "spells/psi/read-contact" "$card" TEL
  assert_success || return 1
  assert_output_contains "Telephone: +123456789" || return 1
  expected_output=$(printf 'Telephone: +123456789\n')
  [ "$OUTPUT" = "$expected_output" ] || { TEST_FAILURE_REASON="unexpected output for single field"; return 1; }
}

read_contact_reports_missing_field() {
  vcard_dir=$(make_tempdir)
  card="$vcard_dir/merlin.vcf"
  cat <<'CARD' >"$card"
BEGIN:VCARD
VERSION:3.0
FN:Merlin
EMAIL;TYPE=INTERNET:merlin@example.com
END:VCARD
CARD

  run_spell "spells/psi/read-contact" "$card" TEL
  assert_failure || return 1
  assert_error_contains "TEL not found" || return 1
}

read_contact_normalizes_escapes_and_urls() {
  card_dir=$(make_tempdir)
  card="$card_dir/escaped.vcf"
  cat <<'VCARD' >"$card"
BEGIN:VCARD
VERSION:3.0
FN:Escaper
ADR;TYPE=WORK:123\\;Main St\\;Suite 9
NOTE:escaped\\,comma\\;semi\\\\backslash\\nnext
URL:https\://example.com/path
END:VCARD
VCARD

  run_spell "spells/psi/read-contact" "$card"
  assert_success || return 1
  assert_output_contains "Address: 123" || return 1
  assert_output_contains "Main St" || return 1
  assert_output_contains "Suite 9" || return 1
  assert_output_contains "Note: escaped, comma" || return 1
  assert_output_contains "next" || return 1
  assert_output_contains "URL: https\\://example.com/path" || return 1
}

read_contact_rejects_missing_file() {
  missing_path="/nonexistent/ghost.vcf"

  run_spell "spells/psi/read-contact" "$missing_path"
  assert_failure || return 1
  assert_error_contains "vCard file not found" || return 1
}

read_contact_rejects_malformed_cards() {
  vcard_dir=$(make_tempdir)
  empty_card="$vcard_dir/empty.vcf"
  printf '' >"$empty_card"

  run_spell "spells/psi/read-contact" "$empty_card"
  assert_failure || return 1
  assert_error_contains "No vCard entries" || return 1

  broken_card="$vcard_dir/broken.vcf"
  cat <<'CARD' >"$broken_card"
BEGIN:VCARD
FN:Halfway
CARD

  run_spell "spells/psi/read-contact" "$broken_card"
  assert_failure || return 1
  assert_error_contains "Unbalanced vCard entries" || return 1
}

read_contact_rejects_multiple_cards() {
  card_dir=$(make_tempdir)
  card_path="$card_dir/multiple.vcf"
  cat <<'CARDS' >"$card_path"
BEGIN:VCARD
FN:First
END:VCARD
BEGIN:VCARD
FN:Second
END:VCARD
CARDS

  run_spell "spells/psi/read-contact" "$card_path"
  assert_failure || return 1
  assert_error_contains "Multiple vCard entries" || return 1
}

read_contact_handles_crlf_cards() {
  card_dir=$(make_tempdir)
  card="$card_dir/crlf.vcf"
  printf 'BEGIN:VCARD\r\nVERSION:3.0\r\nFN:CRLF Friend\r\nEND:VCARD\r\n' >"$card"

  run_spell "spells/psi/read-contact" "$card"
  assert_success || return 1
  assert_output_contains "Full Name: CRLF Friend" || return 1
}

run_test_case "read-contact prints usage" test_help
run_test_case "read-contact requires a vcard path" read_contact_requires_path
run_test_case "read-contact formats core vCard fields" read_contact_formats_fields
run_test_case "read-contact extracts a requested field" read_contact_extracts_single_field
run_test_case "read-contact reports when a requested field is missing" read_contact_reports_missing_field
run_test_case "read-contact normalizes escapes and URLs" read_contact_normalizes_escapes_and_urls
run_test_case "read-contact rejects missing files" read_contact_rejects_missing_file
run_test_case "read-contact rejects malformed cards" read_contact_rejects_malformed_cards
run_test_case "read-contact rejects multi-card vcf inputs" read_contact_rejects_multiple_cards
run_test_case "read-contact handles CRLF vCards" read_contact_handles_crlf_cards

finish_tests
