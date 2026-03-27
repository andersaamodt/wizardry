#!/bin/sh
# Behavioral cases:
# - doppelganger creates compiled wizardry clone
# - doppelganger --help shows usage
# - doppelganger uses default directory if none provided

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/spellcraft/doppelganger" --help
  assert_success && assert_output_contains "Usage:"
}

test_uses_default_directory() {
  run_spell "spells/spellcraft/doppelganger" --help
  assert_success || return 1
  assert_output_contains "default: ./wizardry-compiled"
}

test_creates_compiled_wizardry() {
  skip-if-compiled || return $?
  output_dir="$WIZARDRY_TMPDIR/doppelganger-output"
  stub_dir=$(make_tempdir)
  real_find=$(command -v find)

  # Limit doppelganger's spell scan to a tiny representative set so the
  # behavioral test stays under test-magic performance timeout.
  cat >"$stub_dir/find" <<STUB
#!/bin/sh
if [ "\$#" -gt 0 ] && [ "\$1" = "$ROOT_DIR/spells" ]; then
  printf '%s\n' "$ROOT_DIR/spells/arcane/copy"
  printf '%s\n' "$ROOT_DIR/spells/spellcraft/doppelganger"
  exit 0
fi
exec "$real_find" "\$@"
STUB
  chmod +x "$stub_dir/find"

  PATH="$stub_dir:$PATH" run_spell "spells/spellcraft/doppelganger" "$output_dir"
  assert_success || return 1
  assert_output_contains "Doppelganger created successfully" || return 1
  assert_output_contains "Compiled: 2 spells" || return 1
  assert_path_exists "$output_dir/spells" || return 1
  assert_path_exists "$output_dir/.tests" || return 1
  assert_path_exists "$output_dir/spells/arcane/copy" || return 1
  assert_path_exists "$output_dir/spells/spellcraft/doppelganger" || return 1
  assert_path_missing "$output_dir/.github" || return 1
  assert_path_missing "$output_dir/.git" || return 1
}

run_test_case "doppelganger prints usage" test_help
run_test_case "doppelganger uses default directory" test_uses_default_directory
run_test_case "doppelganger creates compiled wizardry" test_creates_compiled_wizardry


# Test via source-then-invoke pattern  

finish_tests
