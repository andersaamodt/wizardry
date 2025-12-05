#!/bin/sh
# Behavioral cases (derived from --help):
# - copy shows usage text
# - copy requires an existing file
# - copy refuses directories and missing targets
# - copy prefers pbcopy over other helpers
# - copy falls back to xsel and xclip
# - copy reports when no clipboard helper is present

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

copy_shows_usage() {
  run_spell "spells/arcane/copy" --help
  assert_success || return 1
  assert_output_contains "Usage: copy" || return 1
}

copy_requires_existing_file() {
  run_spell "spells/arcane/copy" "$WIZARDRY_TMPDIR/nowhere.txt"
  assert_failure || return 1
  assert_output_contains "That file does not exist." || return 1
}

copy_rejects_directories_and_missing_target() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/dir"

  run_spell "spells/arcane/copy" "$tmpdir/dir"
  assert_failure || return 1
  assert_output_contains "That file does not exist." || return 1

  run_spell "spells/arcane/copy"
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

  PATH="$stubdir:$PATH" CLIPBOARD_FILE="$clipboard" run_spell "spells/arcane/copy" "$file"
  assert_success || return 1
  # Normalize path for macOS compatibility (TMPDIR ends with /)
  normalized_file=$(printf '%s' "$file" | sed 's|//|/|g')
  assert_output_contains "Copied $normalized_file to your clipboard." || return 1
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

  # Create symlinks to essential utilities in stub directory to avoid finding pbcopy
  for util in sh sed cat printf test env basename dirname; do
    if command -v "$util" >/dev/null 2>&1; then
      util_path=$(command -v "$util")
      ln -sf "$util_path" "$stubdir/$util" 2>/dev/null || true
    fi
  done

  # Use a restricted PATH with just our stubs (no system paths that might have pbcopy)
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/sys:$stubdir" CLIPBOARD_FILE="$clipboard" run_spell "spells/arcane/copy" "$file"
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

  # Create symlinks to essential utilities in stub directory to avoid finding pbcopy or xsel
  for util in sh sed cat printf test env basename dirname; do
    if command -v "$util" >/dev/null 2>&1; then
      util_path=$(command -v "$util")
      ln -sf "$util_path" "$stubdir/$util" 2>/dev/null || true
    fi
  done

  # Use a restricted PATH with just our stubs (no system paths that might have pbcopy or xsel)
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/sys:$stubdir" CLIPBOARD_FILE="$clipboard" run_spell "spells/arcane/copy" "$file"
  assert_success || return 1
  # Normalize the expected path to match what copy outputs
  file_normalized=$(printf '%s' "$file" | sed 's|//|/|g')
  assert_output_contains "Copied $file_normalized to your clipboard." || return 1
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

  # Create symlinks to essential utilities in stub directory to avoid finding pbcopy
  for util in sh sed cat printf test env basename dirname; do
    if command -v "$util" >/dev/null 2>&1; then
      util_path=$(command -v "$util")
      ln -sf "$util_path" "$stubdir/$util" 2>/dev/null || true
    fi
  done

  # Use a restricted PATH with just our stubs (no system paths that might have pbcopy)
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/sys:$stubdir" CLIPBOARD_FILE="$clipboard" run_spell "spells/arcane/copy" "$file"
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

  stubdir="$tmpdir/stubs_none"
  mkdir -p "$stubdir"

  # Create symlinks to essential utilities but no clipboard tools
  for util in sh sed cat printf test env basename dirname; do
    if command -v "$util" >/dev/null 2>&1; then
      util_path=$(command -v "$util")
      ln -sf "$util_path" "$stubdir/$util" 2>/dev/null || true
    fi
  done

  # Use a PATH with just essential utilities (no clipboard tools like pbcopy, xsel, xclip)
  PATH="$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/sys:$stubdir" run_spell "spells/arcane/copy" "$file"
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

  PATH="$stubdir:$PATH" CLIPBOARD_FILE="$clipboard" run_spell "spells/arcane/copy" "$file"
  assert_success || return 1
  # Normalize path for macOS compatibility (TMPDIR ends with /)
  normalized_file=$(printf '%s' "$file" | sed 's|//|/|g')
  assert_output_contains "Copied $normalized_file to your clipboard." || return 1
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
