#!/bin/sh
# Common test helpers for simple POSIX shell tests.
# Provides minimal assertion helpers and a lightweight test runner.

set -eu

find_repo_root() {
  dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/spells" ] && [ -d "$dir/tests" ]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  printf '%s\n' "$(pwd -P)"
}

ROOT_DIR=$(find_repo_root)
initial_path=$PATH
PATH="$ROOT_DIR/spells"
for dir in "$ROOT_DIR"/spells/*; do
  [ -d "$dir" ] || continue
  PATH="$PATH:$dir"
done
PATH="$PATH:$initial_path"
export PATH
WIZARDRY_TEST_HELPERS_ONLY=1
export WIZARDRY_TEST_HELPERS_ONLY

: "${WIZARDRY_TMPDIR:=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")}" || exit 1
export WIZARDRY_TMPDIR

BWRAP_AVAILABLE=1
BWRAP_VIA_SUDO=0
BWRAP_USE_UNSHARE=1
BWRAP_BIN=${BWRAP_BIN-}

if [ -z "$BWRAP_BIN" ]; then
  if command -v bwrap >/dev/null 2>&1; then
    BWRAP_BIN=$(command -v bwrap)
  else
    BWRAP_AVAILABLE=0
    BWRAP_REASON="bubblewrap not installed"
  fi
fi

if [ "$BWRAP_AVAILABLE" -eq 1 ]; then
  if "$BWRAP_BIN" --unshare-user-try --ro-bind / / /bin/true 2>/dev/null; then
    :
  elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    if sudo -n "$BWRAP_BIN" --unshare-user-try --ro-bind / / /bin/true 2>/dev/null; then
      BWRAP_VIA_SUDO=1
    elif sudo -n "$BWRAP_BIN" --ro-bind / / /bin/true 2>/dev/null; then
      BWRAP_VIA_SUDO=1
      BWRAP_USE_UNSHARE=0
    else
      BWRAP_AVAILABLE=0
      BWRAP_REASON="bubblewrap unusable even via sudo"
    fi
  else
    BWRAP_AVAILABLE=0
    BWRAP_REASON="bubblewrap unusable (user namespaces likely disabled)"
  fi
fi

warn_once_file=${WIZARDRY_BWRAP_WARN_FILE-${TMPDIR:-/tmp}/wizardry-bwrap-warning}

if [ "$BWRAP_AVAILABLE" -eq 1 ] && { [ -z "$BWRAP_BIN" ] || [ ! -x "$BWRAP_BIN" ]; }; then
  BWRAP_AVAILABLE=0
  BWRAP_REASON="bubblewrap not installed"
fi

if [ "$BWRAP_AVAILABLE" -eq 0 ] && [ ! -f "$warn_once_file" ] && [ "${WIZARDRY_BWRAP_WARNING-0}" -eq 0 ]; then
  printf '%s\n' "WARNING: proceeding without bubblewrap sandbox: $BWRAP_REASON" >&2
  WIZARDRY_BWRAP_WARNING=1
  export WIZARDRY_BWRAP_WARNING
  : >"$warn_once_file" 2>/dev/null || true
fi

run_bwrap() {
  if [ "$BWRAP_VIA_SUDO" -eq 1 ]; then
    sudo -n "$BWRAP_BIN" "$@"
  else
    "$BWRAP_BIN" "$@"
  fi
}

_pass_count=0
_fail_count=0
_test_index=0
_fail_detail_indices=""

# Record the result of a test case with a human-friendly label.
report_result() {
  desc=$1
  status=$2
  reason=${3-}
  if [ "$status" -eq 0 ]; then
    _pass_count=$((_pass_count + 1))
    printf 'PASS %s\n' "$desc"
  else
    _fail_count=$((_fail_count + 1))
    if [ -n "$reason" ]; then
      printf 'FAIL %s: %s\n' "$desc" "$reason"
    else
      printf 'FAIL %s\n' "$desc"
    fi
  fi
}

# Run a named test case function and report its result.
run_test_case() {
  desc=$1
  func=$2
  _test_index=$((_test_index + 1))
  if "$func"; then
    report_result "$desc" 0
  else
    reason=${TEST_FAILURE_REASON-}
    report_result "$desc" 1 "$reason"
    record_failure_detail "$_test_index"
    unset TEST_FAILURE_REASON || true
  fi
}

record_failure_detail() {
  idx=$1

  _fail_detail_indices=$(printf '%s\n%s\n' "$_fail_detail_indices" "$idx" |
    awk 'NF { if (!seen[$0]++) { order[++count]=$0 } }
         END { for (i=1; i<=count; i++) { if (i>1) printf(","); printf order[i] } }')
}

finish_tests() {
  total=$((_pass_count + _fail_count))
  printf '%s/%s tests passed' "$_pass_count" "$total"
  if [ "$_fail_count" -gt 0 ]; then
    printf ' (%s failed)\n' "$_fail_count"
    if [ -n "$_fail_detail_indices" ]; then
      printf 'FAIL_DETAIL:%s\n' "$_fail_detail_indices"
    fi
    return 1
  fi
  printf '\n'
  return 0
}

# Capture a command's stdout, stderr, and exit status inside a bubblewrap
# sandbox. Results land in STATUS, OUTPUT, and ERROR variables.
run_cmd() {
  __stdout=$(mktemp "${WIZARDRY_TMPDIR}/stdout.XXXXXX") || return 1
  __stderr=$(mktemp "${WIZARDRY_TMPDIR}/stderr.XXXXXX") || return 1

  workdir=${RUN_CMD_WORKDIR:-$(pwd)}
  mkdir -p "$workdir"

  sandbox=$(mktemp -d "${WIZARDRY_TMPDIR}/sandbox.XXXXXX") || return 1
  tmpdir="$sandbox/tmp"
  homedir="$sandbox/home"
  mkdir -p "$tmpdir" "$homedir"

    if [ "$BWRAP_AVAILABLE" -eq 1 ]; then
      set -- \
        --die-with-parent \
        --ro-bind / / \
        --dev-bind /dev /dev \
        --bind /proc /proc \
      --tmpfs /tmp \
      --bind "$WIZARDRY_TMPDIR" "$WIZARDRY_TMPDIR" \
      --ro-bind "$ROOT_DIR" "$ROOT_DIR" \
      --chdir "$workdir" \
        --setenv PATH "$PATH" \
        --setenv HOME "$homedir" \
        --setenv TMPDIR "$tmpdir" \
        --setenv WIZARDRY_TMPDIR "$WIZARDRY_TMPDIR" \
        --setenv WIZARDRY_TEST_HELPERS_ONLY "${WIZARDRY_TEST_HELPERS_ONLY-}" \
        -- "$@"

    if [ "$BWRAP_USE_UNSHARE" -eq 1 ]; then
      set -- --unshare-user-try "$@"
    fi

    if run_bwrap "$@" >"$__stdout" 2>"$__stderr"; then
      STATUS=0
    else
      STATUS=$?
    fi
  else
    if (cd "$workdir" && env PATH="$PATH" HOME="$homedir" TMPDIR="$tmpdir" WIZARDRY_TMPDIR="$WIZARDRY_TMPDIR" "$@" \
      >"$__stdout" 2>"$__stderr"); then
      STATUS=0
    else
      STATUS=$?
    fi
  fi

  OUTPUT=$(cat "$__stdout")
  ERROR=$(cat "$__stderr")
  rm -f "$__stdout" "$__stderr"
  rm -rf "$sandbox"
}

run_spell() {
  script=$1
  shift || true
  run_cmd "$ROOT_DIR/$script" "$@"
}

run_spell_in_dir() {
  dir=$1
  shift
  RUN_CMD_WORKDIR=$dir run_spell "$@"
}

assert_status() {
  expected_status=$1
  if [ "$STATUS" -ne "$expected_status" ]; then
    if [ -n "${ERROR-}" ]; then
      TEST_FAILURE_REASON="expected status $expected_status but got $STATUS; stderr: $ERROR"
    else
      TEST_FAILURE_REASON="expected status $expected_status but got $STATUS"
    fi
    return 1
  fi
  return 0
}

assert_success() { assert_status 0; }

assert_failure() {
  if [ "$STATUS" -eq 0 ]; then
    TEST_FAILURE_REASON="expected failure status but got success"
    return 1
  fi
  return 0
}

assert_output_contains() {
  substring=$1
  case "$OUTPUT" in
    *"$substring"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="output missing substring: $substring"
      return 1
      ;;
  esac
}

assert_error_contains() {
  substring=$1
  case "$ERROR" in
    *"$substring"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="stderr missing substring: $substring"
      return 1
      ;;
  esac
}

assert_file_contains() {
  file=$1
  substring=$2
  if [ ! -f "$file" ]; then
    TEST_FAILURE_REASON="expected file missing: $file"
    return 1
  fi

  if grep -F -- "$substring" "$file" >/dev/null 2>&1; then
    return 0
  fi

  TEST_FAILURE_REASON="file $file missing substring: $substring"
  return 1
}

assert_path_exists() {
  if [ ! -e "$1" ]; then
    TEST_FAILURE_REASON="expected path to exist: $1"
    return 1
  fi
  return 0
}

assert_path_missing() {
  if [ -e "$1" ]; then
    TEST_FAILURE_REASON="expected path to be absent: $1"
    return 1
  fi
  return 0
}

make_tempdir() {
  mktemp -d "${WIZARDRY_TMPDIR}/case.XXXXXX"
}

# --- Core install test helpers ---

make_fixture() {
  fixture=$(make_tempdir)
  mkdir -p "$fixture/bin" "$fixture/log" "$fixture/home/.local/bin"
  printf '%s\n' "$fixture"
}

write_apt_stub() {
  fixture=$1
  cat <<'STUB' >"$fixture/bin/apt-get"
#!/bin/sh
echo "$0 $*" >>"${APT_LOG:?}" || exit 1
exit ${APT_EXIT:-0}
STUB
  chmod +x "$fixture/bin/apt-get"
}

write_sudo_stub() {
  fixture=$1
  cat <<'STUB' >"$fixture/bin/sudo"
#!/bin/sh
exec "$@"
STUB
  chmod +x "$fixture/bin/sudo"
}

write_command_stub() {
  dir=$1
  name=$2
  cat <<'STUB' >"$dir/$name"
#!/bin/sh
exit 0
STUB
  chmod +x "$dir/$name"
}

write_pkgin_stub() {
  fixture=$1
  mkdir -p "$fixture/opt/pkg/bin"
  cat <<'STUB' >"$fixture/opt/pkg/bin/pkgin"
#!/bin/sh
if [ "$1" = "-y" ] && [ "$2" = "install" ]; then
  shift 2
  printf 'pkgin install %s\n' "$*" >>"${PKGIN_LOG:?}" || exit 1
  exit ${PKGIN_EXIT:-0}
fi

if [ "$1" = "-y" ] && [ "$2" = "remove" ]; then
  shift 2
  printf 'pkgin remove %s\n' "$*" >>"${PKGIN_LOG:?}" || exit 1
  exit ${PKGIN_EXIT:-0}
fi

exit 1
STUB
  chmod +x "$fixture/opt/pkg/bin/pkgin"
}

provide_basic_tools() {
  fixture=$1
  for cmd in mktemp mkdir rm cat env ln sh dirname readlink; do
    tool_path=$(command -v "$cmd" 2>/dev/null || true)
    if [ -n "$tool_path" ]; then
      ln -s "$tool_path" "$fixture/bin/$cmd"
    fi
  done
}

link_tools() {
  dir=$1
  shift
  for tool in "$@"; do
    if [ -e "$dir/$tool" ]; then
      continue
    fi
    tool_path=$(command -v "$tool" 2>/dev/null || true)
    if [ -n "$tool_path" ]; then
      ln -s "$tool_path" "$dir/$tool"
    fi
  done
}

