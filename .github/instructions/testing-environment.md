# Testing Environment Differences: AI Documentation

This document explains common reasons why tests may pass in a local development environment but fail in CI, and vice versa. Understanding these differences is critical for AI agents debugging test failures.

## Key Differences Between Environments

### 1. Bubblewrap Sandboxing

**CI Environment:**
- Tests run inside bubblewrap sandboxes (when available)
- Provides filesystem isolation
- Restricts access to `/dev/tty` and other system resources
- Mounts a minimal filesystem view
- Environment variables are heavily controlled

**Local Development:**
- Often runs without bubblewrap (warning: "proceeding without sandbox isolation")
- Full filesystem access
- Direct `/dev/tty` access for interactive prompts
- All environment variables available

**Impact:**
- Tests that pass locally may fail in CI if they assume `/dev/tty` access
- Interactive prompts (like `ask-yn`) fail with "cannot open /dev/tty"
- File paths may behave differently due to mount restrictions

**Solution:**
- Use `ASK_CANTRIP_INPUT=none` or similar env vars to disable interactive prompts in tests
- Mock `/dev/tty` access when testing interactive spells
- Check for `/dev/tty` availability before using it

### 2. PATH Environment

**CI Environment:**
- PATH is strictly controlled per platform (see `.github/workflows/tests.yml`)
- May start empty on some platforms (macOS GitHub Actions)
- Bubblewrap further restricts PATH
- Test harness explicitly sets up PATH for imps and spells

**Local Development:**
- Inherits user's PATH with all their tools
- Usually includes standard directories by default
- System tools readily available

**Impact:**
- Tests may pass locally because tools are in PATH but fail in CI
- Spells that assume certain tools are available without checking will fail
- Tests must explicitly set up PATH for imps directories

**Solution:**
- Always use `command -v tool` to check availability
- Never assume tools are in PATH
- Test harness should add wizardry directories to PATH:
  ```sh
  PATH="$ROOT_DIR/spells/.imps:$PATH"
  for impdir in "$ROOT_DIR"/spells/.imps/*; do
    PATH="$impdir:$PATH"
  done
  ```

### 3. Environment Variable Availability

**CI Environment:**
- Minimal set of environment variables
- HOME, USER, SHELL, TERM may have specific test values
- TMPDIR may point to controlled temp directories
- Test variables like `WIZARDRY_TEST_HELPERS_ONLY` are set

**Local Development:**
- Full user environment inherited
- All user-specific variables present
- May have custom configurations in rc files
- Development tools' environment variables present

**Impact:**
- Tests that assume certain env vars exist may fail
- Tests may behave differently based on HOME location
- Spells using undeclared env vars will fail with `set -eu`

**Solution:**
- Always use `${VAR:-}` or `${VAR-}` syntax for optional variables
- Check for variable existence before using with `set -eu`
- Tests should explicitly set required environment variables
- Use `env-clear` imp carefully (it preserves specific variables for tests)

### 4. File System Layout

**CI Environment:**
- Repository is in `/home/runner/work/wizardry/wizardry` or similar
- Temp directories are under system temp with specific permissions
- No user customizations in HOME directory
- Clean slate on every run

**Local Development:**
- Repository can be anywhere (`~/.wizardry`, `/tmp/wizardry`, etc.)
- Temp directories may behave differently
- User's actual HOME with real rc files and configurations
- State may persist between test runs

**Impact:**
- Tests that assume specific paths may fail
- Tests that don't clean up properly pollute local environment
- Path normalization issues (double slashes in macOS TMPDIR)
- Tests may pass locally due to leftover state

**Solution:**
- Always use relative paths from repository root
- Clean up temp files and directories in tests
- Use `make_tempdir` from test framework (handles normalization)
- Never hard-code absolute paths
- Use `$(cd "$script_dir" && pwd -P)` for resolution

### 5. Shell and POSIX Compliance

**CI Environment:**
- Tests run with `/bin/sh` (usually dash on Linux, bash on macOS)
- Strict POSIX compliance enforced
- No bash-isms available
- Shell behavior varies by platform

**Local Development:**
- User's default shell (may be bash, zsh, fish, etc.)
- Bash-isms may work if using bash
- More lenient parsing in some cases
- Development shell may have custom functions

**Impact:**
- Bash-isms work locally but fail in CI
- Tests must use POSIX-compliant constructs
- `[[` vs `[`, `==` vs `=`, arrays, etc.

**Solution:**
- Always use `#!/bin/sh` shebang
- Use `[` not `[[`
- Use `=` not `==` for string comparison
- No arrays, use space-separated strings
- Run `lint-magic` and `verify-posix` before committing
- Use `checkbashisms` to detect non-POSIX constructs

### 6. Interactive vs Non-Interactive

**CI Environment:**
- No terminal attached (stdin redirected from `/dev/null`)
- All tests run non-interactively
- Cannot prompt for user input
- Must provide input via environment variables or test stubs

**Local Development:**
- Terminal usually attached
- Interactive prompts may work
- Developer can respond to prompts
- Tests may hang waiting for input

**Impact:**
- Tests that work interactively locally will hang in CI
- Need to mock or stub interactive input
- `read` commands will fail immediately with EOF

**Solution:**
- Use stub imps from `spells/.imps/test/stub-*` for terminal I/O
- Provide canned input via fake TTY files for await-keypress
- Use `AWAIT_KEYPRESS_SKIP_STTY=1` with fake TTY device
- Test real wizardry, stub only the bare minimum (terminal I/O)
- Never rely on timeouts as a testing strategy

### 7. Platform-Specific Differences

**CI Matrix Platforms:**
- Debian (in container)
- Ubuntu (native)
- Arch Linux (in container)
- NixOS (via Nix installed on Ubuntu)
- macOS (native)

**Local Development:**
- Single platform (developer's OS)
- Specific version with specific quirks
- May have custom configurations

**Impact:**
- Tests pass on one platform, fail on others
- Command availability varies (e.g., `timeout`, `realpath`)
- File system behavior differs (case sensitivity, symlink handling)
- Package managers differ (apt, pacman, nix, brew)

**Solution:**
- Test on multiple platforms if possible
- Use platform detection (`detect-distro`)
- Provide fallbacks for missing commands
- Abstract platform differences behind imps
- Check command availability with `command -v`

### 8. Timing and Race Conditions

**CI Environment:**
- Shared runners with variable performance
- May be slow or fast unpredictably
- Timeouts are enforced (default 180s per test)
- Concurrent test execution

**Local Development:**
- Dedicated resources
- Consistent performance
- May not enforce timeouts
- Usually single-threaded testing

**Impact:**
- Race conditions may only appear in CI
- Tests may timeout in slow CI environments
- Timing-dependent tests are unreliable

**Solution:**
- Avoid timing-dependent tests
- Use explicit synchronization (wait for condition, not fixed sleep)
- Increase timeout for slow operations
- Use `WIZARDRY_TEST_TIMEOUT` variable to override

### 9. Variable Initialization with `set -eu`

**Critical Issue:**
- With `set -eu`, referencing unset variables causes immediate exit
- Tests must initialize all variables before use
- Empty strings must be explicitly set

**Common Patterns:**
```sh
# WRONG - fails with set -eu if VAR is unset
echo "$VAR"

# CORRECT - provides default empty value
echo "${VAR-}"
echo "${VAR:-}"

# CORRECT - explicit check and error
if [ -z "${VAR-}" ]; then
  echo "VAR required" >&2
  exit 1
fi
```

**Impact:**
- Tests pass without `set -eu` but fail with it
- Spells that reference optional variables fail
- Bootstrap scripts must be extra careful

**Solution:**
- Always use `${VAR-}` or `${VAR:-default}` for optional variables
- Place `set -eu` **after** argument parsing (see detect-rc-file fix)
- Initialize variables before `set -eu`
- Check for variable existence explicitly when needed

### 10. Test Helper Availability

**CI Environment:**
- Test framework explicitly sources helpers
- Test imps available via PATH setup
- Consistent helper versions

**Local Development:**
- May use system versions of tools
- Helper sourcing may differ
- Development versions of helpers

**Impact:**
- Helper functions may not be available
- Wrong versions of helpers may be used
- Test infrastructure may behave differently

**Solution:**
- Always source test helpers explicitly:
  ```sh
  test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
  while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
    test_root=$(dirname "$test_root")
  done
  . "$test_root/spells/.imps/test/test-bootstrap"
  ```
- Use helpers from repository, not system
- Test framework should validate helper availability

## Debugging Workflow

When tests pass locally but fail in CI:

1. **Check CI logs carefully** - exact error messages differ from local
2. **Look for environment differences** - PATH, HOME, variables
3. **Check for `/dev/tty` errors** - indicates interactive code in non-interactive env
4. **Look for "parameter not set" errors** - `set -eu` with uninitialized variables
5. **Check bubblewrap warnings** - sandboxing may restrict access
6. **Verify PATH setup** - tools and imps must be explicitly added
7. **Check file paths** - absolute vs relative, normalization issues
8. **Look for timing issues** - timeouts, race conditions
9. **Test with `/bin/sh` locally** - not bash, to catch POSIX issues
10. **Run with minimal environment** - `env -i` to simulate clean env

## Common Fixes

### Fix 1: Handle Empty Variables with set -eu
```sh
# Before
value=$1

# After
value=${1-}
```

### Fix 2: Check for Interactive Terminal
```sh
# Before
read -r user_input

# After
if [ "${ASK_CANTRIP_INPUT-}" = "none" ]; then
  echo "Error: No interactive input available." >&2
  exit 1
fi
read -r user_input
```

### Fix 3: Set up PATH in Tests
```sh
# At beginning of test file
ROOT_DIR=$(cd "$test_root/../.." && pwd -P)
PATH="$ROOT_DIR/spells/.imps:$PATH"
for impdir in "$ROOT_DIR"/spells/.imps/*; do
  [ -d "$impdir" ] && PATH="$impdir:$PATH"
done
export PATH
```

### Fix 4: Place set -eu After Argument Parsing
```sh
# Before
set -eu
while [ "$#" -gt 0 ]; do
  case $1 in
    --opt) opt=$2; shift 2 ;;
  esac
done

# After
while [ "$#" -gt 0 ]; do
  case $1 in
    --opt) opt=$2; shift 2 ;;
  esac
done
set -eu
```

### Fix 5: Use Stub Imps, Not Inline Stubs
```sh
# WRONG - inline stub in test file
cat >"$tmpdir/fathom-cursor" <<'STUB'
#!/bin/sh
printf '1 1\n'
STUB
chmod +x "$tmpdir/fathom-cursor"

# CORRECT - use reusable stub imp
mkdir -p "$tmpdir/stubs"
ln -s "$ROOT_DIR/spells/.imps/test/stub-fathom-cursor" "$tmpdir/stubs/fathom-cursor"
PATH="$tmpdir/stubs:$PATH" run_spell "path/to/spell"
```

## Summary

The most common causes of test failures in CI are:

1. **Missing `/dev/tty`** - bubblewrap restriction
2. **Uninitialized variables with `set -eu`** - needs `${VAR-}` syntax
3. **Missing PATH setup** - imps not in PATH
4. **Interactive prompts** - no terminal in CI
5. **Platform-specific commands** - assuming tools exist
6. **Wrong `set -eu` placement** - inside loops or before initialization
7. **Bash-isms** - using non-POSIX constructs
8. **File path assumptions** - hard-coded or unnormalized paths

Always test with strict POSIX compliance, minimal environment, and non-interactive mode to catch these issues before CI.
