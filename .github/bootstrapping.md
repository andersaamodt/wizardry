# Wizardry Bootstrapping - AI Agent Quick Reference

## Execution Sequence (The Golden Rule)

```
install (self-contained) 
  → invoke-wizardry (sources imps/spells) 
    → Regular spells (can use wizardry)
```

**Scripts BEFORE invoke-wizardry:** Cannot use wizardry (self-contained)  
**Scripts AFTER invoke-wizardry:** Can use wizardry (all spells available in PATH)

---

## CRITICAL: ALL Wizardry Spells Call Each Other by Hyphenated Names

### Inside Code: Use HYPHENATED Names

```sh
# ✅ CORRECT - Call spells by hyphenated command name
env-clear
temp-file "name"
cursor-blink on
has git || exit 1

# ❌ WRONG - Never use underscores in spell code
env_clear         # WRONG!
temp_file "name"  # WRONG!
cursor_blink on   # WRONG!

# ❌ WRONG - Never use full paths to spells
"$WIZARDRY_DIR/spells/.imps/sys/env-clear"  # WRONG!
```

**Why:** All wizardry spells (including imps—imps ARE spells) are available in PATH after invoke-wizardry is called. All spell code should assume wizardry is already invoked and call other spells by their hyphenated command name.

### When to Use Each

| Context | Use | Why |
|---------|-----|-----|
| Inside spells/imps | `cursor-blink` (hyphenated) | Call spell command from PATH |
| User terminal | `cursor-blink` (hyphenated via PATH) | User-facing command |
| Help text | `cursor-blink` (hyphenated) | Describes user command |
| Function names | `cursor_blink` (underscored) | POSIX doesn't allow hyphens in function names |

**CRITICAL:** Functions cannot use hyphens in their names (not POSIX-compliant). But spell CALLS always use hyphens.

---

## Spell Templates

### Standard Spell (99% of spells)

```sh
#!/bin/sh

# Brief description of what this spell does.

case "${1-}" in
--help|--usage|-h)
  cat <<'USAGE'
Usage: spell-name [options] [arguments]

Description of what the spell does and how to use it.
USAGE
  exit 0
  ;;
esac

set -eu

# Main logic here
# Call other spells by hyphenated name:
env-clear
has git || exit 1
temp-file "data.txt"
```

**Key points:**
1. Help handler BEFORE `set -eu`
2. `set -eu` AFTER help handler
3. NO functions (except ONE helper function if absolutely necessary)
4. --usage is NEVER in a function (inline heredoc in case statement)
5. Use `exit` (not `return`) - these are scripts, not sourced functions
6. Call ALL other spells by hyphenated name from PATH

### Uncastable Spell (must be sourced, not executed)

For spells that MUST be sourced (like `jump-to-marker` which changes directory):

```sh
#!/bin/sh

# Brief description.
# This spell must be sourced (not executed) because it changes the current directory.

case "${1-}" in
--help|--usage|-h)
  cat <<'USAGE'
Usage: . spell-name [args]

Description.
Note: This spell must be sourced (use '. spell-name') to affect your current shell.
USAGE
  return 0 2>/dev/null || exit 0
  ;;
esac

# Uncastable pattern - ensures spell is sourced, not executed
_spell_name_sourced=0
if eval '[ -n "${ZSH_VERSION+x}" ]' 2>/dev/null; then
  case "${ZSH_EVAL_CONTEXT-}" in
    *:file) _spell_name_sourced=1 ;;
  esac
else
  _spell_name_base=${0##*/}
  case "$_spell_name_base" in
    sh|dash|bash|zsh|ksh|mksh) _spell_name_sourced=1 ;;
    spell-name) _spell_name_sourced=0 ;;
    *) _spell_name_sourced=1 ;;
  esac
fi

if [ "$_spell_name_sourced" -eq 0 ]; then
  printf '%s\n' "This spell cannot be cast directly. Invoke it with: spell name" >&2
  exit 1
fi
unset _spell_name_sourced _spell_name_base

# Main logic here
# Use `return` for flow control (since spell is sourced)
```

**Uncastable spells:**
- MUST have `# Uncastable` comment at start of uncastable pattern block
- Use `return` (not `exit`) for flow control (since they're sourced)
- Include helpful error message telling user how to invoke
- Examples: jump-to-marker, blink, cd (spells that change shell state)

### Action Imp

```sh
#!/bin/sh
# imp-name ARG - brief description

set -eu

# Flat, linear implementation (NO functions)
printf '%s\n' "$1"
```

**Imps CANNOT have ANY functions** - they must be completely flat.

### Conditional Imp (NO set -eu!)

```sh
#!/bin/sh
# imp-name ARG - test if condition

# NO set -eu because this is a conditional imp (returns exit codes for flow control)

# Flat, linear implementation (NO functions)
# Return 0 for true, 1 for false
[ -n "$1" ]
```

**Conditional imps:**
- NO `set -eu` (use exit codes for flow control)
- NO functions
- Return 0 for true, 1 for false

---

## Component Relationships

| Component | Phase | Can Use Wizardry | Dependencies |
|-----------|-------|------------------|--------------|
| `install` | 1-2 | ❌ No | Self-contained |
| `invoke-wizardry` | 3 | ❌ No | Loads wizardry |
| Regular spells | 3+ | ✅ Yes | All spells in PATH |

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| `env_clear` in spell | Use `env-clear` (hyphenated) |
| `temp_file` in spell | Use `temp-file` (hyphenated) |
| `cursor_blink` in spell | Use `cursor-blink` (hyphenated) |
| Using full path to spell | Use hyphenated name from PATH |
| `exit` in uncastable spell function | Use `return` |
| Adding function to imp | Imps are flat (no functions) |
| `show_usage()` function | Use inline heredoc in case statement |
| More than 1 helper function in spell | Document in EXEMPTIONS.md |

---

## Function Discipline

**Spells:**
- ≤ 1 helper function if absolutely necessary
- More than 1 helper requires documentation in EXEMPTIONS.md
- --usage is NEVER in a function (always inline)

**Imps:**
- NO functions allowed
- Completely flat, linear code
- This rule is enforced by tests

**Functions vs Commands:**
- Function names: MUST use underscores (`my_function`)
- Spell calls: ALWAYS use hyphens (`my-spell`)
- POSIX shell doesn't allow hyphens in function names

---

## Quick Reference

**Self-contained (no wizardry):** install, detect-posix, detect-distro  
**Loads wizardry:** invoke-wizardry  
**Uses wizardry:** All regular spells (call each other by hyphenated names)

**Golden rule:** ALL wizardry spells call each other by hyphenated names from PATH, NEVER with full paths, NEVER with underscores.
