#!/bin/sh
# Ensure install-checkbashisms reports success when the tool already exists.

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

creates_no_install_when_present() {
  stub_dir=$(mktemp -d "${WIZARDRY_TMPDIR}/checkbashisms.present.XXXXXX") || return 1
  cat <<'SCRIPT' >"$stub_dir/checkbashisms"
#!/bin/sh
exit 0
SCRIPT
  chmod +x "$stub_dir/checkbashisms"
  PATH="$stub_dir:$PATH"
  export PATH

  run_cmd "$ROOT_DIR/spells/install/core/install-checkbashisms"
  assert_success || return 1
  assert_output_contains "checkbashisms is already installed." || return 1
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/core/install-checkbashisms" ]
}

run_test_case "install-checkbashisms exits when tool is present" creates_no_install_when_present
run_test_case "install-checkbashisms has content" spell_has_content


finish_tests
