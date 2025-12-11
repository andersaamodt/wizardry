# Wizardry Project Exemptions

Documents all deviations from project standards with justification.

## Summary

- **Style**: 330/330 files compliant (2 hardcoded exemptions for doppelganger)
- **Code Structure**: Conditional imps exempt from `set -eu`; imps exempt from `--help`
- **Testing**: Bootstrap scripts can't use wizardry infrastructure
- **CI**: No exemptions - all checks required

---

## 1. Style Exemptions

### Long Lines (>100 chars)

**Rule**: FAIL unless >60% quoted text (strings)

**Automatic Exemptions**: Error messages, prompts, help text (auto-detected by lint-magic)

**Hardcoded Exemptions** (2 files, 2 lines):

1. **`spells/.imps/cond/is` line 13** (156 chars)
   - Case: `empty) if [...]; elif [...]; else ...; fi ;;`
   - Reason: Doppelganger's compile-spell expects case labels on single line
   - Splitting breaks: `empty` → incorrectly renamed to `_empty`

2. **`spells/divination/identify-room` line 260** (~180 chars)
   - Pattern: `case $dir in *dir1*|*dir2*|...|*dirN*) ... ;; esac`
   - Reason: Same doppelganger compilation issue as above

**How to Split Other Long Lines**:
- Pipelines → intermediate variables: `filtered=$(cmd1 | cmd2); result=$(echo "$filtered" | cmd3)`
- Conditionals → separate checks
- Command chains → break at `&&`/`||`

### Mixed Tabs/Spaces

**Status**: ✅ RESOLVED - 8 files converted to 2-space indentation (commit 4463607)

---

## 2. Code Structure Exemptions

### Conditional Imps: No `set -eu`

**Affected**: `spells/.imps/cond/`, `spells/.imps/lex/`, `spells/.imps/menu/`

**Reason**: Return exit codes for flow control (if/&&/||); `set -e` would treat false as error

**Example**:
```sh
#!/bin/sh
# has CMD - test if command available
_has() { command -v "$1" >/dev/null 2>&1; }
case "$0" in */has) _has "$@" ;; esac

# Usage: has git || die "git required"
```

### Imps: No `--help` Required

**Affected**: All `spells/.imps/*`

**Reason**: Micro-helpers; opening comment serves as spec; `--help` would bloat them

---

## 3. Testing Exemptions

### Bootstrap Scripts: No Wizardry Imps

**Affected**: `install`, `spells/install/core/*`

**Reason**: Run before wizardry installed; must be self-contained

### Test-Only Imps: Require `test-` Prefix

**Affected**: `spells/.imps/test/*`

**Reason**: Distinguish test infrastructure from production code

---

## 4. CI Exemptions

**Status**: ✅ None - all checks required (no `continue-on-error` or `allow-failure`)

---

## Adding New Exemptions

1. Exhaust alternatives (logical splitting, helper functions)
2. Document: files, reason, justification, examples
3. Get PR approval
4. Update this file

**Review**: Quarterly (next: 2026-03-10) | **Last Updated**: 2025-12-10
