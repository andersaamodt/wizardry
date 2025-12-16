# Spell Style Instructions

applyTo: "spells/**"

## Creating New Spells

**CRITICAL**: When creating a new spell, you MUST also create a corresponding test file:
- Spell location: `spells/category/spell-name`
- Test location: `.tests/category/test_spell-name.sh`

Test files are NOT optional. Every spell requires tests covering:
1. `--help` output
2. Success cases
3. Error cases

**After creating tests, you MUST run them and report actual results:**
```sh
.tests/category/test_spell-name.sh
```
Never claim tests pass without actually executing them. Report the actual pass/fail counts.

See `.github/instructions/tests.instructions.md` for test patterns.

## Spell Template

```sh
#!/bin/sh

# Brief description of what this spell does.
# Additional context (optional second line).

show_usage() {
  cat <<'USAGE'
Usage: spell-name [options] [arguments]

Description of what the spell does and how to use it.
USAGE
}

case "${1-}" in
--help|--usage|-h)
  show_usage
  exit 0
  ;;
esac

set -eu

# Main spell logic here
```

## Required Elements

1. **Shebang**: `#!/bin/sh` (POSIX only)
2. **Opening comment**: 1-2 lines describing what it does
3. **Strict mode**: `set -eu`

## Recommended Elements

1. **`show_usage()` function** with single-quoted heredoc `'USAGE'`
2. **Help handler** before `set -eu` for `--help`, `--usage`, `-h`

## Code Style

### Function Naming

All functions in spells must use **snake_case** naming:

```sh
# CORRECT
show_usage() { ... }
detect_os() { ... }
helper_usable() { ... }
read_value() { ... }
validate_name() { ... }

# WRONG - do not use underscore prefix in spells
_jump() { ... }
_helper_function() { ... }

# WRONG - do not use hyphens in function names
my-function() { ... }
```

**Convention**:
- **Spells**: Use `snake_case` for all internal functions
- **Imps**: Use underscore-prefixed `_snake_case` for "true name" functions (e.g., `_nix_shell_add`)

**Rationale**:
- `snake_case` is the dominant convention in POSIX shell
- Underscore prefix is reserved for imp "true names" to distinguish from public hyphenated aliases
- Consistent naming makes code easier to read and maintain

### Variables
```sh
# CORRECT
var=''
value=${1-}              # Empty default
value=${1:-default}      # Non-empty default

# WRONG
var= 
value=$1                 # Fails with set -u
```

### Variable Naming Convention

**CRITICAL**: Variable names indicate scope and purpose.

#### Lowercase for Local Variables

**ALL local variables MUST use lowercase naming**:

```sh
# CORRECT - local variables (used only within this script)
script_dir=$(dirname "$0")
config_file="$HOME/.config/myapp"
user_input=""
temp_file=$(mktemp)
marker_name="${1:-}"
```

**NEVER use ALL_CAPS for local variables**:

```sh
# WRONG - looks like environment variable but is only local
SCRIPT_DIR=$(dirname "$0")
CONFIG_FILE="$HOME/.config/myapp"
USER_INPUT=""
TEMP_FILE=$(mktemp)
```

**Rationale**: In POSIX shell, ALL_CAPS conventionally indicates environment variables that may be exported or overridden. Using ALL_CAPS for local variables:
- Creates confusion about variable scope
- Suggests the variable might be used for inter-script communication
- Violates the principle of least surprise
- Is caught by `test_no_allcaps_variable_assignments` in common-tests.sh

#### ALL_CAPS for Environment Variables and Constants

**Use ALL_CAPS ONLY for**:

1. **Declared globals** (from `declare-globals`):
   ```sh
   WIZARDRY_DIR="${WIZARDRY_DIR:-}"
   SPELLBOOK_DIR="${SPELLBOOK_DIR:-}"
   MUD_DIR="${MUD_DIR:-}"
   ```

2. **Standard system environment variables**:
   ```sh
   PATH="$new_dir:$PATH"
   HOME="${HOME:-}"
   TMPDIR="${TMPDIR:-/tmp}"
   ```

3. **Feature flags and configuration** (documented in EXEMPTIONS.md):
   ```sh
   WIZARDRY_LOG_LEVEL="${WIZARDRY_LOG_LEVEL:-0}"
   AWAIT_KEYPRESS_KEEP_RAW=1
   ```

4. **Package manager override variables**:
   ```sh
   export APT_PACKAGE="package-name"
   export NIX_PACKAGE="package-name"
   ```

5. **True constants** (rare, must be justified):
   ```sh
   BITCOIN_PORT=8333  # Standard Bitcoin port
   ```

#### Avoid Environment Variable Antipattern

**DO NOT use environment variables to pass data between scripts.**

```sh
# WRONG - environment variable antipattern
export MY_CONFIG_FILE="$config"
other-spell  # expects MY_CONFIG_FILE

# CORRECT - explicit arguments
other-spell "$config"
```

**Exception**: Package manager variables (APT_PACKAGE, NIX_PACKAGE, etc.) are explicitly approved for arcana install scripts to communicate with `pkg-install`.

**Test-only overrides**: Environment variables like `*_ASK_TEXT` used in tests for stubbing are acceptable but should not be added to production code.

**Enforcement**: The `test_no_allcaps_variable_assignments` test in `.tests/common-tests.sh` prevents ALL_CAPS local variables from being introduced.

### Quoting
Always quote variables unless word splitting is intended:
```sh
printf '%s\n' "$message"
path="$HOME/wizardry"
```

### Output and Logging

Use the output imps from `out/` for consistent messaging. See `logging.instructions.md` for complete documentation.

```sh
# Always shown - basic output
say "File copied successfully"
success "Installation complete"

# Respects WIZARDRY_LOG_LEVEL (shown when >= 1)
info "Processing files..."
step "Installing dependencies..."

# Respects WIZARDRY_LOG_LEVEL (shown when >= 2)
debug "Variable value: $var"

# Errors and warnings (always shown)
warn "spell-name: configuration missing"
die "spell-name: installation failed"
die 2 "spell-name: invalid argument"
usage-error "$spell_name" "unknown option: $opt"
has git || fail "git required"
```

### Signal Handling and Cleanup

Use `on-exit` and `clear-traps` for consistent cleanup:

```sh
tmpfile=$(temp-file)
on-exit cleanup-file "$tmpfile"

# Work with tmpfile...
# Cleanup happens automatically on exit/interrupt
```

### Error Messages
Print to stderr with spell name prefix—descriptive, not imperative:
```sh
# CORRECT
die "spell-name: sshfs not found"
warn "spell-name: configuration missing"

# WRONG
die "Please install sshfs"
warn "You must create a configuration file"
```

### Error Handling Helpers (Legacy)

For reference, direct stderr output (prefer using imps instead):

```sh
# Direct output (use die/warn/fail instead)
printf '%s\n' "spell-name: sshfs not found." >&2
```

### Functions
Prefer linear, flat code flow over excessive function wrapping.

**Function Discipline**:
- `show_usage()` is required (except for imps)
- 0-1 additional helper functions: freely allowed (the "spell-heart helper")
- 2 additional functions: acceptable with warning (must be invoked from multiple paths, not suitable as imps)
- 3 additional functions: marginal case with strong warning
- 4+ additional functions: indicates proto-library, must decompose into multiple spells and/or imps

**Rationale**: A spell is a scroll, not a miniature program. It narrates one coherent magical action expressed linearly. Multiple internal subroutines indicate the action is conceptually fractured and should be refactored.

### Exit Codes
- `0`: Success
- `1`: General error
- `2`: Usage/argument error
- `126`: Command cannot execute
- `127`: Command not found
- `130`: Interrupted (Ctrl-C)

## Complexity Guidelines

Signs a spell needs refactoring:
- More than 2-3 optional flags
- Multiple modes or usage lines
- More than 5-10 lines of help text
- Complex nested conditionals
- **4+ additional functions beyond `show_usage()` (proto-library)**

Solutions:
- Split into multiple smaller spells
- Move shared logic to imps in `spells/.imps/`
- Use composition (small spells that pipe together)

## POSIX Compliance

Avoid bash-isms:
- Use `[ ]` not `[[ ]]`
- Use `.` not `source`
- Use `=` not `==` for string comparison
- No `local` keyword
- No arrays
- Use `$()` not backticks
