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

**Status**: 7 permanent exceptions (out of 329 files = 98% compliance)

**Philosophy**: We prefer **logical command splitting** over arbitrary line continuations. Lines should only remain long when splitting would harm readability or break command semantics.

#### Permanent Exceptions

##### 1. Menu Options with Embedded Shell Scripts

**Affected Files**:
- `spells/.arcana/lightning/lightning-wallet-menu` (line 37)
- `spells/.arcana/tor/tor-menu` (line 39)

**Reason**: Menu options use format `"Label%command"` where command may be a complex shell one-liner with pipes, subshells, and variable assignments. Cannot split without:
- Creating separate helper scripts (adds complexity)
- Breaking the inline `sh -c` pattern
- Making menu definition less clear

**Example**:
```sh
create_invoice_option="Create Invoice%sh -c 'amt=$(printf \"Amount: \"; read -r a; printf \"%s\" \"$a\"); lightning-cli invoice \"$amt\"'"
```

This is a single semantic unit: a menu option with its associated command.

**Justification**: The menu system requires this format for dynamic command execution. Splitting would require extracting to separate script files, significantly increasing maintenance burden for what is essentially configuration data.

##### 2. Single-Command perl/awk Scripts for Config Editing

**Affected Files**:
- `spells/.arcana/tor/install-tor` (lines 136-137)
- `spells/.arcana/tor/configure-tor-bridge` (line 62)

**Reason**: Complex perl/awk one-liners that atomically modify configuration files. Splitting would:
- Require multi-line scripts (changes semantics)
- Need extraction to separate files (maintenance burden)
- Break single-command atomic operation pattern

**Example**:
```sh
sudo perl -0pi -e "s/(environment\\.systemPackages\\s*=\\s*with\\s+pkgs;\\s*\\[)/$1 tor /" /etc/nixos/configuration.nix
```

**Justification**: These are atomic operations that must succeed or fail as a single unit. Converting to multi-line scripts would obscure their atomicity and make error handling more complex.

##### 3. grep Patterns with Multiple Alternatives

**Affected Files**:
- `spells/.arcana/mud/toggle-cd` (line 68)

**Reason**: grep patterns with multiple alternatives using `|` operator cannot be meaningfully split without breaking the regex.

**Example**:
```sh
if grep -Eq '# >>> wizardry cd cantrip >>>|#wizardry: cd-cantrip' "$rc_file"; then
```

**Justification**: Regex patterns are inherently linear and splitting them would require using extended regex constructs or multiple grep calls, both of which reduce clarity.

##### 4. Heredoc Description Text

**Affected Files**:
- `spells/.arcana/mud/cd` (line 13)
- `spells/.arcana/mud/handle-command-not-found` (line 11)
- `spells/.arcana/mud/toggle-cd` (line 9)
- `spells/.arcana/tor/configure-tor-bridge` (lines 9, 34)

**Reason**: These are description lines within heredoc `USAGE` blocks, not actual code.

**Justification**: Heredoc content is documentation and can wrap naturally. The 100-character limit applies to code lines, not documentation text.

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
