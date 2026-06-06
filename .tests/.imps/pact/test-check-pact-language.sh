#!/bin/sh
# Behavioral cases for check-pact-language:
# - accepts balanced pact markers
# - rejects unknown primitives after a pact begins
# - rejects unfulfilled promises
# - rejects transgressions without a preceding taboo

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

pact_checker_accepts_balanced_markers() {
  tmpdir=$(make_tempdir)
  file=$tmpdir/good
  cat >"$file" <<'EOF'
#!/bin/sh
set -eu
: pact publish-safely
: threshold imported-site-name
: essence site-name "$site_name"
: divine site-name "$site_name"
: taboo remote-shell
: transgress remote-shell quoted-argv host-allowlisted
: promise cleanse-stage "$stage_dir"
: fulfill cleanse-stage "$stage_dir"
EOF
  run_spell "spells/.imps/pact/check-pact-language" "$file"
  assert_success || return 1
}

pact_checker_rejects_unknown_after_pact() {
  tmpdir=$(make_tempdir)
  file=$tmpdir/bad
  cat >"$file" <<'EOF'
#!/bin/sh
set -eu
: pact publish-safely
: warrent remote-shell
EOF
  run_spell "spells/.imps/pact/check-pact-language" "$file"
  assert_failure || return 1
  assert_output_contains "unknown pact primitive: warrent" || return 1
}

pact_checker_rejects_unfulfilled_promise() {
  tmpdir=$(make_tempdir)
  file=$tmpdir/bad
  cat >"$file" <<'EOF'
#!/bin/sh
set -eu
: pact release-safely
: promise cleanse-stage "$stage_dir"
EOF
  run_spell "spells/.imps/pact/check-pact-language" "$file"
  assert_failure || return 1
  assert_output_contains "promise is not fulfilled or released: cleanse-stage" || return 1
}

pact_checker_rejects_unprepared_transgression() {
  tmpdir=$(make_tempdir)
  file=$tmpdir/bad
  cat >"$file" <<'EOF'
#!/bin/sh
set -eu
: pact publish-safely
: transgress remote-shell quoted-argv
EOF
  run_spell "spells/.imps/pact/check-pact-language" "$file"
  assert_failure || return 1
  assert_output_contains "transgress appears before matching taboo: remote-shell" || return 1
}

run_test_case "pact checker accepts balanced markers" pact_checker_accepts_balanced_markers
run_test_case "pact checker rejects unknown primitives" pact_checker_rejects_unknown_after_pact
run_test_case "pact checker rejects unfulfilled promises" pact_checker_rejects_unfulfilled_promise
run_test_case "pact checker rejects unprepared transgressions" pact_checker_rejects_unprepared_transgression

finish_tests
