#!/bin/sh
# Behavioral cases (derived from --help):
# - copy shows usage text
# - copy requires an existing file
# - copy refuses directories and missing targets
# - copy prefers pbcopy over other helpers
# - copy falls back to xsel and xclip
# - copy reports when no clipboard helper is present

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test_common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test_common.sh"

copy_shows_usage() {
  run_spell "spells/copy" --help
  assert_success || return 1
  assert_output_contains "Usage: copy" || return 1
}

copy_requires_existing_file() {
  run_spell "spells/copy" "$WIZARDRY_TMPDIR/nowhere.txt"
  assert_failure || return 1
  assert_output_contains "That file does not exist." || return 1
}

copy_rejects_directories_and_missing_target() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/dir"

  run_spell "spells/copy" "$tmpdir/dir"
  assert_failure || return 1
  assert_output_contains "That file does not exist." || return 1

  run_spell "spells/copy"
  assert_failure || return 1
  assert_output_contains "That file does not exist." || return 1
}

copy_prefers_pbcopy() {
  tmpdir=$(make_tempdir)
  file="$tmpdir/message.txt"
  printf 'hello world' >"$file"

  clipboard="$tmpdir/pbcopy.txt"
  stubdir="$tmpdir/stubs"
  mkdir -p "$stubdir"

  cat <<'STUB' >"$stubdir/pbcopy"
#!/bin/sh
cat >"${CLIPBOARD_FILE:?}"
STUB
  cat <<'STUB' >"$stubdir/xsel"
#!/bin/sh
echo "xsel should not run" >&2
exit 64
STUB
  cat <<'STUB' >"$stubdir/xclip"
#!/bin/sh
echo "xclip should not run" >&2
exit 64
STUB
  chmod +x "$stubdir"/pbcopy "$stubdir"/xsel "$stubdir"/xclip

  PATH="$stubdir:$PATH" CLIPBOARD_FILE="$clipboard" run_spell "spells/copy" "$file"
  assert_success || return 1
  assert_output_contains "Copied $file to your clipboard." || return 1
  [ "$(cat "$clipboard")" = "hello world" ] || { TEST_FAILURE_REASON="pbcopy stub not used"; return 1; }
}

copy_uses_xsel_when_available() {
  tmpdir=$(make_tempdir)
  file="$tmpdir/message.txt"
  printf 'hi there' >"$file"

  clipboard="$tmpdir/xsel.txt"
  stubdir="$tmpdir/stubs_xsel"
  mkdir -p "$stubdir"

  cat <<'STUB' >"$stubdir/xsel"
#!/bin/sh
cat >"${CLIPBOARD_FILE:?}"
STUB
  chmod +x "$stubdir/xsel"

  PATH="$stubdir:$PATH" CLIPBOARD_FILE="$clipboard" run_spell "spells/copy" "$file"
  assert_success || return 1
  [ "$(cat "$clipboard")" = "hi there" ] || { TEST_FAILURE_REASON="xsel stub not used"; return 1; }
}

copy_uses_xclip_when_others_missing() {
  tmpdir=$(make_tempdir)
  file="$tmpdir/message more.txt"
  printf 'clipboard ready' >"$file"

  clipboard="$tmpdir/xclip.txt"
  stubdir="$tmpdir/stubs_xclip"
  mkdir -p "$stubdir"

  cat <<'STUB' >"$stubdir/xclip"
#!/bin/sh
cat >"${CLIPBOARD_FILE:?}"
STUB
  chmod +x "$stubdir/xclip"

  PATH="$stubdir:$PATH" CLIPBOARD_FILE="$clipboard" run_spell "spells/copy" "$file"
  assert_success || return 1
  assert_output_contains "Copied $file to your clipboard." || return 1
  [ "$(cat "$clipboard")" = "clipboard ready" ] || { TEST_FAILURE_REASON="xclip stub not used"; return 1; }
}

copy_prefers_xsel_over_xclip() {
  tmpdir=$(make_tempdir)
  file="$tmpdir/prioritized.txt"
  printf 'ordered' >"$file"

  clipboard="$tmpdir/clipboard.txt"
  stubdir="$tmpdir/stubs_xsel_first"
  mkdir -p "$stubdir"

  cat <<'STUB' >"$stubdir/xsel"
#!/bin/sh
cat >"${CLIPBOARD_FILE:?}"
STUB
  cat <<'STUB' >"$stubdir/xclip"
#!/bin/sh
echo "xclip should not be reached" >&2
exit 77
STUB
  chmod +x "$stubdir/xsel" "$stubdir/xclip"

  PATH="$stubdir:$PATH" CLIPBOARD_FILE="$clipboard" run_spell "spells/copy" "$file"
  assert_success || return 1
  [ "$(cat "$clipboard")" = "ordered" ] || { TEST_FAILURE_REASON="xsel stub not used"; return 1; }
  case ${ERROR:-} in
    *"xclip should not be reached"*) TEST_FAILURE_REASON="xclip unexpectedly executed"; return 1 ;;
  esac
}

copy_fails_without_clipboard_tools() {
  tmpdir=$(make_tempdir)
  file="$tmpdir/message.txt"
  printf 'spell' >"$file"

  PATH="$tmpdir:$PATH" run_spell "spells/copy" "$file"
  assert_failure || return 1
  assert_error_contains "Your spell fizzles." || return 1
}

copy_reports_success_with_path() {
  tmpdir=$(make_tempdir)
  file="$tmpdir/file with space.txt"
  printf 'echo' >"$file"

  clipboard="$tmpdir/output.txt"
  stubdir="$tmpdir/stubs_message"
  mkdir -p "$stubdir"
  cat <<'STUB' >"$stubdir/pbcopy"
#!/bin/sh
cat >"${CLIPBOARD_FILE:?}"
STUB
  chmod +x "$stubdir/pbcopy"

  PATH="$stubdir:$PATH" CLIPBOARD_FILE="$clipboard" run_spell "spells/copy" "$file"
  assert_success || return 1
  assert_output_contains "Copied $file to your clipboard." || return 1
  [ "$(cat "$clipboard")" = "echo" ] || { TEST_FAILURE_REASON="clipboard contents unexpected"; return 1; }
}

run_test_case "copy shows usage text" copy_shows_usage
run_test_case "copy requires an existing file" copy_requires_existing_file
run_test_case "copy rejects directories and missing target" copy_rejects_directories_and_missing_target
run_test_case "copy prefers pbcopy when available" copy_prefers_pbcopy
run_test_case "copy falls back to xsel" copy_uses_xsel_when_available
run_test_case "copy falls back to xclip when others are missing" copy_uses_xclip_when_others_missing
run_test_case "copy prefers xsel over xclip" copy_prefers_xsel_over_xclip
run_test_case "copy fails when no clipboard utility is present" copy_fails_without_clipboard_tools
run_test_case "copy reports success message with original path" copy_reports_success_with_path

finish_tests
