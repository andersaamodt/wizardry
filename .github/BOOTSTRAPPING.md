# Wizardry Bootstrapping - AI Agent Reference

## Core Concept: Execution Sequence

Wizardry has a specific execution order that determines which scripts can use wizardry features:

```
1. install (self-contained)
   ↓ downloads wizardry
2. invoke-wizardry (sourced at shell startup)
   ↓ loads imps and spells
3. require-wizardry (checks if step 2 succeeded)
   ↓ used by regular spells
4. banish (validates spell levels)
```

**Key rule**: Scripts in steps 1-2 CANNOT use wizardry. Scripts in steps 3-4 CAN use wizardry.

---

## Critical Placement Rules

### 1. Castable Spells (99% of spells)

**Correct sequence:**
```sh
#!/bin/sh

spell_name() {
  case "${1-}" in --help) usage; return 0 ;; esac
  
  require-wizardry || return 1  # ← FIRST: check wizardry available
  set -eu                        # ← SECOND: enable strict mode
  env-clear                      # ← THIRD: clear environment
  
  # Spell logic here
}

castable "$@"  # ← LAST: self-execute
```

**Why this order?**
- `require-wizardry` before `set -eu`: Checks can fail gracefully with `|| return 1`
- `set -eu` inside function: Castable loading runs in permissive mode (WIZARDRY_DIR may be unset)
- `env-clear` after `set -eu`: Needs strict mode for safety
- `castable` at end: Self-executes only when run directly (not sourced)
- Use `return` (not `exit`): Allows safe sourcing without killing shell

### 2. Imps (Action)

**Correct sequence:**
```sh
#!/bin/sh
set -eu  # ← TOP of file (imps are simple, always strict)

_imp_name() {
  # Implementation
}

case "$0" in */imp-name) _imp_name "$@" ;; esac
```

**Critical: ONE `set -eu` per file!** Never duplicate before case statement.

### 3. Imps (Conditional - for if/while conditions)

**Correct sequence:**
```sh
#!/bin/sh
# NO set -eu for conditional imps

_imp_name() {
  [ "$1" = "expected" ]  # Returns 0/1 for flow control
}

case "$0" in */imp-name) _imp_name "$@" ;; esac
```

**Why no `set -eu`?** These return exit codes for `if`/`&&`/`||` chains.

### 4. Self-Contained Scripts (install, detect-*)

**Correct sequence:**
```sh
#!/bin/sh

# PATH setup BEFORE set -eu (may use unset variables)
baseline_path="/usr/local/bin:/usr/bin:/bin"
case ":${PATH-}:" in
  *":/bin:"*) ;;
  *) PATH="${baseline_path}${PATH:+:}${PATH-}" ;;
esac
export PATH

set -eu  # ← AFTER PATH setup

# Self-contained logic (NO wizardry imps/spells)
```

### 5. Uncastable Spells (must be sourced, like `colors`)

**Correct sequence:**
```sh
#!/bin/sh

case "${1-}" in --help) usage; exit 0 ;; esac  # ← Top-level exit OK

uncastable  # ← BEFORE require-wizardry

require-wizardry || exit 1  # ← Top-level exit OK

spell_name() {
  case "${1-}" in --help) usage; return 0 ;; esac  # ← Function return
  
  set -eu  # ← INSIDE function
  env-clear
  
  # Main logic
}
```

---

## Component Relationships

| Component | Runs When | Can Use Wizardry? | Uses |
|-----------|-----------|-------------------|------|
| `install` | Phase 1-2 | ❌ No | Self-contained |
| `detect-posix` | Phase 0 | ❌ No | Self-contained |
| `invoke-wizardry` | Phase 3 (shell startup) | ❌ No (but loads wizardry) | Sources imps/spells |
| `require-wizardry` | Inside spells (Phase 3+) | ✅ Yes (is wizardry) | Checks WIZARDRY_DIR |
| `env-clear` | Inside spells (Phase 3+) | ✅ Yes (is wizardry) | Clears environment |
| `banish` | Phase 4 (validation) | ✅ Yes | Validates spell levels |
| Regular spells | Phase 3+ | ✅ Yes | require-wizardry, env-clear |

**Key insight:** `invoke-wizardry` is the dividing line. Scripts before it cannot use wizardry. Scripts after it can.

---

## Why env-clear?

**Purpose**: Prevents environment variable pollution between spells

**What it does:**
- Clears all environment variables
- Preserves wizardry globals (WIZARDRY_DIR, SPELLBOOK_DIR, etc.)
- Preserves system essentials (PATH, HOME, TERM, etc.)
- Preserves test infrastructure (WIZARDRY_TEST_HELPERS_ONLY, etc.)

**Placement:** MUST be sourced AFTER `set -eu` inside spell function

---

## The Five Phases

```
Phase 0: POSIX Foundation     → detect-posix validates
Phase 1: Download & Install   → ./install runs (self-contained)
Phase 2: Shell Integration    → install modifies rc file
Phase 3: Runtime Invocation   → invoke-wizardry sources at startup
Phase 4: Validation          → banish validates spell levels
```

**Phase 0-2:** Self-contained scripts (no wizardry)
**Phase 3-4:** Wizardry-dependent scripts (use require-wizardry)

---

## Decision Tree

```
Writing a script?
│
├─ Runs BEFORE invoke-wizardry (Phase 0-2)?
│  ├─ Yes → Self-contained script
│  │       - NO require-wizardry
│  │       - NO env-clear
│  │       - set -eu AFTER PATH setup
│  │       - Examples: install, detect-posix, detect-distro
│  │
│  └─ No → Runs AFTER invoke-wizardry (Phase 3+)?
│         └─ Yes → Regular spell
│                  - require-wizardry || return 1
│                  - set -eu INSIDE function
│                  - env-clear AFTER set -eu
│                  - castable "$@" at end
│                  - Examples: copy, forall, menu
```

---

## Common Errors

❌ **WRONG: exit instead of return**
```sh
spell_name() {
  require-wizardry || exit 1  # Kills shell when sourced!
}
```

✅ **CORRECT: return for safe sourcing**
```sh
spell_name() {
  require-wizardry || return 1  # Safe to source
}
```

---

❌ **WRONG: set -eu before require-wizardry**
```sh
spell_name() {
  set -eu
  require-wizardry || return 1  # Can't use || with set -e
}
```

✅ **CORRECT: require-wizardry before set -eu**
```sh
spell_name() {
  require-wizardry || return 1
  set -eu
}
```

---

❌ **WRONG: duplicate set -eu in imp**
```sh
#!/bin/sh
set -eu
_imp() { ... }
set -eu  # DUPLICATE! Breaks invoke-wizardry
case "$0" in */imp) _imp "$@" ;; esac
```

✅ **CORRECT: ONE set -eu**
```sh
#!/bin/sh
set -eu
_imp() { ... }
case "$0" in */imp) _imp "$@" ;; esac
```

---

❌ **WRONG: env-clear before set -eu**
```sh
spell_name() {
  env-clear  # Runs in permissive mode!
  set -eu
}
```

✅ **CORRECT: env-clear after set -eu**
```sh
spell_name() {
  set -eu
  env-clear  # Runs in strict mode
}
```

---

## Quick Reference

**Castable spell template:**
```sh
#!/bin/sh
spell_name() {
  case "${1-}" in --help) usage; return 0 ;; esac
  require-wizardry || return 1
  set -eu
  env-clear
  # logic
}
castable "$@"
```

**Action imp template:**
```sh
#!/bin/sh
set -eu
_imp() { ... }
case "$0" in */imp) _imp "$@" ;; esac
```

**Self-contained script template:**
```sh
#!/bin/sh
# PATH setup
baseline_path="/usr/local/bin:/usr/bin:/bin"
case ":${PATH-}:" in *":/bin:"*) ;; *) PATH="$baseline_path:$PATH" ;; esac
export PATH
set -eu
# logic
```
