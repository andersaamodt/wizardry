#!/bin/sh

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

shows_help() {
  run_cmd "$ROOT_DIR/spells/.arcana/mobile-debugging/install-maestro-cli" --help
  assert_success
  assert_output_contains "Usage: install-maestro-cli"
}

installs_maestro_into_xdg_root() {
  tmpdir=$(make_tempdir)
  maestro_root="$tmpdir/data/theurgy/mobile-debugging/maestro-cli/current"
  stub_dir="$tmpdir/bin"
  mkdir -p "$stub_dir"

  cat >"$stub_dir/curl" <<'SH'
#!/bin/sh
url=
output=
while [ $# -gt 0 ]; do
  case "$1" in
    -o)
      output=$2
      shift 2
      ;;
    --)
      shift
      [ $# -gt 0 ] && url=$1
      break
      ;;
    -*)
      shift
      ;;
    *)
      url=$1
      shift
      ;;
  esac
done

case "$url" in
  *releases/latest)
    cat "${MAESTRO_RELEASE_JSON:?}" >"${output:-/dev/stdout}"
    ;;
  *)
    cat "${MAESTRO_ARCHIVE_PAYLOAD:?}" >"${output:-/dev/stdout}"
    ;;
esac
SH
  chmod +x "$stub_dir/curl"

  cat >"$stub_dir/shasum" <<'SH'
#!/bin/sh
printf '%s  %s\n' "${MAESTRO_ARCHIVE_SHA:?}" "$3"
SH
  chmod +x "$stub_dir/shasum"

  cat >"$stub_dir/unzip" <<'SH'
#!/bin/sh
archive_file=$2
dest_dir=$4
mkdir -p "$dest_dir/maestro/bin"
cat >"$dest_dir/maestro/bin/maestro" <<'MAESTRO'
#!/bin/sh
exit 0
MAESTRO
chmod +x "$dest_dir/maestro/bin/maestro"
test -f "$archive_file"
exit 0
SH
  chmod +x "$stub_dir/unzip"

  release_json="$tmpdir/release.json"
  archive_payload="$tmpdir/maestro.zip"
  printf '{"tag_name":"cli-9.9.9","assets":[{"name":"maestro.zip","digest":"sha256:abc123","browser_download_url":"https://example.test/maestro.zip"}]}\n' >"$release_json"
  printf 'payload' >"$archive_payload"

  run_cmd env PATH="$stub_dir:$WIZARDRY_IMPS_PATH:/bin:/usr/bin" \
    XDG_DATA_HOME="$tmpdir/data" \
    MAESTRO_RELEASE_JSON="$release_json" \
    MAESTRO_ARCHIVE_PAYLOAD="$archive_payload" \
    MAESTRO_ARCHIVE_SHA="abc123" \
    "$ROOT_DIR/spells/.arcana/mobile-debugging/install-maestro-cli"

  assert_success || return 1
  assert_path_exists "$maestro_root/bin/maestro"
  assert_file_contains "$maestro_root/RELEASE_TAG" "cli-9.9.9"
}

run_test_case "install-maestro-cli shows help" shows_help
run_test_case "install-maestro-cli installs into XDG root" installs_maestro_into_xdg_root

finish_tests
