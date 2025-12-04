#!/bin/sh
set -eu

# Locate repo root
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/tor/configure-tor" ]
}
run_test_case "install/tor/configure-tor is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/tor/configure-tor" ]
}
run_test_case "install/tor/configure-tor has content" spell_has_content

shows_help() {
  run_spell spells/install/tor/configure-tor --help
  true
}
run_test_case "configure-tor shows help" shows_help

rewrites_torrc_with_new_ports() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/configure-tor.XXXXXX")
  mkdir -p "$tmpdir/bin"
  torrc="$tmpdir/torrc"
  printf 'SocksPort 9000\nControlPort 9001\nCookieAuthentication 1\n' >"$torrc"

  cat >"$tmpdir/bin/torrc-path" <<'STUB'
#!/bin/sh
printf '%s/torrc' "${TORRC_DIR:?}"
STUB
  cat >"$tmpdir/bin/systemctl" <<'STUB'
#!/bin/sh
if [ "$1" = "list-unit-files" ]; then
  printf 'tor.service\n'
  exit 0
fi
printf '%s\n' "$*" >>"${SYSTEMCTL_LOG:?}"
STUB
  cat >"$tmpdir/bin/sudo" <<'STUB'
#!/bin/sh
exec "$@"
STUB
  chmod +x "$tmpdir/bin"/*

  runner="$tmpdir/run-configure"
  cat >"$runner" <<EOF
#!/bin/sh
PATH="$tmpdir/bin:$PATH"
TORRC_DIR="$tmpdir"
SYSTEMCTL_LOG="$tmpdir/systemctl.log"
export TORRC_DIR SYSTEMCTL_LOG PATH
printf '9055\ny\n9056\ny\n' | "$ROOT_DIR"/spells/install/tor/configure-tor
EOF
  chmod +x "$runner"

  out_file="$tmpdir/output"
  err_file="$tmpdir/error"
  STATUS=0
  if "$runner" >"$out_file" 2>"$err_file"; then STATUS=0; else STATUS=$?; fi
  OUTPUT=$(cat "$out_file")
  ERROR=$(cat "$err_file")

  assert_success || return 1
  assert_file_contains "$torrc" "SocksPort 9055"
  assert_file_contains "$torrc" "ControlPort 9056"
  assert_file_contains "$torrc" "CookieAuthentication 1"
  assert_file_contains "$tmpdir/systemctl.log" "restart tor"
}
run_test_case "configure-tor rewrites torrc and restarts tor" rewrites_torrc_with_new_ports

finish_tests
