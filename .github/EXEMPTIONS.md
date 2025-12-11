# Wizardry Project Exemptions

This document catalogs ALL exemptions and exceptions in the wizardry project. Any deviation from project standards must be documented here with clear justification.

## Table of Contents

1. [Style Check Exemptions](#style-check-exemptions)
2. [Code Structure Exemptions](#code-structure-exemptions)
3. [Testing Exemptions](#testing-exemptions)
4. [CI/Workflow Exemptions](#ciworkflow-exemptions)

---

## Style Check Exemptions

### Long Lines (> 100 characters)

**Status**: Lines exceeding 100 characters **FAIL the build** unless they are primarily string literals

**Philosophy**: We require **logical command splitting** for maintainability and readability. Long commands, pipelines, and complex expressions must be broken into shorter, more readable parts. However, we recognize that long string literals (error messages, help text, user prompts) should NOT be artificially broken, as this harms readability.

**Enforcement in lint-magic**: The long lines check analyzes each line exceeding 100 characters:
- If the line is **>60% quoted text** (string literals), it is ALLOWED
- If the line is **<60% quoted text** (commands, pipelines, code), it FAILS

#### Automatic Exemptions (Built into lint-magic)

Lines with primarily string content are automatically exempt:
- Error messages: `die "my-spell: this is a long descriptive error message that explains what went wrong"`
- User prompts: `printf '%s' "Please enter your configuration (this long prompt helps users understand what to do)"`  
- Help text: Long descriptive strings in scripts
- Test assertions with long strings

No manual documentation needed for these - lint-magic detects them automatically.

#### When to Split Lines

✅ **Required splits** (will fail lint-magic):
- Long pipelines → break at pipe boundaries or use intermediate variables
- Complex conditionals → separate into multiple checks
- Long variable assignments → extract intermediate steps  
- Command chains with `&&` or `||` → break at logical operators
- Menu invocations with many arguments → one argument per line

❌ **Allowed long lines** (won't fail lint-magic):
- String literals in printf/echo/say/warn/die calls
- Long quoted error messages
- User-facing prompts and messages
- Help text and descriptions

#### Examples

##### Good - Long String (Automatically Allowed)
```sh
# 120 characters, >80% quoted - automatically passes lint-magic
die "my-spell: configuration file not found. Please run 'wizardry init' to create default config"
```

##### Bad - Long Command (Will Fail)
```sh
# 150 characters, <20% quoted - FAILS lint-magic, must be split
result=$(echo "$data" | grep pattern | sed 's/old/new/g' | awk '{print $1}' | sort | uniq | head -10)

# Fix: Use intermediate variables or split pipeline
filtered=$(echo "$data" | grep pattern)
cleaned=$(echo "$filtered" | sed 's/old/new/g' | awk '{print $1}')
result=$(echo "$cleaned" | sort | uniq | head -10)
```

##### Manual Exemptions Required

Some lines cannot be easily split and are NOT primarily strings. These require manual exemption and are hardcoded in lint-magic:

**1. Doppelganger Compilation Compatibility**
- **File**: `spells/.imps/cond/is`
- **Line**: 13 (the `empty` case statement)
- **Length**: 156 characters
- **Reason**: The `empty` case has a complex conditional that must remain on one line to preserve doppelganger compilation compatibility. The compile-spell tool expects case labels in the pattern `case_label) ... ;;` to be on the same line or in a specific format. When this line is split across multiple lines, compile-spell's regex-based replacement incorrectly renames `empty` to `_empty` in the case label, breaking the compiled spell.
- **Line**: `empty)    if [ -f "$2" ]; then [ ! -s "$2" ]; elif [ -d "$2" ]; then [ -z "$(ls -A "$2" 2>/dev/null)" ]; else return 1; fi ;;`
- **Exemption Method**: Hardcoded in `lint-magic` check_long_lines() function
- **Alternative Considered**: Improving compile-spell's case statement detection, but this is beyond the scope of style enforcement
- **Impact**: Single file, single line exemption - minimal

**2. Menu options with embedded shell scripts** (NOT YET EXEMPTED - would need manual exemption if enforced)
- File: `spells/.arcana/lightning/lightning-wallet-menu`
- Reason: Menu definition includes inline shell code; splitting breaks menu semantics
- Example: `option="Label%sh -c 'cmd1; cmd2; cmd3'"`
- Status: Currently passes because >60% quoted

**3. Atomic config editing one-liners** (NOT YET EXEMPTED - would need manual exemption if enforced)
- Files: `spells/.arcana/tor/install-tor`, `spells/.arcana/tor/configure-tor-bridge`
- Reason: Perl/awk one-liners for editing system files; must be atomic
- Example: `perl -0pi -e "s/pattern/replacement/" /etc/config`
- Status: Currently passes because >60% quoted

**4. Complex regex patterns with many alternatives** (NOT YET EXEMPTED - would need manual exemption if enforced)
- File: `spells/.arcana/mud/toggle-cd`
- Reason: Grep pattern with multiple alternatives inherently long
- Example: `grep -Eq 'pattern1|pattern2|pattern3|pattern4|pattern5' "$file"`
- Status: Needs review if it fails lint checks

### Historical: Mixed Tabs and Spaces (RESOLVED)

**Status**: ✅ Fixed in commits 4463607 and earlier

**Previous Issue**: 8 files had mixed tabs and spaces for indentation

**Resolution**: Converted all tabs to 2 spaces consistently

**Files Fixed**:
- spells/.arcana/bitcoin/bitcoin-menu
- spells/.arcana/bitcoin/configure-bitcoin
- spells/.arcana/mud/handle-command-not-found
- spells/cantrips/install-service-template
- spells/cantrips/memorize
- spells/cantrips/spellbook-store
- spells/spellcraft/forget
- spells/translocation/jump-to-marker

### Historical: Lint-Magic Tab Detection Bug (RESOLVED)

**Status**: ✅ Fixed in commit 4463607

**Previous Issue**: The `check_inconsistent_indentation` function used `'\t'` in single quotes, which doesn't expand to a tab character in shell.

**Resolution**: Changed to use `tab=$(printf '\t')` and double quotes in the grep pattern.

---

## Code Structure Exemptions

### Conditional Imps: No `set -eu`

**Affected Files**: All imps in these families:
- `spells/.imps/cond/` — `has`, `there`, `is`, `yes`, `no`, `empty`, `nonempty`, `lacks`, `gone`, `given`, `full`, etc.
- `spells/.imps/lex/` — parsing helpers like `disambiguate`, `parse`, etc.
- `spells/.imps/menu/` — menu helpers

**Reason**: Conditional imps are designed to return exit codes for flow control (true/false testing). They are used in `if` statements and `&&`/`||` chains where non-zero exit codes indicate false rather than error.

**Example**:
```sh
# Conditional imp - no set -eu
#!/bin/sh
# has COMMAND - test if command is available

_has() {
  command -v "$1" >/dev/null 2>&1
}

case "$0" in
  */has) _has "$@" ;; esac
```

**Usage Pattern**:
```sh
if has git; then
  # git is available
else
  # git is not available (exit code 1 is expected, not an error)
fi

has gcc || die "gcc required"
```

**Justification**: Using `set -eu` in these imps would cause them to exit with error on "false" conditions, breaking their intended use in boolean contexts. The `-e` flag would interpret a false condition (exit code 1) as an error, and `-u` would complain about intentionally empty variables used for testing.

**Scope**: This exemption applies ONLY to conditional imps. All action imps (those that perform operations rather than return test results) MUST use `set -eu`.

### Imps: No `--help` or `show_usage()` Required

**Affected Files**: All files in `spells/.imps/`

**Reason**: Imps are micro-helpers with minimal interfaces. The opening comment serves as their specification.

**Justification**: Imps are building blocks, not user-facing commands. Adding `--help` handling would make them larger than the functionality they provide. Users should read the source code or opening comment to understand what an imp does.

**Example**:
```sh
#!/bin/sh
# say MESSAGE - print message to stdout with newline
# Example: say "Hello world"

set -eu

_say() {
  printf '%s\n' "$*"
}

case "$0" in
  */say) _say "$@" ;; esac
```

---

## Testing Exemptions

### Bootstrap Scripts: No Wizardry Imps

**Affected Files**:
- `install` (root directory)
- `spells/install/core/*`

**Reason**: Bootstrap scripts run before wizardry is fully installed and cannot depend on wizardry infrastructure.

**Requirements**:
- Must define their own helper functions inline
- Cannot use wizardry imps
- Should follow the same semantic patterns but with self-contained implementations

**Justification**: The chicken-and-egg problem: these scripts install wizardry, so they can't assume wizardry is already available.

### Test-Only Imps: `test-` Prefix Required

**Affected Files**: All imps in `spells/.imps/test/`

**Reason**: Imps used only in tests must be clearly distinguished from production imps.

**Requirement**: All test-only imps must have names prefixed with `test-`

**Examples**:
- `test-bootstrap` ✓ (correct)
- `run-spell` ✗ (should be `test-run-spell` if test-only)

**Justification**: Prevents test infrastructure from being accidentally used in production code or leaked into compiled spells.

---

## CI/Workflow Exemptions

### No CI Exemptions Currently

**Status**: ✅ All CI checks are required

**Historical Context**: The original issue requested removal of all CI exemptions like `continue-on-error` or `allow-failure`.

**Current State**: 
- No workflows use `continue-on-error: true`
- No workflows use `allow-failure`
- All test failures cause the CI run to fail
- All linting failures cause the CI run to fail

**Verification**:
```sh
grep -r "continue-on-error\|allow-failure" .github/workflows/
# Returns: (empty - no exemptions)
```

---

## Guidelines for Adding New Exemptions

Before adding a new exemption to this document:

1. **Exhaust all alternatives**: Try logical splitting, extraction to variables, helper functions
2. **Document thoroughly**: Include affected files, reason, justification, and examples
3. **Set review date**: If temporary, specify when to revisit
4. **Get approval**: Discuss in PR review before merging
5. **Update this document**: Add to appropriate section with full context

### Exemption Template

```markdown
##### [Exemption Name]

**Affected Files**: 
- `path/to/file` (line numbers if applicable)

**Reason**: Brief technical reason

**Example**:
```sh
# Code example demonstrating the exemption
```

**Justification**: Longer explanation of why alternatives don't work

**Review Date**: [If temporary] YYYY-MM-DD or "Permanent"
```

---

## Review Process

This document should be reviewed:
- **Quarterly**: To reassess temporary exemptions
- **Before releases**: Ensure all exemptions are still necessary
- **When adding exemptions**: As part of PR review process
- **When style rules change**: To update affected exemptions

**Last Updated**: 2025-12-10
**Last Reviewed**: 2025-12-10
**Next Review**: 2026-03-10 (quarterly)
