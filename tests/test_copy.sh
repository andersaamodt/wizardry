#!/bin/sh
# Behavioral cases (derived from --help):
# - copy requires an existing file
# - copy uses pbcopy when available
# - copy falls back to xsel and xclip
# - copy fails when no clipboard utility is present

set -eu

. "$(dirname "$0")/lib/test_common.sh"

copy_requires_existing_file() {
  run_spell "spells/copy" "$WIZARDRY_TMPDIR/nowhere.txt"
  assert_failure || return 1
  assert_output_contains "That file does not exist." || return 1
}

copy_uses_available_clipboard() {
  tmpdir=$(make_tempdir)
  file="$tmpdir/message.txt"
  printf 'hello world' >"$file"

  clipboard="$tmpdir/pbcopy.txt"
  stubdir="$tmpdir/stubs_pbcopy"
  mkdir -p "$stubdir"
  cat <<'STUB' >"$stubdir/pbcopy"
#!/bin/sh
cat >"${CLIPBOARD_FILE:?}" 
STUB
  chmod +x "$stubdir/pbcopy"

  PATH="$stubdir:$PATH" CLIPBOARD_FILE="$clipboard" run_spell "spells/copy" "$file"
  assert_success || return 1
  assert_output_contains "Copied $file to your clipboard." || return 1
  copied=$(cat "$clipboard")
  [ "$copied" = "hello world" ] || { TEST_FAILURE_REASON="clipboard did not receive contents"; return 1; }
}

copy_falls_back_to_xsel_and_xclip() {
  tmpdir=$(make_tempdir)
  file="$tmpdir/message.txt"
  printf 'hi there' >"$file"

  # xsel fallback
  xsel_dir="$tmpdir/stubs_xsel"
  mkdir -p "$xsel_dir"
  cat <<'STUB' >"$xsel_dir/xsel"
#!/bin/sh
cat >"${CLIPBOARD_FILE:?}" 
STUB
  chmod +x "$xsel_dir/xsel"

  clipboard="$tmpdir/xsel.txt"
  PATH="$xsel_dir:$PATH" CLIPBOARD_FILE="$clipboard" run_spell "spells/copy" "$file"
  assert_success || return 1
  [ "$(cat "$clipboard")" = "hi there" ] || { TEST_FAILURE_REASON="xsel stub not used"; return 1; }

  # xclip fallback when pbcopy and xsel missing
  xclip_dir="$tmpdir/stubs_xclip"
  mkdir -p "$xclip_dir"
  cat <<'STUB' >"$xclip_dir/xclip"
#!/bin/sh
cat >"${CLIPBOARD_FILE:?}" 
STUB
  chmod +x "$xclip_dir/xclip"

  clipboard="$tmpdir/xclip.txt"
  PATH="$xclip_dir:$PATH" CLIPBOARD_FILE="$clipboard" run_spell "spells/copy" "$file"
  assert_success || return 1
  [ "$(cat "$clipboard")" = "hi there" ] || { TEST_FAILURE_REASON="xclip stub not used"; return 1; }
}

copy_fails_without_clipboard_tools() {
  tmpdir=$(make_tempdir)
  file="$tmpdir/message.txt"
  printf 'spell' >"$file"

  PATH="$tmpdir:$PATH" run_spell "spells/copy" "$file"
  assert_failure || return 1
  assert_error_contains "Your spell fizzles." || return 1
}

run_test_case "copy requires an existing file" copy_requires_existing_file
run_test_case "copy uses pbcopy when available" copy_uses_available_clipboard
run_test_case "copy falls back to xsel and xclip" copy_falls_back_to_xsel_and_xclip
run_test_case "copy fails when no clipboard utility is present" copy_fails_without_clipboard_tools

finish_tests
