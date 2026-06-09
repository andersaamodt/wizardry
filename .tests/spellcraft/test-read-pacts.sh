#!/bin/sh
# Behavioral cases for read-pacts:
# - shows help
# - extracts pact markers from explicit files

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

read_pacts_shows_help() {
  run_spell "spells/spellcraft/read-pacts" --help
  assert_success || return 1
  assert_output_contains "Usage: read-pacts" || return 1
}

read_pacts_extracts_markers() {
  tmpdir=$(make_tempdir)
  file=$tmpdir/spell
  cat >"$file" <<'EOF'
#!/bin/sh
set -eu
: pact publish-safely
: threshold imported-site-name
: seal publish "$site"
: enthrall release "$lock_dir"
: disenthrall release "$lock_dir"
EOF
  run_spell "spells/spellcraft/read-pacts" "$file"
  assert_success || return 1
  assert_output_contains "pact" || return 1
  assert_output_contains "publish-safely" || return 1
  assert_output_contains "threshold" || return 1
  assert_output_contains "seal" || return 1
  assert_output_contains "enthrall" || return 1
  assert_output_contains "disenthrall" || return 1
}

run_test_case "read-pacts shows help" read_pacts_shows_help
run_test_case "read-pacts extracts markers" read_pacts_extracts_markers

finish_tests
