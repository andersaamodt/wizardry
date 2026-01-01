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

The glossary system uses the `parse` imp as the central command dispatcher.

#### Parse Imp Architecture

The `parse` imp (`spells/.imps/lex/parse`) is the command execution engine that:
1. **Prevents infinite recursion** via `WIZARDRY_PARSE_DEPTH` counter (max depth: 5)
2. **Reconstructs multi-word commands** from space-separated input
3. **Searches for commands** in priority order:
   - Preloaded functions (fastest)
   - Multi-word wizardry spells (before single-word)
   - Single-word wizardry spells
   - System commands in PATH (glossary excluded)

#### Multi-Word Command Reconstruction

Parse supports natural language-like invocation by reconstructing hyphenated commands:

```sh
# User types:  env or VAR DEFAULT
# Gloss calls: parse "env" "or" "VAR" "DEFAULT"
# Parse tries:
#   1. env_or_VAR_DEFAULT (4-word function)
#   2. env_or_VAR (3-word function)
#   3. env_or (2-word function) ✓ MATCH
#   4. env (1-word function)
# Result: Calls env_or("VAR", "DEFAULT")
```

**Priority order** (longest match wins):
1. 4-word function: `env_or_VAR_DEFAULT`
2. 3-word function: `env_or_VAR`
3. 2-word function: `env_or` ← matches here
4. 1-word function: `env`

After finding a match, parse shifts the matched words off and passes remaining args to the function.

#### Parse Self-Reference Handling

Parse has special handling for `parse "parse" ...`:
- Shows help text with `--help`
- Returns success (exit 0) otherwise
- Prevents infinite loops when called via its own gloss

#### Recursion Prevention

```sh
# Each parse call increments WIZARDRY_PARSE_DEPTH
# Depth limit prevents circular gloss references:
# gloss-a → parse "gloss-b" → parse "gloss-a" → ERROR (depth 5)
```

### How Glosses Work (File-Based - Legacy)

**Note:** Modern wizardry uses function-based glosses (see generate-glosses). File-based glosses are legacy.

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

### invoke-wizardry Initialization Sequence

The invoke-wizardry initialization follows a carefully ordered sequence:

#### Phase 1: Environment Setup
1. **Baseline PATH**: Set minimal PATH for basic commands (especially for macOS)
2. **Detect WIZARDRY_DIR**: Find installation directory from script path
3. **Set SPELLBOOK_DIR**: User's spell directory (`~/.spellbook`)

#### Phase 2: word-of-binding Bootstrap
```sh
# Load word-of-binding first (it's special - needed to load everything else)
WIZARDRY_SOURCE_WORD_OF_BINDING=1 . "$_iw_wob" 2>/dev/null || :
```

**Why `WIZARDRY_SOURCE_WORD_OF_BINDING=1`?**
- word_of_binding is a function, but needs to be sourced without arguments
- Setting this flag skips the self-execute block
- The function definition is then available for loading other imps

#### Phase 3: Preload Imps (Levels 0-3)
Uses `spell-levels` imp to determine which imps to load:
- **Level 0**: POSIX & Platform (no imps)
- **Level 1**: Wizardry Installation (require-wizardry, env-or, die, warn, etc.)
- **Level 2**: Glossary System (parse, find-executable)
- **Level 3**: Menu System (menu helpers)

For each imp:
```sh
word_of_binding "imp-name" 2>/dev/null || :
```

This creates:
- `imp_name()` function (always)
- `imp-name()` wrapper (if shell supports hyphens)

#### Phase 4: Preload Spells (Levels 0-3)
Similar to imps, loads essential spells:
- **Level 0**: detect-posix, detect-distro, verify-posix
- **Level 1**: banish, validate-spells
- **Level 2**: generate-glosses
- **Level 3**: menu, main-menu, colors, cursor/terminal helpers

#### Phase 5: Generate Glosses
```sh
# Generate function-based glosses (synchronous - must run in current shell)
if command -v generate_glosses >/dev/null 2>&1; then
  if _iw_gloss_output=$(generate_glosses --quiet 2>&1); then
    eval "$_iw_gloss_output"  # Load functions and aliases into shell
  fi
fi
```

**What generate-glosses creates:**
1. **First-word gloss functions**: `env() { parse "env" "$@"; }`
   - Enables space-separated invocation: `env or VAR DEFAULT`
2. **Full-name aliases**: `alias env-or='env_or'`
   - Enables hyphenated invocation: `env-or VAR DEFAULT`
3. **Synonym aliases**: From `.synonyms` and `.default-synonyms` files

**Why synchronous (not background)?**
- Functions and aliases must be defined in the current shell
- Background process can't modify parent shell environment
- User needs commands available immediately

#### Phase 6: Verification
Check that essential spells loaded:
```sh
# Verify menu is available (required for wizardry to function)
if ! command -v menu >/dev/null 2>&1; then
  printf 'invoke-wizardry: ERROR - failed to load menu spell\n' >&2
  return 1
fi
```

### invoke-wizardry Design Notes

**Preloading vs PATH:**
- Preloading ~100 functions is faster than adding ~50 directories to PATH
- PATH lookups scale O(n*m) where n=directories, m=executions
- Function calls scale O(1) after initial load

**ZSH Compatibility:**
- Uses `setopt SH_WORD_SPLIT` for for-loops over space-separated lists
- ZSH doesn't split on spaces by default (unlike sh/bash)
- Restored after invoke_wizardry completes

**Error Handling:**
- Uses permissive mode (`set +eu`) since sourced into user's shell
- Failures logged to stderr but don't terminate shell
- Missing spells/imps logged with `✗ Failed` but don't stop initialization

### Chicken-and-Egg Problem: generate-glosses (Summary)

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

**Problem:** word-of-binding fails with "failed to prepare module"

**Causes and Solutions:**
1. **Awk extraction fails**: Check that the spell defines a function (not just inline code)
2. **Awk exits with error code**: The brace_delta function should use `return n - m`, NOT `exit n - m`
3. **Function pattern not matched**: Ensure function uses one of these patterns:
   - `function_name() { ... }`
   - `function_name() {` (header on own line)
   - `function function_name() { ... }`

**Problem:** Test file exits immediately when sourced

**Cause:** Inline code with `set -eu` and `exit` statements in boot imps.

**Solution:** Boot imps must define functions and use self-execute guards:
```sh
# ✅ CORRECT
my_boot_imp() {
  # Function body
  return 0
}
case "${0##*/}" in
  my-boot-imp) my_boot_imp "$@" ;; esac

# ❌ WRONG - exits when sourced
set -eu
exit 0
```

### Common Implementation Bugs (Fixed)

These bugs were present in the codebase and have been fixed:

1. **word-of-binding awk exit bug** (Fixed in commit 4ade880)
   - **Bug**: `exit n - m` in awk brace_delta function
   - **Impact**: Awk terminated with exit code instead of returning value
   - **Fix**: Changed to `return n - m`
   - **Test**: parse-gloss-recursion now passes

2. **word-of-binding inline code** (Fixed in commit 5cdeb3a)
   - **Bug**: word-of-binding had no function definition, just inline code
   - **Impact**: When sourced by test-bootstrap, it required arguments
   - **Fix**: Wrapped in `word_of_binding()` function with self-execute guard
   - **Test**: All tests can now load word-of-binding

3. **Boot imps with inline exit** (Fixed in commit 5cdeb3a)
   - **Bug**: skip-if-compiled, skip-if-uncompiled had inline `exit 0`
   - **Impact**: Test files exited immediately when sourcing test-bootstrap
   - **Fix**: Wrapped in functions with self-execute guards
   - **Test**: Tests no longer exit during bootstrap

4. **Parse file not executable** (Fixed in commit 5cdeb3a)
   - **Bug**: parse imp had mode 644 instead of 755
   - **Impact**: Direct execution of parse failed
   - **Fix**: Added execute permission
   - **Test**: parse-gloss-recursion can now execute parse

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
