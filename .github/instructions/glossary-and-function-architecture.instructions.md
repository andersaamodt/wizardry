# Glossary and Function Architecture Instructions

applyTo: "spells/**,.tests/**,spells/.imps/**"

## CRITICAL: Understanding Wizardry's Function and Gloss Architecture

This document explains how functions, glosses, and PATH work together in wizardry. **Read this completely before making changes to spells, imps, or the glossary system.**

### Core Architecture Principles

1. **Spells and imps define underscore-named functions** (`require_wizardry`, `env_or`, `menu`)
2. **Glosses provide hyphenated commands** for user-facing access (`require-wizardry`, `env-or`, `main-menu`)
3. **invoke-wizardry preloads functions** via word_of_binding (not PATH)
4. **Only the glossary directory is added to PATH** (not imp directories)
5. **Background jobs must call functions** (not execute scripts) to access preloaded imps

### Why This Architecture Exists

**Problem:** POSIX sh (dash) doesn't support hyphens in function names.

**Solution:** 
- Imps define `function_name()` with underscores
- Glosses create `function-name` commands that call `parse`
- word_of_binding loads functions and creates hyphenated wrappers (when supported)

### Function Naming Convention

```sh
# IMP FILE: spells/.imps/sys/require-wizardry
require_wizardry() {   # ← Underscore name (ALWAYS works)
  # Implementation
}

# Self-execute when run as command
case "$0" in
  */require-wizardry) require_wizardry "$@" ;; esac
```

**Key points:**
- Function name uses underscores: `require_wizardry`
- File name uses hyphens: `require-wizardry`
- When executed as `./require-wizardry`, the case matches and calls the function
- When sourced via word_of_binding, the function is defined

### How word_of_binding Works

```sh
# Load an imp as a function
word_of_binding "require-wizardry"

# This defines:
# 1. require_wizardry() function (always)
# 2. require-wizardry() wrapper (only if shell supports hyphens)
```

**On bash/zsh:** Both `require_wizardry` and `require-wizardry` work
**On sh/dash:** Only `require_wizardry` works

### How Glosses Work

```sh
# File: ~/.spellbook/.glossary/require-wizardry
#!/bin/sh
exec parse "require-wizardry" "$@"
```

**Glosses are commands** that invoke `parse`, which then:
1. Checks if function is preloaded
2. If yes, calls the function
3. If no, finds and executes the script

### PATH Setup

| Component | Added to PATH? | Why |
|-----------|----------------|-----|
| Glossary directory | ✅ YES | User-facing commands |
| Imp directories | ❌ NO | Functions preloaded instead |
| Spell directories | ❌ NO | Functions preloaded instead |

**Reason:** Adding imp/spell dirs to PATH would be slow (hundreds of directories). Preloading essential functions is faster.

### When to Use Underscore vs Hyphenated Names

| Context | Use | Example |
|---------|-----|---------|
| **Inside spells** | Underscore | `require_wizardry \|\| return 1` |
| **Inside imps** | Underscore | `env_or SPELLBOOK_DIR "$HOME/.spellbook"` |
| **User commands** | Hyphenated (via gloss) | `$ require-wizardry` |
| **Tests (when imps in PATH)** | Hyphenated | `require-wizardry` (legacy) |
| **Tests (modern)** | Use sourced spells | `run_sourced_spell` |

### Background Jobs and Functions

**CRITICAL:** Background jobs inherit functions if run in the same shell, but NOT if executed as scripts.

```sh
# ✅ CORRECT: Call function in background
my_function() {
  echo "Works!"
}
{ my_function & }  # ✅ Function is available

# ❌ WRONG: Execute script in background  
./my-script &      # ❌ Script runs in new process, no functions
```

**For wizardry:**
```sh
# ✅ CORRECT (invoke-wizardry pattern)
generate_glosses --quiet &  # Calls preloaded function

# ❌ WRONG
"$WIZARDRY_DIR/spells/system/generate-glosses" --quiet &  # No functions!
```

### Chicken-and-Egg Problem: generate-glosses

**Problem:** generate-glosses creates glosses, but needs imps to run. How can it use imps before glosses exist?

**Solution:** generate-glosses is preloaded by invoke-wizardry and called as a function (not script), giving it access to preloaded imp functions.

```sh
# invoke-wizardry preloads imps
word_of_binding "require-wizardry"
word_of_binding "env-or"
# ... etc

# invoke-wizardry preloads generate-glosses
word_of_binding "generate-glosses"

# invoke-wizardry calls function in background
generate_glosses --quiet &  # ✅ Has access to all preloaded imps
```

### Testing Spells That Use Underscore Functions

**Old way (doesn't work anymore):**
```sh
run_spell "spells/system/generate-glosses" --quiet  # ❌ Executes script, no functions
```

**New way:**
```sh
run_sourced_spell generate-glosses --quiet  # ✅ Sources and calls function
```

**Why:** `run_sourced_spell` sources invoke-wizardry (which preloads imps), then calls the spell function. This mirrors production usage.

### Common Mistakes to Avoid

#### Mistake 1: Adding Imp Directories to PATH

```sh
# ❌ WRONG
PATH="/path/to/imps/sys:/path/to/imps/out:$PATH"
generate-glosses --quiet
```

**Why wrong:** Violates architecture. Only glossary should be in PATH.

**Correct approach:**
```sh
# ✅ CORRECT: Preload functions
word_of_binding "require-wizardry"
word_of_binding "env-or"
# ... then call spell function
generate_glosses --quiet
```

#### Mistake 2: Executing Scripts in Background

```sh
# ❌ WRONG
"$WIZARDRY_DIR/spells/system/generate-glosses" --quiet &
```

**Why wrong:** Creates new process, doesn't inherit preloaded functions.

**Correct approach:**
```sh
# ✅ CORRECT: Call preloaded function
generate_glosses --quiet &
```

#### Mistake 3: Using Hyphenated Names in Spell Code

```sh
# ❌ WRONG (in spell code)
require-wizardry || return 1
value=$(env-or SPELLBOOK_DIR "$HOME/.spellbook")
```

**Why wrong:** Hyphenated function names don't work on POSIX sh. Hyphenated commands only work when in PATH (tests) or via glosses (users).

**Correct approach:**
```sh
# ✅ CORRECT: Use underscore names
require_wizardry || return 1
value=$(env_or SPELLBOOK_DIR "$HOME/.spellbook")
```

#### Mistake 4: Testing Script Execution Instead of Function Calls

```sh
# ❌ WRONG: Tests script execution (old pattern)
test_my_spell() {
  run_spell "spells/system/my-spell" --arg
  assert_success
}
```

**Why wrong:** If spell uses underscore functions, script execution will fail (no functions available).

**Correct approach:**
```sh
# ✅ CORRECT: Tests function call (new pattern)
test_my_spell() {
  run_sourced_spell my-spell --arg
  assert_success
}
```

### Test Environment Setup

The test-bootstrap sets up the environment differently than production:

**test-bootstrap:**
1. Adds imp directories to PATH (legacy support)
2. Preloads imp functions via word_of_binding (modern support)
3. Both hyphenated commands and underscore functions work

**Production (invoke-wizardry):**
1. Does NOT add imp directories to PATH
2. Only adds glossary directory to PATH
3. Preloads imp functions via word_of_binding
4. Hyphenated names available via glosses

### Migration Checklist

When updating a spell to use modern architecture:

- [ ] Change imp calls to underscore names (`require-wizardry` → `require_wizardry`)
- [ ] Change `. imp-name` to `imp_name` (call function, don't source)
- [ ] Ensure spell is preloaded in invoke-wizardry (check spell-levels)
- [ ] Update tests to use `run_sourced_spell` instead of `run_spell`
- [ ] Verify tests pass
- [ ] Verify background jobs work (if applicable)

### Quick Reference

| Need | Solution |
|------|----------|
| Use imp in spell | Call underscore function: `require_wizardry` |
| Use imp in test | Either hyphenated command (PATH) or underscore (function) |
| Run spell in background | Call preloaded function: `generate_glosses &` |
| Test spell with imps | Use `run_sourced_spell spell-name` |
| Add new imp | Define `imp_name()` function, file named `imp-name` |
| User command | Create gloss (auto-generated by generate-glosses) |

### Debugging

**Problem:** "require_wizardry: not found"

**Cause:** Spell using underscore function but function not preloaded.

**Solution:**
1. Check if spell is being executed as script (wrong) or called as function (correct)
2. If test: Use `run_sourced_spell` instead of `run_spell`
3. If background job: Call function, not script file
4. If neither: Ensure invoke-wizardry preloaded the imp

**Problem:** "require-wizardry: not found"

**Cause:** Hyphenated command not in PATH and not preloaded.

**Solution:**
1. Change to underscore name: `require_wizardry`
2. Or ensure glossary is in PATH (production)
3. Or ensure imp directories in PATH (tests only)

**Problem:** Background job fails with "command not found"

**Cause:** Executing script instead of calling function.

**Solution:** Change from `"$WIZARDRY_DIR/spells/spell" &` to `spell_function &`

### See Also

- `.github/instructions/spells.instructions.md` - Spell writing guide
- `.github/instructions/imps.instructions.md` - Imp guidelines
- `.github/instructions/castable-uncastable-pattern.instructions.md` - Self-execute pattern
- `.github/instructions/tests.instructions.md` - Testing framework
