#!/bin/sh
# Common test helpers for simple POSIX shell tests.
# Provides minimal assertion helpers and a lightweight test runner.

# CRITICAL: Set a baseline PATH BEFORE set -eu and before any commands
# On macOS GitHub Actions, PATH may be completely empty, causing immediate failure
# when we try to use dirname, cd, pwd, etc. in find_repo_root
baseline_path="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
case ":${PATH-}:" in
  *":/usr/bin:"*|*":/bin:"*) 
    # Already has at least one standard directory
    ;;
  *) 
    # PATH is empty or missing standard directories, prepend baseline
    PATH="${baseline_path}${PATH:+:}${PATH-}"
    ;;
esac
export PATH

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

# The baseline PATH was already set at the top of this file.
# Now add wizardry spells directories to PATH.
initial_path=$PATH
PATH="$ROOT_DIR/spells"
# Include .imps first so imps are available to all spells
if [ -d "$ROOT_DIR/spells/.imps" ]; then
  PATH="$PATH:$ROOT_DIR/spells/.imps"
fi
for dir in "$ROOT_DIR"/spells/*; do
  [ -d "$dir" ] || continue
  PATH="$PATH:$dir"
done
PATH="$PATH:$initial_path"
export PATH
WIZARDRY_TEST_HELPERS_ONLY=1
export WIZARDRY_TEST_HELPERS_ONLY

# Save the system PATH for run_cmd to use internally
# This ensures run_cmd can always find essential utilities like mktemp, mkdir, cat, rm
# even when tests intentionally set a restricted PATH to test error conditions
WIZARDRY_SYSTEM_PATH="$initial_path"
export WIZARDRY_SYSTEM_PATH

: "${WIZARDRY_TMPDIR:=$(mktemp -d "${TMPDIR:-/tmp}/wizardry-test.XXXXXX")}" || exit 1
# Normalize path for macOS compatibility (TMPDIR ends with /)
WIZARDRY_TMPDIR=$(printf '%s' "$WIZARDRY_TMPDIR" | sed 's|//|/|g')
export WIZARDRY_TMPDIR

# Detect platform for sandbox selection
SANDBOX_PLATFORM=$(uname -s 2>/dev/null || printf 'unknown')

# Initialize sandbox availability flags
BWRAP_AVAILABLE=1
BWRAP_VIA_SUDO=0
BWRAP_USE_UNSHARE=1
BWRAP_BIN=${BWRAP_BIN-}
MACOS_SANDBOX_AVAILABLE=0
SANDBOX_EXEC_BIN=""

# Allow disabling sandboxing via environment variable
if [ "${WIZARDRY_DISABLE_SANDBOX-0}" = "1" ]; then
  BWRAP_AVAILABLE=0
  BWRAP_REASON="sandboxing disabled by WIZARDRY_DISABLE_SANDBOX"
  MACOS_SANDBOX_AVAILABLE=0
else
  # macOS sandboxing is disabled by default due to compatibility issues
  # Enable with WIZARDRY_ENABLE_MACOS_SANDBOX=1 if needed
  if [ "$SANDBOX_PLATFORM" = "Darwin" ] && [ "${WIZARDRY_ENABLE_MACOS_SANDBOX-0}" = "1" ]; then
    if command -v sandbox-exec >/dev/null 2>&1; then
      SANDBOX_EXEC_BIN=$(command -v sandbox-exec)
      # Test if sandbox-exec works with a simple profile
      if "$SANDBOX_EXEC_BIN" -p '(version 1) (allow default)' /usr/bin/true 2>/dev/null; then
        MACOS_SANDBOX_AVAILABLE=1
        # On macOS, prefer sandbox-exec over attempting bubblewrap
        BWRAP_AVAILABLE=0
        BWRAP_REASON="using macOS sandbox-exec instead"
      fi
    fi
  fi
fi

# Check for Linux bubblewrap (only if not using macOS sandboxing)
if [ "$MACOS_SANDBOX_AVAILABLE" -eq 0 ]; then
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

  if [ "$BWRAP_AVAILABLE" -eq 1 ] && { [ -z "$BWRAP_BIN" ] || [ ! -x "$BWRAP_BIN" ]; }; then
    BWRAP_AVAILABLE=0
    BWRAP_REASON="bubblewrap not installed"
  fi
fi

warn_once_file=${WIZARDRY_BWRAP_WARN_FILE-${TMPDIR:-/tmp}/wizardry-sandbox-warning}

if [ "$BWRAP_AVAILABLE" -eq 0 ] && [ "$MACOS_SANDBOX_AVAILABLE" -eq 0 ] && [ ! -f "$warn_once_file" ] && [ "${WIZARDRY_BWRAP_WARNING-0}" -eq 0 ]; then
  printf '%s\n' "WARNING: proceeding without sandbox isolation: $BWRAP_REASON" >&2
  WIZARDRY_BWRAP_WARNING=1
  export WIZARDRY_BWRAP_WARNING
  : >"$warn_once_file" 2>/dev/null || true
elif [ "$MACOS_SANDBOX_AVAILABLE" -eq 1 ] && [ ! -f "$warn_once_file" ]; then
  printf '%s\n' "INFO: using macOS sandbox-exec for test isolation" >&2
  : >"$warn_once_file" 2>/dev/null || true
fi

run_bwrap() {
  if [ "$BWRAP_VIA_SUDO" -eq 1 ]; then
    sudo -n "$BWRAP_BIN" "$@"
  else
    "$BWRAP_BIN" "$@"
  fi
}

run_macos_sandbox() {
  # Create a permissive sandbox profile that provides minimal isolation
  # NOTE: macOS sandboxing is DISABLED BY DEFAULT due to compatibility issues
  # Enable with WIZARDRY_ENABLE_MACOS_SANDBOX=1 if needed for testing
  #
  # This profile is intentionally very permissive because:
  # 1. macOS sandbox-exec is fundamentally more restrictive than Linux bubblewrap
  # 2. A more restrictive profile caused 75 out of 102 tests to fail
  # 3. Even a permissive profile may cause test failures in GitHub Actions
  # 4. The primary benefit is process isolation and consistent environment, not security
  #
  # The profile allows most operations to maintain test compatibility while still
  # providing basic process isolation that helps catch environment-related issues.
  sandbox_profile='(version 1)
(allow default)
(allow file-read*)
(allow file-write*)
(allow process*)
(allow network*)
(allow ipc*)
(allow mach*)
(allow sysctl*)
(allow signal)
(allow system*)
'
  
  "$SANDBOX_EXEC_BIN" -p "$sandbox_profile" "$@"
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

# Capture a command's stdout, stderr, and exit status inside a sandbox.
# Uses bubblewrap on Linux or sandbox-exec on macOS when available.
# Results land in STATUS, OUTPUT, and ERROR variables.
run_cmd() {
  # Save the caller's PATH and temporarily use the system PATH for run_cmd's
  # internal operations (mktemp, mkdir, cat, rm, pwd). This ensures run_cmd
  # works even when tests intentionally set a restricted PATH.
  _saved_path=$PATH
  PATH=${WIZARDRY_SYSTEM_PATH:-$PATH}
  
  _stdout=$(mktemp "${WIZARDRY_TMPDIR}/stdout.XXXXXX") || return 1
  _stderr=$(mktemp "${WIZARDRY_TMPDIR}/stderr.XXXXXX") || return 1

  workdir=${RUN_CMD_WORKDIR:-$(pwd)}
  mkdir -p "$workdir"

  sandbox=$(mktemp -d "${WIZARDRY_TMPDIR}/sandbox.XXXXXX") || return 1
  tmpdir="$sandbox/tmp"
  homedir="$sandbox/home"
  mkdir -p "$tmpdir" "$homedir"
  
  # Restore the caller's PATH for use in the sandbox
  PATH=$_saved_path

  if [ "$BWRAP_AVAILABLE" -eq 1 ]; then
    # Pass through test-related environment variables that tests commonly set
    # These are needed for test stubs (apt-get, pkgin, etc.) to log their actions
    # Note: We bind WIZARDRY_TMPDIR as writable to allow test fixtures to work.
    # The --bind makes it writable even though / is ro-bind.
    set -- \
      --die-with-parent \
      --ro-bind / / \
      --dev-bind /dev /dev \
      --bind /proc /proc \
      --bind "$WIZARDRY_TMPDIR" "$WIZARDRY_TMPDIR" \
      --ro-bind "$ROOT_DIR" "$ROOT_DIR" \
      --chdir "$workdir" \
      --setenv PATH "$PATH" \
      --setenv HOME "$homedir" \
      --setenv TMPDIR "$tmpdir" \
      --setenv WIZARDRY_TMPDIR "$WIZARDRY_TMPDIR" \
      -- "$@"
    
    # Optionally pass through test-related variables if they're set
    # (add them BEFORE the -- separator in the command)
    for envvar in APT_LOG APT_EXIT PKGIN_LOG PKGIN_EXIT PKGIN_CANDIDATES; do
      eval "val=\${$envvar-}"
      if [ -n "$val" ]; then
        # Insert --setenv before the -- separator
        set -- "--setenv" "$envvar" "$val" "$@"
      fi
    done

    if [ "$BWRAP_USE_UNSHARE" -eq 1 ]; then
      set -- --unshare-user-try "$@"
    fi

    if run_bwrap "$@" >"$_stdout" 2>"$_stderr"; then
      STATUS=0
    else
      STATUS=$?
    fi
  elif [ "$MACOS_SANDBOX_AVAILABLE" -eq 1 ]; then
    # Use macOS sandbox-exec for isolation
    if (cd "$workdir" && env PATH="$PATH" HOME="$homedir" TMPDIR="$tmpdir" WIZARDRY_TMPDIR="$WIZARDRY_TMPDIR" \
      run_macos_sandbox "$@" >"$_stdout" 2>"$_stderr"); then
      STATUS=0
    else
      STATUS=$?
    fi
  else
    if (cd "$workdir" && env PATH="$PATH" HOME="$homedir" TMPDIR="$tmpdir" WIZARDRY_TMPDIR="$WIZARDRY_TMPDIR" "$@" \
      >"$_stdout" 2>"$_stderr"); then
      STATUS=0
    else
      STATUS=$?
    fi
  fi

  # Use system PATH again for cleanup operations
  PATH=${WIZARDRY_SYSTEM_PATH:-$PATH}
  OUTPUT=$(cat "$_stdout")
  ERROR=$(cat "$_stderr")
  rm -f "$_stdout" "$_stderr"
  rm -rf "$sandbox"
  
  # Restore caller's PATH before returning
  PATH=$_saved_path
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
  mktemp -d "${WIZARDRY_TMPDIR}/case.XXXXXX" | sed 's|//|/|g'
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
# Strip common sudo flags before executing the actual command.
# This stub handles flags used by wizardry spells; add more as needed.
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--non-interactive) shift ;;  # Skip non-interactive flag
    --)                   shift; break ;;  # End of options
    *)                    break ;;  # First non-flag argument
  esac
done
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

