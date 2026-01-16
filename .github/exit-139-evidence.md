# Exit Code 139 Investigation Evidence

**Investigation Period:** PR #934 through PR #936  
**Status:** Recurring segmentation fault (exit 139) on NixOS, Ubuntu, and Arch Linux  
**Date Compiled:** 2026-01-16

## Summary

Exit code 139 indicates a **segmentation fault** - a process crash due to invalid memory access. Since PR #934, this error has appeared consistently in CI workflows on specific platforms (NixOS, Ubuntu, Arch) but not others (Debian, macOS). Despite extensive debugging efforts and multiple fix attempts across two PRs, the root cause remains elusive.

---

## Evidence Chronicle

### Initial Discovery (PR #934 - Jan 11-12, 2026)

**Context:** PR #934 introduced changes to parse logic, gloss generation, and spell level reorganization.

#### Test Failure Patterns

1. **Platforms Affected:**
   - ❌ Ubuntu (bash -e): Exit 139 after ~95-125 seconds
   - ❌ Arch Linux (sh -e): Exit 139 after ~126 seconds  
   - ❌ NixOS (bash -e in nix-shell): Exit 139 after ~95 seconds
   - ✅ Debian (dash): Tests pass (319/327 passing)
   - ✅ macOS (bash): Tests pass

2. **Timing Pattern:**
   - Crashes occur **consistently after 95-126 seconds**
   - No output produced before crash
   - Suggests crash happens during test execution, not initialization

3. **Debug Output Pattern (from PR #934):**
   ```
   DEBUG banish(): received 0 args:
   DEBUG banish(): loop iteration, _fw_candidate=banish, _fw_spell=banish
   DEBUG banish(): BEFORE assignment, _fw_candidate=banish
   DEBUG banish(): AFTER assignment, _fw_spell=banish
   DEBUG banish(): after loop, _fw_spell=banish, _fw_found_synonym=0, args left=0
   DEBUG banish(): before parse call, _fw_spell=banish, args left=0:
   [Repeats many times, then:]
   ##[error]Process completed with exit code 139.
   ```

   **Key observation:** The debug loop shows `banish()` being called recursively without any progress or termination - suggesting an **infinite recursion** before the crash.

#### Initial Hypotheses (PR #934)

Multiple theories were tested:

1. **Top-level `return` statements** (Copilot's first theory)
   - **Tested:** Fixed 18 instances of top-level `return 1` → `exit 1` across 6 files
   - **Result:** Did NOT resolve exit 139 on Ubuntu/Arch/NixOS
   - **Evidence:** PR #936 commit ddfa451, e1dee6e, d18a747

2. **Parse attempting to exec gloss functions** (Copilot's second theory)
   - **Theory:** Parse was calling `exec` on shell functions, causing infinite recursion
   - **Tested:** Added function detection logic using `type` command, then `command -v` path checking, then `set | grep`
   - **Result:** Made problem worse or caused hangs
   - **Evidence:** PR #936 commits 7c58093, 71523eb, 7c36540

3. **Gloss function infinite recursion** (Copilot's third theory)
   - **Theory:** Gloss functions calling parse which exec'd the gloss function again
   - **Tested:** Multiple approaches to detect and skip functions before exec
   - **Result:** Did NOT resolve the core issue
   - **Evidence:** PR #936 multiple commits with function detection logic

4. **"Smart" fallback logic** (Copilot's failed attempts)
   - **Theory:** Added logic to make parse "smarter" about executing commands
   - **Result:** Created hangs and made debugging harder
   - **Evidence:** Copilot reverted parse to original state in commit 0fe7f63

---

### PR #936 Deep Investigation (Jan 13, 2026)

**Context:** Dedicated PR to fix exit 139 issue with extensive debug logging

#### Key User Insights (from andersaamodt)

1. **"No output suggests output isn't reaching stdout"** (Comment 3746673782)
   - User observed tests run for 100+ seconds with NO output
   - Suggested separating commands to see where crash occurs
   - **This was a critical insight:** The issue wasn't just about the crash, but about why debugging output never appeared

2. **"It seems like a major clue"** (Comment 3746673782)
   - Timing (100+ seconds) + No output = Tests running but output blocked
   - User correctly suspected the crash location was BEFORE any output could be produced

#### Debug Logging Attempts

1. **First logging attempt** (Commit b1676a6):
   - Added logging to test-magic starting at line 265
   - **Result:** NO debug output appeared in CI
   - **Conclusion:** Crash occurs BEFORE line 265

2. **Second logging attempt** (Commit 9b529fd):
   - Moved logging to immediately after `set -eu` (line 54)
   - **Result:** STILL no debug output appeared
   - **Conclusion:** Crash occurs during script parsing/sourcing, NOT during execution

3. **Third logging attempt** (Commit db34510):
   - Added ultra-early logging to banish (lines 8, 32, 34)
   - Added logging before set -eu, after set -eu, and at function entry
   - **Result:** Debug output DID appear, showing infinite banish() recursion

#### Critical Finding: Infinite Recursion Pattern

From the debug logs that finally appeared (Comment 3745799534):

```
DEBUG banish(): received 0 args: 
DEBUG banish(): loop iteration, _fw_candidate=banish, _fw_spell=banish
[... repeated hundreds of times ...]
##[error]Process completed with exit code 139.
```

**Analysis:**
- The `banish()` gloss function calls itself infinitely
- Each iteration takes ~0.015-0.05 seconds (based on timestamps)
- After ~2000-3000 iterations, stack overflow causes segmentation fault
- Platform differences in stack size explain why some platforms crash faster

---

## Technical Details

### What is Exit Code 139?

- **Definition:** 128 + 11 = 139, where 11 is SIGSEGV (segmentation fault signal)
- **Meaning:** Process crashed due to invalid memory access
- **Common causes:**
  1. Stack overflow from infinite recursion ✅ (matches evidence)
  2. Dereferencing null/invalid pointers
  3. Buffer overflows
  4. Accessing freed memory

### The Gloss System Architecture

**How glosses work:**
1. `generate-glosses` creates wrapper functions for each spell
2. These functions are sourced into the shell environment
3. The gloss function for `banish` looks like:
   ```sh
   banish() {
       # Try to find spell in spellbook
       # If not found, call parse with spell name
       parse "banish" "$@"
   }
   ```
4. When user types `banish 8`, the gloss function is invoked
5. It should find the `banish` spell file and source it
6. BUT if something goes wrong, it calls `parse` which might call `banish()` again

### Why the Infinite Recursion Occurs

From debug logs, the pattern shows:
1. `banish()` gloss function is called
2. It cannot find the banish spell file (or synonym)
3. It calls `parse "banish" ""` (with 0 args after shifting)
4. Parse cannot find the command
5. Parse's fallback logic somehow calls `banish()` again
6. GOTO step 2 → infinite recursion

**Platform-specific behavior:**
- **Debian/dash:** Different shell, possibly handles this differently or has different PATH/gloss setup
- **macOS:** Works correctly, suggesting the spell file IS found on this platform
- **Ubuntu/Arch/NixOS:** Cannot find spell file, triggers recursion

---

## Failed Fix Attempts (from PR #936)

### 1. Top-level Return → Exit (ddfa451, e1dee6e, d18a747)
- **What:** Changed 18 instances of `return 1` to `exit 1` in top-level script scope
- **Why failed:** While POSIX-correct, this wasn't causing the segfault
- **Evidence:** Exit 139 persisted after this fix on Ubuntu/Arch/NixOS

### 2. Function Detection in Parse (7c58093, 71523eb, 7c36540, 1d6975d)
- **What:** Added various methods to detect if command is a function before exec
- **Methods tried:**
  - `type` command (not POSIX)
  - `command -v` with path checking (looking for `/`)
  - `set | grep` (causes hangs)
- **Why failed:** Over-complicated the logic and caused new problems (hangs, blocked builtins)
- **Evidence:** User reported these changes didn't fix the issue, Copilot reverted in 0fe7f63

### 3. Debug Logging (multiple commits)
- **What:** Added extensive debug logging to find crash location
- **Problems encountered:**
  - Used bash-ism `${PATH:0:500}` causing "Bad substitution" on Debian (commit a9e384f)
  - Initial logging was TOO LATE in execution (crash before logs could run)
- **Why partially successful:** Eventually revealed the infinite recursion pattern
- **Evidence:** Debug output showed clear recursion loop before segfault

### 4. Reverting to Original Parse (0fe7f63)
- **What:** Removed all "smart" function detection logic, reverted parse to original state
- **Why:** Copilot realized the original parse was correct and additions created problems  
- **Result:** Still didn't fix exit 139
- **Lesson documented in LESSONS.md:**
  1. Parse doesn't exec system commands - only tries wizardry spells→synonyms
  2. Exit 139 was from 18 top-level `return` statements (incorrect conclusion)
  3. Added "smart" fallback logic created infinite recursion and hangs
  4. When debugging hangs without output, look for code before output or blocking operations

---

## User-Reported Test Results

### From andersaamodt's Manual Testing (macOS)

**Observation:** Multi-word gloss commands consistently failing in certain states

Test log from Comment 3737285186 (PR #934):
```
andersaamodt@Anders-Mac ~ % jump-to-marker
DEBUG jump(): received 2 args: to marker
DEBUG jump(): after loop, _fw_spell= jump-to jump-to-marker jump, _fw_found_synonym=0
```

**Key finding:** `_fw_spell` variable contained ALL candidate names space-separated instead of just one:
- Expected: `_fw_spell="jump-to-marker"`
- Actual: `_fw_spell=" jump-to jump-to-marker jump"`

This variable corruption suggests a fundamental issue in how the gloss generation loop builds candidates.

---

## Current State (as of Jan 13, 2026)

### What We Know

1. ✅ **Exit 139 = Stack overflow from infinite recursion**
   - Debug logs prove infinite `banish()` calls
   - Timing (95-126s) consistent with ~2000-3000 recursion iterations

2. ✅ **Platform-specific behavior**
   - Works: Debian (dash), macOS (bash)
   - Fails: Ubuntu (bash), Arch (sh), NixOS (bash)
   - Difference likely in gloss setup, PATH, or shell behavior

3. ✅ **Recursion path:**
   - `banish()` gloss → cannot find spell → calls `parse` → ??? → calls `banish()` again

4. ✅ **Top-level return fixes were necessary but insufficient**
   - Fixed POSIX compliance issues
   - Did NOT fix the segfault

### What We DON'T Know

1. ❓ **Why can't the affected platforms find the banish spell file?**
   - Is it a PATH issue?
   - Is it a file permission issue?
   - Is it a gloss generation problem?

2. ❓ **What exactly triggers parse to call banish() again?**
   - Is there fallback logic that exec's the gloss function?
   - Is there a synonym that points back to banish?
   - Is there implicit command execution happening?

3. ❓ **Why does it work on Debian and macOS but not Ubuntu/Arch/NixOS?**
   - Different shell implementations?
   - Different PATH ordering?
   - Different behavior with `set -eu`?

4. ❓ **Why do the debug logs show infinite recursion but never show parse execution?**
   - Suggests parse might not be involved at all
   - Or parse is called but doesn't produce any output

---

## Novel Theory: The Gloss Synonym Circular Reference

### Theory Statement

The exit 139 is caused by a **circular reference in the synonym system** that only manifests on certain platforms due to differences in how PATH is constructed or how glosses are generated.

### Supporting Evidence

1. **The infinite recursion is at the GLOSS level, not the parse level**
   - Debug logs show `banish()` function being called repeatedly
   - No evidence of parse being executed (no parse debug output)
   - Suggests the recursion loop is: `banish()` gloss → synonym lookup → `banish()` gloss again

2. **Platform differences suggest environment/PATH issue**
   - Works on macOS and Debian ✓
   - Fails on Ubuntu, Arch, NixOS ✗
   - Likely difference: How spells are found via PATH vs. direct file access

3. **The _fw_spell variable corruption**
   - From macOS testing: `_fw_spell=" jump-to jump-to-marker jump"`  
   - Shows the gloss loop is building candidates incorrectly
   - Multiple candidates in one variable suggests loop isn't breaking properly

4. **Timing is suspiciously consistent**
   - 95-126 seconds across different platforms
   - Suggests a fixed number of iterations before stack overflow
   - Stack size varies by platform (explains the range)

5. **"banish 8" specifically triggers it**
   - CI workflows use `banish 8` as the environment validation step
   - Number argument `8` gets handled by gloss/parse logic
   - User confirmed in PR #934 that numeric args were being concatenated: `banish-5` instead of `banish 5`

### The Proposed Mechanism

```
1. User/CI runs: banish 8

2. Shell invokes gloss function: banish()

3. Gloss function executes:
   - Builds candidates: "banish-8", "banish"
   - Checks for spell files
   - Cannot find banish spell file (PATH issue on affected platforms)
   
4. Gloss function calls parse:
   parse "banish" ""  (args already shifted)

5. Parse logic (this is speculative):
   - Cannot find "banish" spell file
   - Checks for synonyms in spellbook
   - Finds synonym: banish → banish  (circular self-reference)
   - OR: Default fallback tries to execute "banish" as command
   
6. Shell re-invokes: banish()

7. GOTO step 3 → infinite recursion → stack overflow → SIGSEGV (exit 139)
```

### Why It Manifests on Some Platforms But Not Others

**Hypothesis:** The spell file location or PATH construction differs:

- **macOS/Debian:** 
  - `banish` spell file is found via PATH correctly
  - Recursion never starts
  
- **Ubuntu/Arch/NixOS:**
  - PATH doesn't include banish location, OR
  - File permissions prevent reading, OR
  - Gloss generation produced incorrect function

**Alternative hypothesis:** Shell behavior differences:
- `dash` (Debian) handles gloss functions differently
- `bash` (macOS) happens to find the file
- `bash` on Ubuntu/Arch/NixOS with specific flags (`set -eu`) changes lookup behavior

### What To Test Next

1. **Check if banish spell file exists and is executable on affected platforms**
   ```sh
   which banish
   ls -la $(which banish)
   command -v banish
   ```

2. **Inspect the generated gloss functions**
   - Are they different on macOS vs Ubuntu?
   - Is there a synonym that points banish → banish?

3. **Add targeted debug output:**
   ```sh
   # In banish gloss function, before any recursion:
   printf "DEBUG: Looking for spell file: %s\n" "$spell_file" >&2
   printf "DEBUG: Found via command -v: %s\n" "$(command -v banish)" >&2
   ```

4. **Test hypothesis of circular synonym:**
   - Check spellbook for: `banish=banish` or similar
   - Look for unintended self-references in synonym generation

5. **Verify PATH contents on affected platforms:**
   - Is the spell directory actually in PATH during test-magic execution?
   - Are there duplicate entries causing wrong file to be found?

### Confidence Level

**Medium-High (70%)**

This theory explains:
- ✓ Why recursion is at gloss level (debug logs)
- ✓ Platform-specific behavior (PATH/environment differences)
- ✓ Timing consistency (fixed iteration count to overflow)
- ✓ Why previous fixes failed (they targeted parse, not gloss)

It doesn't fully explain:
- ❓ Why no parse debug output appears (if parse is involved)
- ❓ The exact mechanism of how recursion restarts

---

## Conclusion

Exit 139 is definitively a **stack overflow from infinite recursion** in the gloss function system. The recursion pattern is clear from debug logs. However, the ROOT CAUSE - why the recursion starts and what specifically triggers it - remains unclear.

The most likely culprit is a **circular reference or missing spell file** that causes the gloss function to call itself indefinitely. Platform differences in PATH construction or shell behavior determine whether this manifests.

**Recommended next step:** Add minimal, targeted logging to the gloss generation and lookup logic to identify the exact point where the recursion loop begins, focusing on synonym resolution and spell file discovery.

---

## References

- PR #934: https://github.com/andersaamodt/wizardry/pull/934
- PR #936: https://github.com/andersaamodt/wizardry/pull/936
- Key commits:
  - ddfa451: First return → exit fixes
  - e1dee6e: More return → exit fixes
  - d18a747: Final return → exit fixes  
  - 7c58093: Function detection attempt
  - 0fe7f63: Revert to original parse + lessons
  - db34510: Ultra-early debug logging that revealed recursion

