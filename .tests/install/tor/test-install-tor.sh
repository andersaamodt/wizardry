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
  [ -x "$ROOT_DIR/spells/install/tor/install-tor" ]
}
run_test_case "install/tor/install-tor is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/tor/install-tor" ]
}
run_test_case "install/tor/install-tor has content" spell_has_content

shows_help() {
  run_spell spells/install/tor/install-tor --help
  true
}
run_test_case "install-tor shows help" shows_help

logs_apt_invocations_on_debian() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/tor-apt.XXXXXX")
  log="$tmpdir/log"
  mkdir -p "$tmpdir/bin"

  # Stubs
  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'debian'
STUB
  cat >"$tmpdir/bin/apt-get" <<'STUB'
#!/bin/sh
printf '%s\n' "$*" >>"${APT_LOG:?}"
STUB
  cat >"$tmpdir/bin/sudo" <<'STUB'
#!/bin/sh
exec "$@"
STUB
  cat >"$tmpdir/bin/systemctl" <<'STUB'
#!/bin/sh
if [ "$1" = "list-unit-files" ]; then
  # Skip enable prompt by pretending tor.service is absent
  exit 0
fi
printf 'systemctl %s\n' "$*" >>"${SYSTEMCTL_LOG:?}"
STUB
  chmod +x "$tmpdir/bin"/*

  APT_LOG="$log" SYSTEMCTL_LOG="$tmpdir/systemctl.log" PATH="$tmpdir/bin:$PATH" run_spell spells/install/tor/install-tor
  assert_success || return 1
  assert_file_contains "$log" "update"
  assert_file_contains "$log" "install -y tor"
}
run_test_case "install-tor installs via apt on debian" logs_apt_invocations_on_debian

falls_back_when_homebrew_missing() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/tor-mac.XXXXXX")
  mkdir -p "$tmpdir/bin"
  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'mac'
STUB
  chmod +x "$tmpdir/bin"/*

  PATH="$tmpdir/bin:$PATH" run_spell spells/install/tor/install-tor
  assert_failure || return 1
  assert_output_contains "Homebrew is required"
}
run_test_case "install-tor fails gracefully without brew" falls_back_when_homebrew_missing

fails_on_unsupported_distribution() {
  tmpdir=$(mktemp -d "${WIZARDRY_TMPDIR}/tor-unsupported.XXXXXX")
  mkdir -p "$tmpdir/bin"
  cat >"$tmpdir/bin/detect-distro" <<'STUB'
#!/bin/sh
printf 'solaris'
STUB
  chmod +x "$tmpdir/bin"/*

  PATH="$tmpdir/bin:$PATH" run_spell spells/install/tor/install-tor
  assert_failure || return 1
  assert_output_contains "Unsupported distribution"
}
run_test_case "install-tor reports unsupported platforms" fails_on_unsupported_distribution

finish_tests
