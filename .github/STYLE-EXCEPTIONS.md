# Style Check Exceptions

This document lists permanent or temporary style check exceptions and their justifications.

## Philosophy

Wizardry prefers **logical command splitting** over arbitrary line continuations. When a line exceeds 100 characters:

1. **Best**: Split into multiple logical commands or extract to variables
2. **Good**: Use string concatenation for messages
3. **Acceptable**: Document as exception if splitting harms readability

## Current Status

All style checks in `lint-magic` are now **REQUIRED**:
- Mixed tabs/spaces indentation: ✅ 0 failures
- Lines exceeding 100 characters: ⚠️ 7 permanent exceptions (documented below)
- Echo usage (prefer printf): ✅ Enforced

## Permanent Exceptions

### 1. Menu Options with Embedded Shell Scripts

**Affected Files**:
- `spells/.arcana/lightning/lightning-wallet-menu` (line 37)
- `spells/.arcana/tor/tor-menu` (line 39)

**Reason**: Menu options use format `"Label%command"` where command may be complex shell one-liner. Cannot split without:
- Creating separate helper scripts (adds complexity)
- Breaking inline sh -c pattern
- Making menu definition less clear

**Example**:
```sh
create_invoice_option="Create Invoice%sh -c 'amt=$(printf \"Amount: \"; read -r a; printf \"%s\" \"$a\"); lightning-cli invoice \"$amt\"'"
```

**Decision**: Accept as necessary complexity. Alternative would require separate script files which hurts maintainability.

### 2. Single-Command perl/awk Scripts for Config Editing

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

**Decision**: Accept as necessary for atomic config modifications.

### 3. grep Patterns with Multiple Alternatives

**Affected Files**:
- `spells/.arcana/mud/toggle-cd` (line 68)

**Reason**: grep patterns with multiple alternatives using `|` cannot be meaningfully split.

**Example**:
```sh
if grep -Eq '# >>> wizardry cd cantrip >>>|#wizardry: cd-cantrip' "$rc_file"; then
```

**Decision**: Accept as inherent to pattern matching.

## Temporary Exceptions (To Be Fixed)

### Long Informational Messages

**Affected Files**:
- `spells/.arcana/node/install-node` (line 70)
- `spells/.arcana/simplex-chat/install-simplex-chat` (line 85)  
- `spells/.arcana/lightning/install-lightning` (line 66)

**Status**: Can be fixed with proper string concatenation
**Action**: Split messages using shell string concatenation without spaces

### Long Error/Warning Messages  

**Affected Files**:
- `spells/.arcana/mud/cd` (lines 251, 319)
- `spells/.arcana/mud/handle-command-not-found` (line 350)

**Status**: Can be fixed with string concatenation
**Action**: Use proper `"string1"\n" string2"` concatenation pattern

### Complex Log Checking

**Affected Files**:
- `spells/.arcana/tor/tor-status` (line 56)

**Status**: Under review
**Action**: Consider extracting to variable or function

## Guidelines for New Code

When writing code that might have long lines:

1. **Extract intermediate results**:
   ```sh
   # Good
   filtered=$(echo "$data" | grep pattern)
   result=$(echo "$filtered" | sed 's/old/new/')
   ```

2. **Use variables for complex strings**:
   ```sh
   # Good
   msg="Long error message explaining the problem in detail"
   printf '%s\n' "$msg" >&2
   ```

3. **String concatenation for messages**:
   ```sh
   # Good - no space between parts
   printf '%s\n' "First part"\
" second part"
   ```

4. **Only use backslash continuation as last resort**:
   ```sh
   # Acceptable only if above options don't apply
   very-long-command arg1 arg2 arg3 arg4 | \
     another-command arg5 arg6
   ```

## Review Process

This document should be reviewed:
- When adding new complex commands
- During code review if lines exceed 100 chars
- Quarterly to reassess temporary exceptions

Last updated: 2025-12-10
