# Merge Conflict Resolution Guide

## Conflict in `spells/spellcraft/lint-magic`

### Location
Lines approximately 186-220 in the POSIX compliance check section.

### Conflict Description
The merge conflict occurs between two different approaches for handling checkbashisms output:

**Current Branch (copilot/update-verify-posix-output):** ✓ KEEP THIS
- Captures full checkbashisms output to a temp file
- Displays ALL violations inline with detailed reasons
- Shows line numbers and specific violation types
- Provides actionable error messages

**Incoming Branch (main):** ✗ DISCARD THIS
- Checks for bashisms and uses exemption logic
- Shows generic "run checkbashisms for details" message
- Less helpful for debugging

### Resolution Decision

**Accept CURRENT (ours)** - Keep the implementation from `copilot/update-verify-posix-output`

### Why This Resolution Is Correct

1. **Better User Experience**: The current implementation shows all violations inline instead of requiring users to run checkbashisms manually
2. **Already Tested**: Test #24 validates that all violations are shown with detailed reasons
3. **No Exemption Feature**: The exemption checking code has no documentation or usage in the codebase
4. **Consistent with Branch Goals**: This branch was created to improve error messages

### Resolution Commands

If you encounter this conflict during a merge or rebase:

```bash
# Accept current version (ours)
git checkout --ours spells/spellcraft/lint-magic
git add spells/spellcraft/lint-magic
git merge --continue  # or git rebase --continue
```

### Expected Code After Resolution

The resolved code should have this structure in the `else` block (starting around line 192):

```sh
else
  # Run checkbashisms and capture output
  # Use a more reliable temp file method if temp-file fails
  bashisms_tmp=$(temp-file lint-magic-bashisms 2>/dev/null) || {
    # Fallback: use same logic as temp-file imp
    if [ -n "${WIZARDRY_TMPDIR-}" ] && [ -d "$WIZARDRY_TMPDIR" ]; then
      bashisms_tmp="${WIZARDRY_TMPDIR}/lint-magic-bashisms.$$"
    elif [ -n "${TMPDIR-}" ] && [ -d "$TMPDIR" ]; then
      bashisms_tmp="${TMPDIR}/lint-magic-bashisms.$$"
    else
      bashisms_tmp="/tmp/lint-magic-bashisms.$$"
    fi
  }
  
  if ! checkbashisms -f "$path" >"$bashisms_tmp" 2>&1; then
    posix_failures=$((posix_failures + 1))
    # Capture all violations with reasons
    posix_fail_msg="FAIL $target:"
    while IFS= read -r violation_line; do
      posix_fail_msg="${posix_fail_msg}
  ${violation_line}"
    done <"$bashisms_tmp"
    posix_failed_list="${posix_failed_list}${posix_fail_msg}
"
  fi
  
  # Clean up temp file
  if [ -f "$bashisms_tmp" ]; then
    rm -f "$bashisms_tmp"
  fi
fi
```

### Output Comparison

**Before (main branch):**
```
Failed POSIX checks:
FAIL script.sh: POSIX compliance violation (run checkbashisms for details)
```

**After (current branch):**
```
Failed POSIX checks:
FAIL script.sh:
  possible bashism in script.sh line 18 (alternative test command ([[ foo ]] should be [ foo ])):
  [[ -n "${1-}" ]]
  possible bashism in script.sh line 19 ('function' is useless):
  function myfunc() {
```

### Related Changes
This resolution is consistent with other improvements in this branch:
- Added descriptive error messages to test #24
- Installed checkbashisms natively in macOS CI workflow
- Moved checkbashisms to level 21 where it's needed

All these changes work together to provide better error reporting for POSIX compliance issues.
