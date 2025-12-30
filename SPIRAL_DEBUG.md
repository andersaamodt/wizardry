# SPIRAL_DEBUG.md - Glossary Generation Debugging Spiral

## Problem Statement
On macOS with zsh, `invoke-wizardry` fails to generate glosses for wizard spells, resulting in commands like `menu` and `main-menu` not being available. Background job exits with code 1.

## Root Cause Journey

### Iteration 1: find -executable (BSD Incompatibility)
**Hypothesis:** BSD find on macOS doesn't support `-executable` flag  
**Change:** Replaced `find -executable` with `find -perm /111`  
**Result:** ❌ Still failing - this wasn't the root cause  
**Commit:** 43a4384

### Iteration 2: Hyphenated vs Underscore Function Names  
**Hypothesis:** generate-glosses using hyphenated imp names that don't work as functions in POSIX sh  
**Change:** Changed all imp calls from hyphenated (`require-wizardry`) to underscore (`require_wizardry`)  
**Result:** ❌ Still failing - functions not available in background job  
**Commits:** 8981d85, eead531

### Iteration 3: PATH Inheritance
**Hypothesis:** Background job not inheriting PATH with imp directories  
**Change:** Added bootstrap code to generate-glosses to add imp dirs to PATH  
**Result:** ❌ Violated architecture requirement (only glossary should be in PATH)  
**Commit:** bade4fd (later reverted)

### Iteration 4: Execution Order
**Hypothesis:** Gloss generation starting before spells preloaded  
**Change:** Moved gloss generation to run AFTER spell preloading  
**Result:** ❌ Order was correct, not the issue  
**Learning:** Added extensive debug logging

### Iteration 5: Curly Braces in Background Job
**Hypothesis:** `{ command & }` preventing function inheritance in zsh  
**Change:** Removed curly braces, just `command &`  
**Result:** ❌ Still failing - zsh fundamentally doesn't inherit functions to background jobs  
**Commit:** 0d22f76

### Iteration 6: Zsh Function Inheritance (Root Cause #1 Found!)
**Hypothesis:** Zsh doesn't inherit functions to background jobs (unlike bash/sh)  
**Diagnostic:** Added function availability checks in background job  
**Result:** ✅ Confirmed - all functions reported as "NO"  
**Commits:** 092a33b (diagnostics), 18cab56 (attempted fix)

### Iteration 7: Capturing Functions in Subshell
**Hypothesis:** `command -v` being called INSIDE subshell where functions don't exist  
**Change:** Move function capture to PARENT shell before entering subshell  
**Result:** ❌ Still captured 0 functions  
**Commit:** 6523c3c

### Iteration 8: ANSI-C Quoting ($'\n') 
**Hypothesis:** `$'\n'` bash-ism corrupting function definitions string in POSIX sh  
**Change:** Use literal newlines instead of `$'\n'`  
**Result:** ❌ Still captured 0 functions - string syntax wasn't the issue  
**Commit:** 40bfd40

### Iteration 9: command -v Unreliability in Zsh
**Hypothesis:** `command -v` unreliable for detecting functions in zsh  
**Change:** Call `functions` command directly without `command -v` check  
**Result:** ❌ Still captured 0 functions  
**Commit:** c6e6e6b

### Iteration 10: Zsh Word Splitting (Root Cause #2 Found!)
**Hypothesis:** For loop not iterating - treating entire string as single item  
**Diagnostic Output:**
```
[invoke-wizardry] DEBUG:   Function not found: generate_glosses require_wizardry env_or env_clear temp_file cleanup_file on_exit die warn fail say success info step debug has there is yes no empty nonempty cleanup_dir make_tempdir
```

**Analysis:**
1. **Problem:** The debug message shows ALL function names on ONE line in a single printf call
2. **Meaning:** `$_func` is expanding to the entire space-separated list, NOT iterating one at a time
3. **Root Cause:** Zsh doesn't perform word splitting in for loops by default (unlike bash/sh)
4. **Zsh Behavior:** Without `SH_WORD_SPLIT` option, `for x in $var` treats `$var` as a single word even if it contains spaces

**Key Learning:**
- Bash/sh: `for x in $var` splits on IFS (spaces by default)
- Zsh: `for x in $var` does NOT split unless `setopt SH_WORD_SPLIT` is set
- This is a fundamental difference in how zsh handles parameter expansion
- The function names in `$_iw_export_funcs` were correct (underscore versions)
- The loop just wasn't iterating over them!

### Solution (Final)
Enable word splitting in zsh for the for loop:

```sh
# CRITICAL: In zsh, enable word splitting for the for loop
# Zsh doesn't split on spaces by default (unlike sh/bash)
if [ -n "${ZSH_VERSION-}" ]; then
  setopt SH_WORD_SPLIT
fi

for _func in $_iw_export_funcs; do
  # Now $_func will be each individual function name
  _iw_func_def="$(functions "$_func" 2>/dev/null || echo '')"
  if [ -n "$_iw_func_def" ]; then
    # Append function definition
  fi
done

# Restore zsh word splitting behavior to default
if [ -n "${ZSH_VERSION-}" ]; then
  unsetopt SH_WORD_SPLIT
fi
```

This is the actual root cause - everything else was correct, but the loop wasn't iterating!

## Architecture Insights

### Function Naming Convention
1. **File names:** Use hyphens (`require-wizardry`, `env-clear`)
2. **Function names:** Use underscores (`require_wizardry`, `env_clear`)
3. **Glosses:** User-facing hyphenated commands that call `parse` which finds functions
4. **word_of_binding:** Converts hyphenated names to underscores when loading

### Zsh Background Job Behavior
- Zsh does NOT inherit shell functions to background jobs (fundamental difference from bash/sh)
- Functions must be explicitly re-eval'd in the subshell using `functions` command to capture definitions
- The `functions` builtin outputs the complete function definition including the function name

### Testing Gap
- Tests run on bash/sh (where function inheritance works)
- macOS-specific zsh behavior not caught by CI
- Need platform-specific tests or zsh in CI environment

## Lessons Learned

1. **Debug Early:** Extensive debug logging identified issues quickly
2. **Test Assumptions:** `command -v` behaves differently across shells
3. **Name Conversions:** Always account for hyphen → underscore conversion  
4. **Platform Differences:** Zsh has fundamentally different subprocess model than bash
5. **CI Coverage:** Tests passing doesn't mean it works on all platforms
6. **Read Architecture Docs:** The glossary/function architecture was well-documented but AI didn't fully internalize the naming convention

## Future Prevention

1. Add zsh to CI environment for cross-shell testing
2. Document shell-specific behaviors more explicitly
3. Test both execution patterns (direct + background job) for all spells
4. Add warnings when functions expected but not found
5. Consider simpler architecture (avoid relying on function inheritance)
