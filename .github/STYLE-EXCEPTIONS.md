# Style Check Exceptions

This document tracks temporary exceptions to wizardry's style checks and provides justification for each.

## Status

As of the latest commit, all style checks in `lint-magic` are now **required** (previously some were warnings only):
- Mixed tabs and spaces indentation: **REQUIRED** (0 failures)
- Lines exceeding 100 characters: **REQUIRED** (87 failures remaining)
- Echo usage (prefer printf): **REQUIRED**

## Current Exceptions

### Long Lines (> 100 characters)

**Status**: 87 files currently fail this check
**Justification**: These files have lines exceeding 100 characters that require manual review and refactoring to break into shorter, more readable lines.

**Common Patterns**:
1. Menu commands with many arguments (e.g., `menu "$opt1" "$opt2" ... "$opt15"`)
2. Long printf/error messages
3. Long command pipelines
4. Long URL strings or file paths

**Action Plan**:
- Fix systematically by breaking lines with backslash continuation
- For menu commands: split arguments across multiple lines
- For long strings: consider if they can be broken without harming readability
- For URLs and paths: evaluate if shortening is practical

**Target**: Reduce to 0 exceptions

### Files Requiring Long Line Fixes

The following files currently have lines exceeding 100 characters. Each needs manual review:

```
spells/.arcana/bitcoin/bitcoin-status
spells/.arcana/bitcoin/change-bitcoin-directory
spells/.arcana/bitcoin/configure-bitcoin
spells/.arcana/bitcoin/install-bitcoin
spells/.arcana/bitcoin/repair-bitcoin-permissions
spells/.arcana/bitcoin/uninstall-bitcoin
spells/.arcana/core/core-menu
spells/.arcana/core/install-checkbashisms
spells/.arcana/core/install-dd
```

(87 files total - see `lint-magic` output for complete list)

## Historical Exceptions

### Mixed Tabs and Spaces (RESOLVED)

**Previous Status**: 8 files had mixed tabs and spaces
**Resolution**: Fixed in commit [hash] by converting all tabs to 2 spaces
**Files Fixed**:
- spells/.arcana/bitcoin/bitcoin-menu
- spells/.arcana/bitcoin/configure-bitcoin
- spells/.arcana/mud/handle-command-not-found
- spells/cantrips/install-service-template
- spells/cantrips/memorize
- spells/cantrips/spellbook-store
- spells/spellcraft/forget
- spells/translocation/jump-to-marker

### Lint-Magic Tab Detection Bug (RESOLVED)

**Issue**: The `check_inconsistent_indentation` function used `'\t'` in single quotes, which doesn't expand to a tab character, causing the check to never find tabs.
**Resolution**: Fixed in commit [hash] by using `tab=$(printf '\t')` and double quotes in the grep pattern.

## Philosophy

Wizardry aims for 100% compliance with all style checks. Exceptions should be:
1. **Temporary**: Have a plan to resolve
2. **Justified**: Clear reason why the exception is needed
3. **Documented**: Listed here with rationale

## How to Fix Long Lines

### Menu Commands
```sh
# Before (150+ characters)
menu "$opt1" "$opt2" "$opt3" "$opt4" "$opt5" "$opt6" "$opt7" "$opt8" "$opt9" "$opt10" "$opt11" "$opt12"

# After (broken across lines)
menu "$opt1" "$opt2" "$opt3" "$opt4" "$opt5" "$opt6" \
  "$opt7" "$opt8" "$opt9" "$opt10" "$opt11" "$opt12"
```

### Long Strings
```sh
# Before
printf '%s\n' "This is a very long error message that exceeds 100 characters and should be broken up"

# After (option 1: line continuation)
printf '%s\n' "This is a very long error message that exceeds 100 characters \
and should be broken up"

# After (option 2: heredoc for very long text)
cat <<'MSG'
This is a very long error message that exceeds 100 characters
and should be broken up
MSG
```

### Command Pipelines
```sh
# Before
some-command arg1 arg2 | another-command arg3 arg4 | third-command arg5 arg6 | fourth-command arg7

# After  
some-command arg1 arg2 | \
  another-command arg3 arg4 | \
  third-command arg5 arg6 | \
  fourth-command arg7
```

## Checking Compliance

Run the linter on all spells:
```sh
./spells/spellcraft/lint-magic
```

Check a specific file:
```sh
./spells/spellcraft/lint-magic path/to/spell
```

View files with long lines:
```sh
./spells/spellcraft/lint-magic 2>&1 | grep "lines exceed"
```
