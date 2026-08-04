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

installs_into_termux_prefix_without_devscripts() {
  skip-if-compiled || return $?
  fixture=$(make_fixture)
  prefix="$fixture/data/data/com.termux/files/usr"
  stub_dir="$fixture/bin"
  mkdir -p "$prefix/bin" "$stub_dir"

  cat <<'SCRIPT' >"$stub_dir/uname"
#!/bin/sh
printf '%s\n' Linux
SCRIPT
  cat <<'SCRIPT' >"$stub_dir/apt-get"
#!/bin/sh
printf '%s\n' "apt-get must not be used for Termux checkbashisms" >&2
exit 1
SCRIPT
  cat <<'SCRIPT' >"$stub_dir/sudo"
#!/bin/sh
printf '%s\n' "sudo must not be used for Termux checkbashisms" >&2
exit 1
SCRIPT
  cat <<'SCRIPT' >"$stub_dir/curl"
#!/bin/sh
output=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o) output=$2; shift 2 ;;
    *) shift ;;
  esac
done
[ -n "$output" ] || exit 1
cat <<'TOOL' >"$output"
#!/usr/bin/perl
exit 0;
TOOL
SCRIPT
  chmod +x "$stub_dir/uname" "$stub_dir/apt-get" "$stub_dir/sudo" "$stub_dir/curl"

  run_cmd env PATH="$stub_dir:$initial_path" PREFIX="$prefix" \
    INSTALL_CHECKBASHISMS_FORCE_INSTALL=1 \
    "$ROOT_DIR/spells/.arcana/core/install-checkbashisms"

  assert_success || return 1
  [ -x "$prefix/bin/checkbashisms" ] || {
    TEST_FAILURE_REASON="expected checkbashisms in the Termux prefix"
    return 1
  }
  first_line=$(sed -n '1p' "$prefix/bin/checkbashisms")
  [ "$first_line" = "#!/usr/bin/env perl" ] || {
    TEST_FAILURE_REASON="expected the downloaded Perl script to use Termux PATH"
    return 1
  }
  assert_output_contains "checkbashisms installed successfully from Debian sources." || return 1
}

run_test_case "install-checkbashisms exits when tool is present" creates_no_install_when_present
run_test_case "install-checkbashisms uses the Termux prefix" \
  installs_into_termux_prefix_without_devscripts
run_test_case "install-checkbashisms has content" spell_has_content


shows_help() {
  run_spell spells/.arcana/core/install-checkbashisms --help
  true
}

run_test_case "install-checkbashisms shows help" shows_help
finish_tests
