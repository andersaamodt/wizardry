# Paradigm Conversion Guide

## Overview
This document provides detailed instructions for converting wizardry from the word-of-binding paradigm back to flat-file PATH-based execution.

## Why This Conversion?

The word-of-binding paradigm introduced performance optimization through function preloading, but:
- Executed commands run in subshells without preloaded functions
- Complex zsh compatibility workarounds needed
- Negated the performance benefits
- Added significant complexity

Returning to flat-file execution provides:
- Simpler, more teachable code
- Better alignment with UNIX philosophy
- Easier debugging and maintenance
- All spells just work via PATH

## Conversion Statistics

- **Spell files to convert:** 189
- **Imp files to convert:** 201
- **Total files:** 390+
- **Estimated effort:** Multiple sessions required

## Phase-by-Phase Guide

### Phase 1: Understanding ✅ COMPLETE
See SPIRAL_DEBUG.md for exploration notes.

### Phase 2: Documentation ✅ COMPLETE
This file and SPIRAL_DEBUG.md provide the roadmap.

### Phase 3: Convert Individual Spells

#### Spell Conversion Template

**BEFORE (word-of-binding paradigm):**
```sh
#!/bin/sh
# Description

spell_name_usage() {
  cat <<'USAGE'
Usage: spell-name [options]
Description text.
USAGE
}

spell_name() {
case "${1-}" in
--help|--usage|-h)
  spell_name_usage
  return 0
  ;;
esac

require_wizardry || return 1

set -eu
env_clear

# Main logic here
}

# Castable loading code (30 lines)
if true; then
  # Complex path detection
fi

castable "$@"
```

**AFTER (flat-file paradigm - UPDATED PATTERN WITH 0 FUNCTIONS):**
```sh
#!/bin/sh

# Brief opening comment (for code readers)

# Usage block - ALWAYS at the top, BEFORE --help handler
# This is user-facing documentation that expands on the opening comment
cat <<'USAGE'
Usage: spell-name [options]

Detailed description text with examples.
USAGE

# Help handler - BEFORE set -eu and require-wizardry
# This ensures --help works even if wizardry not installed!
case "${1-}" in
--help|--usage|-h)
  cat <<'USAGE'
Usage: spell-name [options]

Detailed description text with examples.
USAGE
  exit 0
  ;;
esac

# Strict mode - AFTER help handler
set -eu

# Main logic here (no wrappers, no functions!)
```

#### Standard Element Order (CRITICAL):

1. **Shebang** (`#!/bin/sh`)
2. **Opening comment** (brief, for code readers)
3. **Usage block** (detailed, user-facing docs - inline heredoc)
4. **`--help` handler** (BEFORE `set -eu`)
5. **`set -eu`** strict mode
6. **Main logic** (direct execution, no wrappers)

**Why this order matters:**
- `--help` runs BEFORE `set -eu`, `require-wizardry`, etc.
- Help works even if wizardry is not installed
- Help works even if dependencies are missing
- Help works even if something goes wrong
- Users can ALWAYS get help without errors
- Standard location = easy to find = testable via common test

#### Key Changes:
1. **REMOVED** `spell_name_usage()` function (was 1 function)
2. **REMOVED** `spell_name()` wrapper function (was 1 function)
3. **ADDED** inline usage block at top (after opening comment)
4. **Result:** 0 functions instead of 2!
5. Move help handler before `set -eu` (CRITICAL for robustness)
6. Change `return 0` → `exit 0` in help handler
7. Remove `require_wizardry || return 1`
8. Remove `env_clear` or `env-clear`
9. Remove entire castable loading block (~30 lines)
10. Change all `return N` → `exit N` in main flow

#### Conversion Checklist Per Spell:
- [ ] Remove usage function, add inline usage block at top
- [ ] Move help handler before `set -eu`
- [ ] Change help handler to use `exit` not `return`
- [ ] Remove wrapper function
- [ ] Extract main logic to top level
- [ ] Remove `require_wizardry` line
- [ ] Remove `env_clear` line
- [ ] Delete castable loading block (~30 lines)
- [ ] Change `return` to `exit` throughout
- [ ] Test spell execution
- [ ] Test spell --help

### Phase 4: Convert Individual Imps

#### Imp Conversion Template

**BEFORE (function-wrapped):**
```sh
#!/bin/sh
# imp-name ARG - description
set -eu

imp_name() {
  # Implementation
  printf '%s\n' "$1"
}

# Self-execute when run directly
case "$0" in
  */imp-name) imp_name "$@" ;; esac
```

**AFTER (direct execution):**
```sh
#!/bin/sh
# imp-name ARG - description
set -eu

# Implementation (no function wrapper)
printf '%s\n' "$1"
```

#### Key Changes:
1. Remove function wrapper
2. Remove self-execute case statement
3. Keep `set -eu` for action imps
4. Do NOT add `set -eu` for conditional imps (cond/, lex/, menu/)

#### Conversion Checklist Per Imp:
- [ ] Remove function definition
- [ ] Remove self-execute case statement
- [ ] Verify `set -eu` appropriate for imp type
- [ ] Test imp execution

### Phase 5: Remove Word-of-Binding Infrastructure

Files to DELETE:
- [ ] `spells/.imps/sys/invoke-wizardry`
- [ ] `spells/.imps/sys/word-of-binding`
- [ ] `spells/.imps/sys/castable`
- [ ] `spells/.imps/sys/uncastable`
- [ ] `spells/system/generate-glosses`
- [ ] Any gloss-related helper files

### Phase 6: Update PATH Setup

#### In install script:

**OLD approach:**
```sh
# Add invoke-wizardry to rc file
```

**NEW approach:**
```sh
# Add all spell and imp directories to PATH
# Generate PATH additions:
for dir in "$WIZARDRY_DIR"/spells/*; do
  [ -d "$dir" ] || continue
  case "$dir" in
    */.imps|*/.arcana) continue ;;
  esac
  PATH="$dir:$PATH"
done

# Add imp directories
for dir in "$WIZARDRY_DIR"/spells/.imps/*; do
  [ -d "$dir" ] || continue
  PATH="$dir:$PATH"
done

# Add spellbook
PATH="$SPELLBOOK_DIR:$PATH"
export PATH
```

#### Create new rc initialization:

Instead of sourcing invoke-wizardry, add PATH directly:
```sh
# Wizardry PATH setup
if [ -d "$HOME/.wizardry" ]; then
  WIZARDRY_DIR="$HOME/.wizardry"
  # Add all spell directories
  for _dir in "$WIZARDRY_DIR"/spells/*; do
    [ -d "$_dir" ] || continue
    case "$_dir" in */.imps|*/.arcana) continue ;; esac
    PATH="$_dir:$PATH"
  done
  # Add all imp directories
  for _dir in "$WIZARDRY_DIR"/spells/.imps/*; do
    [ -d "$_dir" ] || continue
    PATH="$_dir:$PATH"
  done
  PATH="$HOME/.spellbook:$PATH"
  export WIZARDRY_DIR PATH
fi
```

### Phase 7: Convert Synonyms to Aliases

**OLD (generate-glosses creates gloss files):**
- Read .synonyms file
- Create gloss wrappers in .glossary/
- Glosses call `parse`

**NEW (generate aliases):**
- Read .synonyms file
- Create alias definitions
- Add to rc file or separate aliases file

**Format of .synonyms:**
```
alias_name=target_command
```

**Generate aliases:**
```sh
# In rc file or sourced aliases file
if [ -f "$HOME/.spellbook/.synonyms" ]; then
  while IFS='=' read -r alias_name target || [ -n "$alias_name" ]; do
    [ -n "$alias_name" ] || continue
    case "$alias_name" in \#*) continue ;; esac
    alias "$alias_name"="$target"
  done < "$HOME/.spellbook/.synonyms"
fi
```

### Phase 8: Update Tests

#### test-bootstrap changes:

**OLD:**
- Source invoke-wizardry
- Functions preloaded
- Use function calls

**NEW:**
- Add all spell/imp dirs to PATH
- Direct execution
- No function preloading

```sh
# Add wizardry to PATH
for _dir in "$WIZARDRY_DIR"/spells/*; do
  [ -d "$_dir" ] || continue
  case "$_dir" in */.imps|*/.arcana) continue ;; esac
  PATH="$_dir:$PATH"
done
for _dir in "$WIZARDRY_DIR"/spells/.imps/*; do
  [ -d "$_dir" ] || continue
  PATH="$_dir:$PATH"
done
export PATH
```

#### Test file changes:
- Remove `run_sourced_spell` usage
- Use direct execution or `run_spell`
- No need for function availability checks

### Phase 9: Update EXEMPTIONS.md

After conversion:
1. Recount functions in all spells
2. Most should go from 2 functions → 0 functions
3. Update function discipline section
4. Remove word-of-binding exemptions
5. Document remaining helper functions

Expected changes:
- Most spells: 2 functions → 0 functions (no usage, no wrapper)
- Some spells with helpers: 3-4 functions → 1-2 functions
- Overall: Much simpler codebase

## Batch Conversion Strategy

Given 390+ files to convert:

### Batch 1: Critical Infrastructure (Priority 1)
- [x] Update SPIRAL_DEBUG.md
- [x] Create this guide
- [ ] Remove invoke-wizardry
- [ ] Update install script PATH setup
- [ ] Update test-bootstrap
- [ ] Remove generate-glosses

### Batch 2: Simple Spells (10-15 files)
Convert simplest spells first to establish pattern:
- [x] `arcane/forall` ✅
- [ ] `arcane/copy`
- [ ] `arcane/trash`
- [ ] `divination/detect-distro`
- [ ] Other simple arcane spells

### Batch 3: Core Imps (20-30 files)
Essential imps that spells depend on:
- [ ] `out/say`
- [ ] `out/die`
- [ ] `out/warn`
- [ ] `out/fail`
- [ ] `cond/has`
- [ ] `cond/is`
- [ ] `cond/there`
- [ ] Other frequently-used imps

### Batch 4: System Spells (10-15 files)
- [ ] `system/` directory spells
- [ ] Test after each conversion

### Batch 5: Menu Spells (5-10 files)
Complex but critical:
- [ ] `cantrips/menu`
- [ ] `menu/main-menu`
- [ ] Other menu spells

### Batch 6-N: Remaining Files
Continue in batches of 15-20 files:
- Group by directory
- Test after each batch
- May span multiple PR sessions

## Testing Strategy

After each batch:
1. Run converted spells with `--help`
2. Test basic functionality
3. Run relevant test files
4. Fix any issues before next batch

After all conversions:
1. Full test suite: `./spells/system/test-magic`
2. Test install process
3. Test menu system
4. Verify PATH setup works

## Current Progress

See SPIRAL_DEBUG.md for up-to-date progress tracker.

## Continuing This Work

If picking up this conversion in a new session:

1. Check SPIRAL_DEBUG.md for current status
2. Review this guide
3. Continue from last completed batch
4. Update progress in SPIRAL_DEBUG.md
5. Test incrementally
6. Document any issues or deviations

## Key Principles

1. **Test incrementally** - Don't convert everything at once
2. **Keep it simple** - Flat files, direct execution
3. **Preserve behavior** - Spells should work the same way
4. **Document progress** - Future sessions need clear continuity
5. **Stay focused** - This is a big task, maintain momentum

## Tools and Scripts

See `/tmp/convert-spell.sh` for a helper script (work in progress).

## Questions and Edge Cases

### Q: What about spells that must be sourced (like `colors`)?
A: Keep these as-is, they're special cases documented in EXEMPTIONS.md

### Q: What about complex spells with helper functions?
A: Keep helper functions that are used multiple times, inline single-use helpers

### Q: What about imps used extensively by other spells?
A: Convert them but ensure they work as standalone executables

### Q: What about backwards compatibility?
A: No backwards compatibility needed per requirements - clean break

## Success Criteria

Conversion is complete when:
- [ ] All 189 spell files converted
- [ ] All 201 imp files converted
- [ ] No word-of-binding infrastructure remains
- [ ] PATH setup works correctly
- [ ] Full test suite passes
- [ ] Install process works
- [ ] Menu system functional
- [ ] EXEMPTIONS.md updated
- [ ] Documentation complete

## UPDATED: Even Simpler Spell Pattern - No show_usage() Function!

**Simplified further - usage text inline at standard location:**

```sh
#!/bin/sh

# Brief description of what spell does

case "${1-}" in
--help|--usage|-h)
  cat <<'USAGE'
Usage: spell-name [args]

Description of spell behavior and arguments.
USAGE
  exit 0
  ;;
esac

set -eu

# Main spell logic here
```

**Benefits:**
- **0 functions** instead of 2 (was: show_usage + spell_name, now: neither!)
- Usage text in standard location (right after opening comment, before set -eu)
- Even simpler and more readable
- Inline heredoc - no function call indirection
- Can duplicate usage in error handling if needed (just repeat the heredoc)

**Example with error handling:**
```sh
if [ "$#" -ne 1 ]; then
  cat >&2 <<'USAGE'
Usage: spell-name <arg>

Description.
USAGE
  exit 2
fi
```

**This is as simple as shell scripts can get!**
