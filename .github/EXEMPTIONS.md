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

**Status**: Lines exceeding 100 characters are ALLOWED when splitting would harm readability

**Philosophy**: We strongly prefer **logical command splitting** and clear code structure over arbitrary line continuations. However, we do NOT artificially break lines just to meet a character limit. Long lines are acceptable when:
- They represent a single semantic unit (menu options, config edits, regex patterns)
- Breaking would require awkward continuations or reduce clarity
- They are string literals, error messages, or help text
- Splitting would break command flow or semantics

**Enforcement in lint-magic**: The long lines check is currently implemented as a **warning** that fails the build, but specific exemptions are documented below for cases where long lines are preferred.

#### When to Split Lines

✅ **Good candidates for splitting**:
- Long pipelines → break at pipe boundaries: `cmd1 | cmd2 | cmd3`
- Complex conditionals → separate into multiple if/else blocks
- Long variable assignments → extract intermediate steps
- Command chains with `&&` or `||` → break at logical operators

❌ **Bad candidates for splitting**:
- String literals and error messages
- Menu options with embedded commands
- Single-line regex patterns
- Atomic perl/awk/sed one-liners
- Help text in heredocs

#### Examples of Acceptable Long Lines

##### 1. Menu Options with Embedded Shell Scripts
```sh
# 200+ characters - acceptable because it's a single menu item definition
option="Lightning Invoice%sh -c 'amt=$(printf \"Amount: \"; read -r a; echo \"$a\"); lightning-cli invoice \"$amt\" | tee invoice.txt'"
```

##### 2. Configuration File Editing One-Liners
```sh
# 150+ characters - atomic operation that shouldn't be split
sudo perl -0pi -e "s/(environment\\.systemPackages\\s*=\\s*with\\s+pkgs;\\s*\\[)/$1 tor /" /etc/nixos/configuration.nix
```

##### 3. Error Messages and User-Facing Strings
```sh
# 120 characters - clear message, no need to split
printf '%s\n' "Error: Configuration file not found. Please run 'wizardry init' to create a default configuration." >&2
```

##### 4. Regular Expression Patterns
```sh
# 110 characters - regex pattern with alternatives
if grep -Eq '# >>> wizardry cd cantrip >>>|#wizardry: cd-cantrip|# BEGIN_WIZARDRY_CD' "$rc_file"; then
```

##### 5. Heredoc Content (Documentation)
```sh
cat <<'USAGE'
This spell configures the system for Bitcoin operations including installation of bitcoin core daemon and configuration of data directories.
USAGE
```

Heredoc content is documentation and naturally wraps - not subject to line length limits.

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
