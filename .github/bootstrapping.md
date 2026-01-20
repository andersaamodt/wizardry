# Wizardry Bootstrapping - AI Agent Quick Reference

## Execution Sequence (The Golden Rule)

```
install (self-contained) 
  → invoke-wizardry (sources imps/spells) 
    → Regular spells (can use wizardry)
```

**Scripts BEFORE invoke-wizardry:** Cannot use wizardry (self-contained)  
**Scripts AFTER invoke-wizardry:** Can use wizardry (require_wizardry, `. env-clear`, etc.)

---

## CRITICAL: Function Naming (Parse Loop Prevention)

### Inside Code: Use UNDERSCORE Names

```sh
# ✅ CORRECT - Direct function calls
require_wizardry || return 1
. env-clear
temp_file "name"
cursor_blink on

# ❌ WRONG - Goes through glosses → parse → LOOP
require-wizardry  # Creates parse loop!
env_clear         # Wrong - source the file instead!
temp-file "name"  # Creates parse loop!
```

**Why:** Hyphenated names execute as glosses (`exec parse "cmd" "$@"`). On macOS this creates visible "parse parse parse..." in terminal title and causes hangs.

### When to Use Each

| Context | Use | Why |
|---------|-----|-----|
| Inside spells/imps | `cursor_blink` (underscore) | Direct function call |
| User terminal | `cursor-blink` (hyphenated via gloss) | User-facing command |
| Help text | `cursor-blink` (hyphenated) | Describes user command |

### Never Use Fallback Pattern

```sh
# ❌ WRONG - Fallback creates loops
if command -v temp_file >/dev/null 2>&1; then
  temp_file "$@"
else
  temp-file "$@"  # Goes through parse!
fi

# ✅ CORRECT - Direct call only
temp_file "$@"  # Guaranteed by invoke-wizardry
```

---

## Spell Templates

### Castable Spell (99% of spells)

```sh
#!/bin/sh

spell_name() {
  case "${1-}" in --help) usage; return 0 ;; esac
  require_wizardry || return 1  # Underscore!
  set -eu
  . env-clear                    # Source file from PATH!
  
  # All calls use underscores
  temp_file "data"               # NOT temp-file
  cursor_blink on                # NOT cursor-blink
}

castable "$@"
```

**Order matters:**
1. Help handler (uses `return`)
2. `require_wizardry` BEFORE `set -eu` (underscore name!)
3. `set -eu` inside function
4. `. env-clear` AFTER `set -eu` (source file from PATH!)
5. `castable` at end
6. Use `return` (not `exit`) to allow sourcing

### Action Imp

```sh
#!/bin/sh
set -eu  # At top of file

_imp_name() {
  # Implementation
}

case "$0" in */imp-name) _imp_name "$@" ;; esac
```

**ONE `set -eu` only!** Never duplicate before case statement.

### Conditional Imp

```sh
#!/bin/sh
# NO set -eu

_imp_name() {
  [ "$1" = "expected" ]  # Returns 0/1
}

case "$0" in */imp-name) _imp_name "$@" ;; esac
```

No strict mode for exit-code-based flow control.

---

## Component Relationships

| Component | Phase | Can Use Wizardry | Dependencies |
|-----------|-------|------------------|--------------|
| `install` | 1-2 | ❌ No | Self-contained |
| `invoke-wizardry` | 3 | ❌ No | Loads wizardry |
| `require-wizardry` | 3+ | ✅ Yes | Checks WIZARDRY_DIR |
| `env-clear` | 3+ | ✅ Yes | Clears environment |
| Regular spells | 3+ | ✅ Yes | require_wizardry, `. env-clear` |

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `require-wizardry` in spell | Use `require_wizardry` |
| `env_clear` in spell | Use `. env-clear` |
| `temp-file` in spell | Use `temp_file` |
| Duplicate `set -eu` in imp | ONE at top only |
| `set -eu` before castable loading | Put inside function |
| Fallback to hyphenated gloss | Never fallback |
| `exit` in spell function | Use `return` |

---

## Castable Variable Bug

**Critical:** `word-of-binding` sets `_WIZARDRY_LOADING_SPELLS=1` when sourcing spells.

`castable` MUST check this variable to skip execution during loading. If it checks the wrong variable, spell functions execute during sourcing → hyphenated commands called → parse loop.

```sh
# In castable imp:
if [ -n "${_WIZARDRY_LOADING_SPELLS-}" ] || [ -n "${_WIZARDRY_SOURCING_SPELL-}" ]; then
  return 0  # Skip execution, just load function
fi
```

---

## Parse Loop Debug Checklist

- [ ] All imp calls use underscores (`temp_file` not `temp-file`)
- [ ] All spell calls use underscores (`cursor_blink` not `cursor-blink`)  
- [ ] No fallback to hyphenated versions
- [ ] `require_wizardry` (not `require-wizardry`)
- [ ] `. env-clear` (not `env_clear`)
- [ ] castable checks `_WIZARDRY_LOADING_SPELLS`
- [ ] No `exit` in spell functions (use `return`)
- [ ] ONE `set -eu` per imp file

---

## Quick Reference

**Self-contained (no wizardry):** install, detect-posix, detect-distro  
**Loads wizardry:** invoke-wizardry  
**Uses wizardry:** All regular spells (MUST use underscore names internally)

**Golden rule:** Underscore names inside code, hyphenated names for users.
