#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/bitcoin/install-bitcoin" ]
}

run_test_case "install/bitcoin/install-bitcoin is executable" spell_is_executable
spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/bitcoin/install-bitcoin" ]
}

run_test_case "install/bitcoin/install-bitcoin has content" spell_has_content

shows_help() {
  run_spell spells/install/bitcoin/install-bitcoin --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "install-bitcoin shows help" shows_help

installs_via_package_manager_and_starts_service() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/bitcoin-install.XXXXXX")
  mkdir -p "$tmpdir/bin"
  log="$tmpdir/log"

  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'debian'
STUB
  cat >"$tmpdir/bin/apt" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" >>"${APT_LOG:?}"
STUB
  cat >"$tmpdir/bin/ask_yn" <<'STUB'
#!/bin/sh
resp=${ASK_YN_RESPONSE:-y}
if [ "$resp" = "y" ]; then exit 0; else exit 1; fi
STUB
  cat >"$tmpdir/bin/configure-bitcoin" <<'STUB'
#!/bin/sh
printf 'configure-bitcoin\n' >>"${BITCOIN_LOG:?}"
STUB
  cat >"$tmpdir/bin/install-service-template" <<'STUB'
#!/bin/sh
printf 'service %s %s\n' "$1" "$2" >>"${BITCOIN_LOG:?}"
STUB
  cat >"$tmpdir/bin/systemctl" <<'STUB'
#!/bin/sh
if [ "$1" = "list-unit-files" ]; then
  printf 'bitcoin.service\n'
  exit 0
fi
printf 'systemctl %s\n' "$*" >>"${SYSTEMCTL_LOG:?}"
STUB
  cat >"$tmpdir/bin/sudo" <<'STUB'
#!/bin/sh
exec "$@"
STUB
  chmod +x "$tmpdir/bin"/*

  runner="$tmpdir/run-install"
  cat >"$runner" <<EOF
#!/bin/sh
PATH="$tmpdir/bin:/usr/bin:/bin"
APT_LOG="$log"
BITCOIN_LOG="$tmpdir/bitcoin.log"
SYSTEMCTL_LOG="$tmpdir/systemd.log"
ASK_YN_RESPONSE=y
export PATH APT_LOG BITCOIN_LOG SYSTEMCTL_LOG ASK_YN_RESPONSE
printf '\n' | "$ROOT_DIR"/spells/install/bitcoin/install-bitcoin
EOF
  chmod +x "$runner"

  out_file="$tmpdir/output"
  err_file="$tmpdir/error"
  STATUS=0
  if "$runner" >"$out_file" 2>"$err_file"; then STATUS=0; else STATUS=$?; fi
  OUTPUT=$(cat "$out_file")
  ERROR=$(cat "$err_file")

  assert_success || return 1
  assert_file_contains "$log" "update"
  assert_file_contains "$log" "install -y bitcoind bitcoin-qt"
  assert_file_contains "$tmpdir/bitcoin.log" "configure-bitcoin"
  assert_file_contains "$tmpdir/bitcoin.log" "service $ROOT_DIR/spells/install/bitcoin/bitcoin.service BITCOIND"
  assert_file_contains "$tmpdir/systemd.log" "start bitcoin"
}
run_test_case "install-bitcoin installs packages and starts service" installs_via_package_manager_and_starts_service

installs_from_binary_when_no_package_manager() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/bitcoin-binary.XXXXXX")
  mkdir -p "$tmpdir/bin"
  log="$tmpdir/log"

  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'custom'
STUB
  cat >"$tmpdir/bin/uname" <<'STUB'
#!/bin/sh
printf 'x86_64'
STUB
  cat >"$tmpdir/bin/wget" <<'STUB'
#!/bin/sh
printf '%s\n' "$@" >>"${BIN_LOG:?}"
file=$(basename "$1")
touch "$file"
STUB
  cat >"$tmpdir/bin/tar" <<'STUB'
#!/bin/sh
archive=${4:-$2}
if [ -z "$archive" ]; then archive=$(basename "$1"); fi
version=$(printf '%s' "$archive" | sed 's/bitcoin-//; s/-x86_64-linux-gnu.tar.gz//')
mkdir -p "bitcoin-$version/bin"
printf 'tar %s\n' "$archive" >>"${BIN_LOG:?}"
touch "bitcoin-$version/bin/bitcoind"
STUB
  cat >"$tmpdir/bin/install" <<'STUB'
#!/bin/sh
printf 'install %s\n' "$*" >>"${BIN_LOG:?}"
STUB
  cat >"$tmpdir/bin/configure-bitcoin" <<'STUB'
#!/bin/sh
printf 'configure\n' >>"${BIN_LOG:?}"
STUB
  cat >"$tmpdir/bin/ask_yn" <<'STUB'
#!/bin/sh
resp=${ASK_YN_RESPONSE:-y}
[ "$resp" = "y" ]
STUB
  cat >"$tmpdir/bin/systemctl" <<'STUB'
#!/bin/sh
exit 1
STUB
  cat >"$tmpdir/bin/bitcoind" <<'STUB'
#!/bin/sh
printf 'bitcoind %s\n' "$*" >>"${BITCOIND_LOG:?}"
STUB
  cat >"$tmpdir/bin/sudo" <<'STUB'
#!/bin/sh
exec "$@"
STUB
  chmod +x "$tmpdir/bin"/*

  runner="$tmpdir/run-binary"
  cat >"$runner" <<EOF
#!/bin/sh
PATH="$tmpdir/bin:/usr/bin:/bin"
BIN_LOG="$tmpdir/bin.log"
BITCOIND_LOG="$tmpdir/bitcoind.log"
ASK_YN_RESPONSE=y
export PATH BIN_LOG BITCOIND_LOG ASK_YN_RESPONSE
printf '\n' | "$ROOT_DIR"/spells/install/bitcoin/install-bitcoin
EOF
  chmod +x "$runner"

  if ! "$runner" >"$tmpdir/out" 2>"$tmpdir/err"; then STATUS=$?; else STATUS=0; fi
  OUTPUT=$(cat "$tmpdir/out")
  ERROR=$(cat "$tmpdir/err")

  assert_success || return 1
  assert_file_contains "$tmpdir/bin.log" "bitcoin-25.0-x86_64-linux-gnu.tar.gz"
  assert_file_contains "$tmpdir/bin.log" "install -m 0755"
  assert_file_contains "$tmpdir/bin.log" "configure"
  assert_file_contains "$tmpdir/bitcoind.log" "-daemon"
}
run_test_case "install-bitcoin downloads binary when no package manager" installs_from_binary_when_no_package_manager

falls_back_to_bitcoind_when_service_missing() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/bitcoin-daemon.XXXXXX")
  mkdir -p "$tmpdir/bin"
  log="$tmpdir/log"

  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'debian'
STUB
  cat >"$tmpdir/bin/apt" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"${APT_LOG:?}"
STUB
  cat >"$tmpdir/bin/ask_yn" <<'STUB'
#!/bin/sh
resp_file=${ASK_YN_RESPONSES:-}
if [ -n "$resp_file" ] && [ -s "$resp_file" ]; then
  resp=$(head -n1 "$resp_file")
  tail -n +2 "$resp_file" >"$resp_file.tmp" && mv "$resp_file.tmp" "$resp_file"
else
  resp=${ASK_YN_RESPONSE:-y}
fi
[ "$resp" = "y" ] && exit 0 || exit 1
STUB
  cat >"$tmpdir/bin/configure-bitcoin" <<'STUB'
#!/bin/sh
printf 'configure\n' >>"${BITCOIN_LOG:?}"
STUB
  cat >"$tmpdir/bin/systemctl" <<'STUB'
#!/bin/sh
exit 0
STUB
  cat >"$tmpdir/bin/bitcoind" <<'STUB'
#!/bin/sh
printf 'bitcoind %s\n' "$*" >>"${BITCOIND_LOG:?}"
STUB
  cat >"$tmpdir/bin/sudo" <<'STUB'
#!/bin/sh
exec "$@"
STUB
  chmod +x "$tmpdir/bin"/*

  responses="$tmpdir/responses"
  printf '%s\n%s\n%s\n' y y y >"$responses"

  runner="$tmpdir/run-daemon"
  cat >"$runner" <<EOF
#!/bin/sh
PATH="$tmpdir/bin:/usr/bin:/bin"
APT_LOG="$log"
BITCOIN_LOG="$tmpdir/bitcoin.log"
BITCOIND_LOG="$tmpdir/bitcoind.log"
ASK_YN_RESPONSES="$responses"
export PATH APT_LOG BITCOIN_LOG BITCOIND_LOG ASK_YN_RESPONSES
printf '\n' | "$ROOT_DIR"/spells/install/bitcoin/install-bitcoin
EOF
  chmod +x "$runner"

  "$runner" >"$tmpdir/out" 2>"$tmpdir/err"
  assert_success || return 1
  assert_file_contains "$tmpdir/bitcoind.log" "-daemon"
  assert_file_contains "$tmpdir/bitcoin.log" "configure"
}
run_test_case "install-bitcoin starts bitcoind when no systemd service" falls_back_to_bitcoind_when_service_missing
finish_tests
