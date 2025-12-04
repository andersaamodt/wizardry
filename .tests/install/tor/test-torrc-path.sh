#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/tor/torrc-path" ]
}

run_test_case "install/tor/torrc-path is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/tor/torrc-path" ]
}

run_test_case "install/tor/torrc-path has content" spell_has_content

shows_help() {
  run_spell spells/install/tor/torrc-path --help
  true
}

run_test_case "torrc-path shows help" shows_help

prints_linux_default_when_not_arch() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/torrc-linux.XXXXXX")
  mkdir -p "$tmpdir/bin"
  cat >"$tmpdir/bin/uname" <<'STUB'
#!/bin/sh
printf 'Linux'
STUB
  cat >"$tmpdir/bin/cut" <<'STUB'
#!/bin/sh
tr ' ' '\n' | sed -n '1p'
STUB
  cat >"$tmpdir/bin/grep" <<'STUB'
#!/bin/sh
# Simulate no Arch Linux match
exit 1
STUB
  chmod +x "$tmpdir/bin"/*

  run_cmd sh -c "cut() { tr ' ' '\n' | sed -n '1p'; } ; PATH='$tmpdir/bin:/usr/bin:/bin:$PATH'; export PATH; exec '$ROOT_DIR'/spells/install/tor/torrc-path"
  assert_success || return 1
  assert_output_contains "/etc/tor/torrc"
}
run_test_case "torrc-path returns linux default for non-arch" prints_linux_default_when_not_arch

honors_arch_specific_path() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/torrc-arch.XXXXXX")
  mkdir -p "$tmpdir/bin"
  cat >"$tmpdir/bin/uname" <<'STUB'
#!/bin/sh
printf 'Linux'
STUB
  cat >"$tmpdir/bin/cut" <<'STUB'
#!/bin/sh
tr ' ' '\n' | sed -n '1p'
STUB
  cat >"$tmpdir/bin/grep" <<'STUB'
#!/bin/sh
# Pretend os-release contains Arch Linux
exit 0
STUB
  chmod +x "$tmpdir/bin"/*

  run_cmd sh -c "cut() { tr ' ' '\n' | sed -n '1p'; } ; PATH='$tmpdir/bin:/usr/bin:/bin:$PATH'; export PATH; exec '$ROOT_DIR'/spells/install/tor/torrc-path"
  assert_success || return 1
  assert_output_contains "/etc/tor/torrc"
}
run_test_case "torrc-path uses Arch location when detected" honors_arch_specific_path

finish_tests
