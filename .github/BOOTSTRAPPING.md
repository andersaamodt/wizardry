# Wizardry Bootstrapping - AI Agent Reference

## Execution Order and Script Types

### The Five Phases

```
Phase 0: POSIX Foundation     → detect-posix validates
Phase 1: Download & Install   → ./install runs (self-contained)
Phase 2: Shell Integration    → install modifies rc file
Phase 3: Runtime Invocation   → invoke-wizardry sources at startup
Phase 4: Validation          → banish validates spell levels
```

### Script Classification

**Self-contained scripts** (Phases 0-2): Cannot use wizardry imps or spells
- `install` - Downloads/installs wizardry
- `spells/install/core/*` - Core prerequisite installers
- `detect-posix`, `detect-distro`, `detect-rc-file` - Detection utilities

**Wizardry-dependent spells** (Phases 3-4): Require wizardry invoked
- `banish` - Validates spell levels
- `validate-spells` - Checks spell/imp existence
- All regular spells - Use `require-wizardry || return 1`

---

## Critical: set -eu Placement Rules

### Castable Spells (Can be executed AND sourced)

```sh
#!/bin/sh

spell_name() {
case "${1-}" in
--help|--usage|-h)
  spell_name_usage
  return 0  # ← RETURN (not exit) - allows sourcing
  ;;
esac

require-wizardry || return 1  # ← RETURN - before set -eu

set -eu  # ← INSIDE function
env-clear

# Main spell logic
}

castable "$@"  # ← AFTER function definition
```

**Why set -eu inside the function?**
- Castable loading code runs without strict mode (WIZARDRY_DIR may be unset)
- Function body gets strict mode protection
- `return` (not `exit`) allows safe sourcing

**Why env-clear?**
- Clears environment variables that might interfere with spell execution
- Preserves wizardry globals (WIZARDRY_DIR, SPELLBOOK_DIR, etc.)
- Preserves system essentials (PATH, HOME, TERM, etc.)
- Prevents environment variable pollution between spells
- Must be sourced (`. env-clear`) AFTER `set -eu`

### Uncastable Spells (Source-only, like `colors`)

```sh
#!/bin/sh

case "${1-}" in
--help) usage; exit 0 ;; esac  # ← Top-level exit OK

uncastable  # ← BEFORE require-wizardry

require-wizardry || exit 1  # ← Top-level exit OK

spell_name() {
case "${1-}" in
--help) usage; return 0 ;; esac  # ← Function return

set -eu  # ← INSIDE function
env-clear

# Main spell logic
}
```

### Imps (Action)

```sh
#!/bin/sh
set -eu  # ← TOP of file (imps are simple)

_imp_name() {
  # Implementation
}

case "$0" in
  */imp-name) _imp_name "$@" ;; esac
```

**ONE set -eu per imp!** Never duplicate before case statement.

### Imps (Conditional - return exit codes)

```sh
#!/bin/sh
# NO set -eu for conditional imps

_imp_name() {
  [ "$1" = "expected" ]  # Returns 0 or 1
}

case "$0" in
  */imp-name) _imp_name "$@" ;; esac
```

### Self-Contained Scripts (install, detect-*)

```sh
#!/bin/sh

# Set baseline PATH BEFORE set -eu
baseline_path="/usr/local/bin:/usr/bin:/bin"
case ":${PATH-}:" in
  *":/bin:"*) ;;
  *) PATH="${baseline_path}${PATH:+:}${PATH-}" ;;
esac
export PATH

set -eu  # ← AFTER PATH setup

# Self-contained logic (no wizardry imps)
```

---

## Phase Details

### Phase 0: POSIX Foundation

**Spell Level 0** - POSIX + package manager available

### Phase 1: Download & Install

**Actions**: `./install` downloads wizardry to `~/.wizardry` (or custom path)

**Spell Level 1 prerequisites** - Files on disk, not yet usable

### Phase 2: Shell Integration

**Actions**: `install` adds `. invoke-wizardry` to shell rc file, creates `~/.spellbook`

**Spell Level 1 complete** - Ready for invocation in new shells

### Phase 3: Runtime Invocation

**Actions**: Shell sources `invoke-wizardry` → loads imps/spells → creates glosses

**Spell Levels 2-3** - Glossary + Menu functional

### Phase 4: Validation

**Actions**: `banish N` validates levels 0 through N

**Spell Levels 0-29** - Progressive validation

---

## Component Relationships

| Component | Type | Phase | Can Use Wizardry? |
|-----------|------|-------|-------------------|
| `install` | Self-contained script | 1-2 | No |
| `detect-posix` | Self-contained script | 0 | No |
| `invoke-wizardry` | Initialization script | 3 | No (loads it) |
| `require-wizardry` | Imp | 3+ | Yes |
| `banish` | Spell | 4 | Yes |

**Mental model:**
- `install` = downloads/installs (Phases 1-2)
- `invoke-wizardry` = initializes (Phase 3)
- `require-wizardry` = validates readiness (runtime check)
- `banish` = validates spell levels (Phase 4)

---

## Common Patterns

### Castable Spell Pattern

```sh
#!/bin/sh

spell_name() {
case "${1-}" in
--help) usage; return 0 ;; esac

require-wizardry || return 1

set -eu
env-clear

# Spell logic using wizardry features
}

castable "$@"
```

### Self-Contained Script Pattern

```sh
#!/bin/sh

# PATH setup before set -eu
baseline_path="/usr/local/bin:/usr/bin:/bin"
case ":${PATH-}:" in
  *":/bin:"*) ;;
  *) PATH="${baseline_path}${PATH:+:}${PATH-}" ;;
esac
export PATH

set -eu

# Self-contained logic - no wizardry dependencies
if ! command -v tar >/dev/null 2>&1; then
  printf 'tar required\n' >&2
  exit 1
fi
```

---

## Decision Tree

```
Writing code that runs BEFORE wizardry installed?
├─ Yes → Self-contained script (no imps, no spells)
│         Examples: install, detect-posix, detect-distro
│         Pattern: Check commands before use, inline logic
│
└─ No → Wizardry invoked (Phase 3+)?
    ├─ Check readiness → require-wizardry || return 1
    ├─ Validate levels → banish N
    └─ Normal spell → Use castable pattern
```

---

## Environment Variables

**Phase 1-2 (Install)**:
- `WIZARDRY_INSTALL_DIR` - Override install location
- `WIZARDRY_INSTALL_ASSUME_YES` - Non-interactive

**Phase 3+ (Runtime)**:
- `WIZARDRY_DIR` - Set by invoke-wizardry (required)
- `SPELLBOOK_DIR` - User spell directory
- `WIZARDRY_DEBUG` - Enable diagnostics
- `WIZARDRY_TEST_HELPERS_ONLY` - Test mode

---

## Key Rules

1. **Self-contained scripts cannot use wizardry** - No imps, no spells
2. **Castable spells use `return`** - Not `exit` (safe for sourcing)
3. **set -eu goes inside functions** - For castable spells
4. **ONE set -eu per imp** - Never duplicate
5. **Conditional imps have NO set -eu** - Return exit codes for flow control
6. **require-wizardry checks, doesn't initialize** - Use `|| return 1`

---

## Spell Levels vs Phases

**Spell levels (0-29)** define functional dependencies and capabilities.

**Bootstrap phases (0-4)** define installation/initialization sequence.

All spells install in Phase 1-2. Spell levels determine validation order in Phase 4 (banish).

---

## Testing

Tests use `WIZARDRY_TEST_HELPERS_ONLY=1` which makes `require-wizardry` always succeed and sets up PATH directly.
