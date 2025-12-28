#!/bin/sh
# Ensure install-checkbashisms reports success when the tool already exists.

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

creates_no_install_when_present() {
  skip-if-compiled || return $?
  stub_dir=$(mktemp -d "${WIZARDRY_TMPDIR}/checkbashisms.present.XXXXXX") || return 1
  cat <<'SCRIPT' >"$stub_dir/checkbashisms"
#!/bin/sh
exit 0
SCRIPT
  chmod +x "$stub_dir/checkbashisms"
  PATH="$stub_dir:$PATH"
  export PATH

  run_cmd "$ROOT_DIR/spells/.arcana/core/install-checkbashisms"
  assert_success || return 1
  assert_output_contains "checkbashisms is already installed." || return 1
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/core/install-checkbashisms" ]
}

run_test_case "install-checkbashisms exits when tool is present" creates_no_install_when_present
run_test_case "install-checkbashisms has content" spell_has_content


shows_help() {
  run_spell spells/.arcana/core/install-checkbashisms --help
  true
}

run_test_case "install-checkbashisms shows help" shows_help
finish_tests
