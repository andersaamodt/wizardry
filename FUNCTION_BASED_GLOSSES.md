# Function-Based Gloss System

## Overview

Wizardry has been converted from **script-based glosses** to **function-based glosses**. This document explains the new architecture and how it works.

## What Changed

### Before (Script-Based Glosses)

- `generate-glosses` created script files in `~/.spellbook/.glossary/`
- Each gloss was a tiny script: `exec parse "spell-name" "$@"`
- `.glossary` directory was prepended to PATH
- Gloss generation ran asynchronously in background
- Scripts executed in subshells

### After (Function-Based Glosses)

- `generate-glosses` outputs shell function definitions and aliases
- First-word gloss functions: `env() { parse "env" "$@"; }`
- Hyphenated aliases: `alias env-or='env_or'`
- Functions/aliases eval'd into current shell
- Gloss generation runs synchronously (must be in current shell)
- No .glossary directory needed

## Architecture

### Three Invocation Methods

Users can invoke spells three ways:

#### 1. Space-Separated (via first-word gloss functions)

```sh
# User types:
env or VAR DEFAULT

# Gloss function:
env() { parse "env" "$@"; }

# Calls:
parse "env" "or" "VAR" "DEFAULT"

# Parse reconstructs command and dispatches to env_or() function
```

#### 2. Hyphenated (via aliases)

```sh
# User types:
env-or VAR DEFAULT

# Alias:
alias env-or='env_or'

# Calls:
env_or VAR DEFAULT  # Direct call to preloaded true-name function
```

#### 3. Underscore (direct true-name invocation)

```sh
# User types:
env_or VAR DEFAULT

# Calls:
env_or VAR DEFAULT  # Direct call to preloaded true-name function
```

### Flow Diagram

```
User Input: "env or VAR DEFAULT"
     ↓
First-Word Gloss: env() { parse "env" "$@"; }
     ↓
Parse: Receives "env or VAR DEFAULT"
     ↓
Parse: Reconstructs command → "env-or"
     ↓
Parse: Checks for preloaded function env_or()
     ↓
Parse: Calls env_or("VAR", "DEFAULT")
     ↓
Result
```

## Implementation Details

### generate-glosses

**Location:** `spells/system/generate-glosses`

**What it does:**
1. Scans all spells and imps in `$WIZARDRY_DIR/spells/`
2. For each multi-word command (e.g., `env-or`):
   - Generates first-word gloss: `env() { parse "env" "$@"; }`
   - Generates hyphenated alias: `alias env-or='env_or'`
3. Processes user synonyms from `.synonyms` and `.default-synonyms`
4. Outputs all definitions to stdout (or `--output FILE`)

**Usage:**
```sh
# Output to stdout
generate-glosses --quiet

# Save to file
generate-glosses --output ~/.wizardry/glosses.sh

# Eval into current shell
eval "$(generate-glosses --quiet)"
```

### invoke-wizardry

**Location:** `spells/.imps/sys/invoke-wizardry`

**What changed:**
1. Removed `.glossary` directory creation
2. Removed PATH manipulation for .glossary
3. Added synchronous gloss generation and eval:
   ```sh
   if _iw_gloss_output=$(generate_glosses --quiet 2>&1); then
     eval "$_iw_gloss_output"
   fi
   ```

**Why synchronous:**
Functions and aliases must be defined in the current shell, not a background process. Background execution would define them in a subshell that exits immediately.

### parse

**Location:** `spells/.imps/lex/parse`

**What changed:**
- Now receives complete command from gloss functions
- Example: `parse "env" "or" "VAR" "DEFAULT"` (not `parse "or" "VAR" "DEFAULT"`)
- Reconstructs command name from arguments
- Dispatches to preloaded functions or finds/sources spell files

**No changes needed:** The existing parse implementation already handles this correctly.

## Benefits

### 1. No Script Files
- No `.glossary` directory to manage
- No hundreds of tiny wrapper scripts
- Cleaner filesystem

### 2. No Subshell Overhead
- Functions execute in current shell
- Faster invocation
- Can modify parent shell environment

### 3. Universal Alias Support
- Aliases work in all shells (bash, zsh, dash, sh)
- No dependency on shell-specific function features
- Hyphenated commands work everywhere via aliases

### 4. Simpler Architecture
- Synchronous loading (no background complexity)
- No need for shell-specific function export
- Easier to debug and understand

### 5. Same Performance
- First-word glosses → parse → preloaded functions (fast path)
- Hyphenated aliases → preloaded functions directly (fastest path)
- True-name functions → direct invocation (fastest path)

## Migration Notes

### For Users
No changes needed! The invocation methods remain the same:
- Space-separated: `env or VAR DEFAULT` ✅
- Hyphenated: `env-or VAR DEFAULT` ✅
- Underscore: `env_or VAR DEFAULT` ✅

### For Developers

**Old way (script-based glosses):**
```sh
# .glossary/env-or script:
#!/bin/sh
exec parse "env-or" "$@"
```

**New way (function-based glosses):**
```sh
# Generated gloss functions:
env() { parse "env" "$@"; }
alias env-or='env_or'
```

**Testing:**
Tests that relied on .glossary directory will need updates to use the new function-based approach.

## Technical Constraints

### Why First-Word Glosses Use Parse

We generate first-word glosses (e.g., `env()`) instead of specific glosses for each command (e.g., `env_or()`) because:

1. **Ambiguity:** The first word doesn't tell us which specific command
   - `env or` → could be `env-or`
   - `env clear` → could be `env-clear`
   - Both start with `env`

2. **Parse solves this:** Parse receives all arguments and reconstructs the command
   - Receives: `"env" "or" "VAR" "DEFAULT"`
   - Reconstructs: `env-or`
   - Dispatches to: `env_or()`

3. **Single gloss per first word:** Only need `env()` gloss, not separate glosses for `env-or`, `env-clear`, etc.

### Why Hyphenated Aliases, Not Functions

**Original plan:** Use functions with hyphens: `env-or() { ... }`

**Problem:** Not all shells support hyphens in function names:
- ✅ Bash: Supports hyphens in function names
- ✅ Zsh: Supports hyphens in function names
- ❌ Dash: Does NOT support hyphens in function names
- ❌ POSIX sh: Does NOT support hyphens in function names

**Solution:** Use aliases instead:
- ✅ All shells support aliases with hyphens
- ✅ Aliases expand to underscore function names: `alias env-or='env_or'`
- ✅ Works everywhere

## Future Enhancements

### Potential Optimizations
1. Cache generated glosses to file for faster startup
2. Lazy-load less common spells
3. Profile and optimize parse dispatch logic

### Not Recommended
1. Return to script-based glosses (adds complexity, no benefit)
2. Attempt persistent shell process (breaks process model)
3. Force hyphenated function names (breaks POSIX compatibility)

## Conclusion

The function-based gloss system provides:
- ✅ Clean architecture (no script files)
- ✅ Fast performance (no subshells)
- ✅ Universal compatibility (aliases work everywhere)
- ✅ Simple implementation (synchronous loading)
- ✅ Maintains all three invocation methods

This is the foundation for wizardry's command invocation going forward.
