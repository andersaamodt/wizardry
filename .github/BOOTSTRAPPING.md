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

## CRITICAL: Function Naming and Parse Loops

### The Golden Rule: Use Underscore Names in Spell Code

**Inside spell/imp code, ALWAYS use underscore function names:**

```sh
# ✅ CORRECT: Direct function calls (fast, no parse overhead)
require_wizardry || return 1
env_clear
cursor_blink on
move_cursor 10 20
temp_file "myfile"
cleanup_file "$tmpfile"

# ❌ WRONG: Hyphenated names (goes through glosses → parse → function)
require-wizardry || return 1  # Goes through gloss!
env-clear                      # Goes through gloss!
cursor-blink on                # Goes through gloss!
```

### Why This Matters

**Hyphenated names execute as glosses:**
1. User/script calls: `cursor-blink on`
2. Gloss file executes: `exec parse "cursor-blink" "on"`
3. Parse looks up and calls: `cursor_blink "on"`

**On macOS, this creates visible "parse parse parse..." in terminal title/ps output!**

**Underscore names call functions directly:**
1. Script calls: `cursor_blink on`
2. Function executes immediately (no gloss, no parse)

### When to Use Each Form

| Context | Use | Example |
|---------|-----|---------|
| **Inside spells** | Underscore | `cursor_blink on` |
| **Inside imps** | Underscore | `temp_file "name"` |
| **User terminal** | Hyphenated (via gloss) | `$ cursor-blink on` |
| **Spell help text** | Hyphenated (describes user command) | `"cursor-blink controls cursor visibility"` |

### Fallback Pattern is WRONG

```sh
# ❌ WRONG: Fallback to hyphenated gloss
menu_temp_file() {
  if command -v temp_file >/dev/null 2>&1; then
    temp_file "$@"
  else
    temp-file "$@"  # Goes through parse if function not found!
  fi
}

# ✅ CORRECT: Direct function call only
menu_temp_file() {
  temp_file "$@"  # Always use function (guaranteed by invoke-wizardry)
}
```

**Why fallback is wrong:**
- Spells only run AFTER `invoke-wizardry` loads all functions
- If function not found, that's a real error (missing spell level)
- Falling back to gloss creates parse loop on macOS
- Hides real problems instead of failing fast

### Parse Loop Prevention Checklist

- [ ] All imp calls use underscore names (`temp_file`, not `temp-file`)
- [ ] All spell calls use underscore names (`cursor_blink`, not `cursor-blink`)
- [ ] No fallback to hyphenated versions in `if command -v` checks
- [ ] `require_wizardry` (not `require-wizardry`) inside spell functions
- [ ] `env_clear` (not `env-clear`) inside spell functions
- [ ] Menu calls `fathom_cursor`, `move_cursor`, `await_keypress` with underscores

---

## Critical Placement Rules

### 1. Castable Spells (99% of spells)

**Correct sequence:**
```sh
#!/bin/sh

spell_name() {
  case "${1-}" in --help) usage; return 0 ;; esac
  
  require_wizardry || return 1   # ← FIRST: check wizardry available (UNDERSCORE!)
  set -eu                         # ← SECOND: enable strict mode
  env_clear                       # ← THIRD: clear environment (UNDERSCORE!)
  
  # Spell logic here - ALWAYS use underscore names for imp/spell calls
  temp_file "data"                # ← CORRECT: underscore
  cursor_blink on                 # ← CORRECT: underscore
  move_cursor 10 20               # ← CORRECT: underscore
  
  # NEVER use hyphenated names (they go through parse gloss)
  # temp-file "data"              # ← WRONG: creates parse loop!
  # cursor-blink on               # ← WRONG: creates parse loop!
}

castable "$@"  # ← LAST: self-execute
```

**Why this order?**
- `require_wizardry` (underscore!) before `set -eu`: Checks can fail gracefully with `|| return 1`
- `set -eu` inside function: Castable loading runs in permissive mode (WIZARDRY_DIR may be unset)
- `env_clear` (underscore!) after `set -eu`: Needs strict mode for safety
- `castable` at end: Self-executes only when run directly (not sourced)
- Use `return` (not `exit`): Allows safe sourcing without killing shell
- **CRITICAL**: All imp/spell calls use UNDERSCORE names to avoid parse loops

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

❌ **WRONG: Hyphenated names in spell code (creates parse loop!)**
```sh
spell_name() {
  require-wizardry || return 1  # Goes through parse gloss!
  env-clear                      # Goes through parse gloss!
  cursor-blink on                # Goes through parse gloss!
  temp-file "data"               # Goes through parse gloss!
}
```

✅ **CORRECT: Underscore names (direct function calls)**
```sh
spell_name() {
  require_wizardry || return 1  # Direct function call
  env_clear                      # Direct function call
  cursor_blink on                # Direct function call
  temp_file "data"               # Direct function call
}
```

**Why this matters:** On macOS, hyphenated calls show "parse parse parse..." in terminal title because every command goes through the parse gloss. Use underscore names for direct function calls.

---

❌ **WRONG: Fallback to hyphenated gloss**
```sh
menu_helper() {
  if command -v temp_file >/dev/null 2>&1; then
    temp_file "$@"
  else
    temp-file "$@"  # Creates parse loop if function not found!
  fi
}
```

✅ **CORRECT: Direct function call only (fail fast if missing)**
```sh
menu_helper() {
  temp_file "$@"  # Always use function (guaranteed by invoke-wizardry)
}
```

**Why this matters:** Spells only run after invoke-wizardry loads all functions. If a function is missing, that's a real error (wrong spell level). Fallback hides the problem and creates parse loops.

---

❌ **WRONG: exit instead of return**
```sh
spell_name() {
  require_wizardry || exit 1  # Kills shell when sourced!
}
```

✅ **CORRECT: return for safe sourcing**
```sh
spell_name() {
  require_wizardry || return 1  # Safe to source
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
  require_wizardry || return 1  # UNDERSCORE!
  set -eu
  env_clear                      # UNDERSCORE!
  # All imp/spell calls use UNDERSCORE names:
  # temp_file, cursor_blink, move_cursor, etc.
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
