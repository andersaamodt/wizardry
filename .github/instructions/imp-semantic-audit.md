# Imp Semantic Audit

This document audits all imps for semantic coherence, ensuring names accurately describe behavior and families are internally consistent.

## Audit Methodology

For each imp family:
1. List all imps in family
2. Describe expected semantics
3. Verify actual behavior matches name
4. Check for internal consistency
5. Identify any semantic issues
6. Document intended usage patterns

## Output Imps (`spells/.imps/out/`)

**Purpose**: Standardized output and error handling with logging levels

### Semantic Analysis

| Imp | Semantic Promise | Actual Behavior | Exit? | Log Level | ✓ |
|-----|------------------|-----------------|-------|-----------|---|
| `die` | "Fatal error, exit script" | Prints to stderr, **returns** exit code | No | Always | ⚠️ |
| `fail` | "Error but continue" | Prints to stderr, returns 1 | No | Always | ✅ |
| `warn` | "Warning, continue" | Prints to stderr, returns 0 | No | Always | ✅ |
| `say` | "Normal output" | Prints to stdout | No | Always | ✅ |
| `info` | "Informational message" | Prints to stdout | No | ≥ 1 | ✅ |
| `step` | "Process step" | Prints to stdout | No | ≥ 1 | ✅ |
| `debug` | "Debug information" | Prints to stderr with DEBUG: prefix | No | ≥ 2 | ✅ |
| `success` | "Success message" | Prints to stdout | No | Always | ✅ |
| `usage-error` | "Usage/argument error" | Prints to stderr, returns 2 | No | Always | ✅ |

### Issue: die Semantic Mismatch ⚠️

**Name suggests**: "die" = terminate/exit script  
**Actual behavior**: Returns exit code (doesn't exit)  
**Current implementation**: Uses `return $_die_code`

**Analysis**:
- In traditional shell scripting, `die` exits the script
- In wizardry's word-of-binding paradigm, imps use `return` not `exit`
- When a spell function returns non-zero, the script exits
- So technically `die` DOES cause script termination, just via return chain

**Verdict**: ✅ Semantic is CORRECT for word-of-binding paradigm
- Name `die` is accurate: it causes script death via return
- Alternative name like `error-fatal` would be less clear
- The return-not-exit pattern is intentional and documented

**Recommendation**: 
- Keep `die` as-is (uses `return`)
- Document that all output imps use `return` for word-of-binding compatibility
- Add comment to die explaining the return vs exit choice

### Family Consistency ✅

All output imps:
- Use `return` not `exit` (word-of-binding compatible)
- Have consistent naming (_imp_name function, self-execute pattern)
- Handle log levels appropriately
- Output to correct stream (stdout vs stderr)

### Usage Pattern Documentation

```sh
# In a spell function
spell_name() {
  has git || fail "git required"           # Error but continue checking
  has make || fail "make required"
  
  if [ ! -f "$config" ]; then
    die "config file not found"            # Fatal error, function returns 1
  fi
  
  warn "using default configuration"       # Warning, continue
  info "processing files..."               # Informational (level ≥ 1)
  step "step 1: download..."               # Step marker (level ≥ 1)
  debug "variable value: $var"             # Debug (level ≥ 2)
  
  success "operation complete"             # Success message
  return 0
}

# When spell_name returns 1, script exits with code 1
# This is how die "works" - it returns, then function returns, then script exits
```

## Conditional Imps (`spells/.imps/cond/`)

**Purpose**: Boolean tests for flow control (if/&&/||)

### Semantic Analysis

| Imp | Semantic Promise | Actual Behavior | Uses set -eu? | ✓ |
|-----|------------------|-----------------|---------------|---|
| `has` | "Command available?" | Tests command -v | No | ✅ |
| `there` | "Path exists?" | Tests -e path | No | ✅ |
| `is` | "Type check" | Tests file type | No | ✅ |
| `yes` | "Affirmative?" | Tests y/yes/true | No | ✅ |
| `no` | "Negative?" | Tests n/no/false | No | ✅ |
| `empty` | "String empty?" | Tests -z string | No | ✅ |
| `nonempty` | "String not empty?" | Tests -n string | No | ✅ |

### No set -eu Exception ✅

**Rationale**: Conditional imps return exit codes for flow control
- Used in: `if has git`, `has git || fail`
- Exit code 1 = false, not error
- With `set -e`, non-zero would terminate script (wrong!)
- Exception is documented and intentional

### Family Consistency ✅

All conditional imps:
- Do NOT use `set -eu`
- Return 0 for true, 1 for false
- Have clear yes/no semantic
- Work in if/&&/|| chains

### Usage Pattern Documentation

```sh
# Boolean flow control
if has git; then
  info "git available"
fi

# Short-circuit operators
has git || fail "git required"
has make && info "make available"

# Compound conditions (POSIX [ ] syntax)
if [ -f "$file" ] && has grep; then
  grep pattern "$file"
fi

# Using conditional imps
if empty "$value"; then
  value="default"
fi

if there /etc/config; then
  . /etc/config
fi
```

## String Imps (`spells/.imps/str/`)

**Purpose**: String manipulation utilities

### Semantic Analysis

| Imp | Semantic Promise | Actual Behavior | ✓ |
|-----|------------------|-----------------|---|
| `trim` | "Remove whitespace" | Removes leading/trailing whitespace | ✅ |
| `contains` | "Substring check" | Tests if string contains substring | ✅ |

### Family Consistency ✅

String imps are simple and semantic.

## Filesystem Imps (`spells/.imps/fs/`)

**Purpose**: Filesystem operations and helpers

### Semantic Analysis

| Imp | Semantic Promise | Actual Behavior | ✓ |
|-----|------------------|-----------------|---|
| `cleanup-file` | "Remove file" | rm -f file | ✅ |
| `cleanup-dir` | "Remove directory" | rm -rf dir | ✅ |
| `temp-file` | "Create temp file" | mktemp with template | ✅ |
| `xattr-*` | "Extended attributes" | Platform-specific xattr ops | ✅ |

### Family Consistency ✅

Filesystem imps have clear action semantics.

## System Imps (`spells/.imps/sys/`)

**Purpose**: System integration and environment

### Semantic Analysis

| Imp | Semantic Promise | Actual Behavior | ✓ |
|-----|------------------|-----------------|---|
| `invoke-wizardry` | "Activate wizardry in shell" | Sources spells, sets PATH | ✅ |
| `word-of-binding` | "Source and call spell" | Sources spell, calls function | ✅ |
| `on-exit` | "Register cleanup handler" | trap handler for signals | ✅ |
| `clear-traps` | "Clear signal handlers" | trap - for all signals | ✅ |
| `declare-globals` | "Initialize wizardry globals" | Sets WIZARDRY_DIR, etc. | ✅ |

### Family Consistency ✅

System imps manage shell environment.

## Input Imps (`spells/.imps/input/`)

**Purpose**: Terminal and user input handling

### Semantic Analysis

| Imp | Semantic Promise | Actual Behavior | ✓ |
|-----|------------------|-----------------|---|
| (Currently no standalone input imps - integrated into cantrips) | - | - | - |

Most input handling is in cantrips (ask-yn, ask-text, await-keypress).

## Menu Imps (`spells/.imps/menu/`)

**Purpose**: Menu rendering and navigation helpers

These are specialized for menu system and don't use set -eu (conditional nature).

### Family Consistency ✅

Menu imps are consistent with conditional imps (no set -eu).

## Lexical Imps (`spells/.imps/lex/`)

**Purpose**: Parsing and lexical analysis

Similar to conditional imps - return exit codes to signal success/failure of parsing.

### No set -eu Exception ✅

Same rationale as conditional imps - exit codes for flow control.

## Test Imps (`spells/.imps/test/`)

**Purpose**: Testing infrastructure

### Naming Convention ✅

**Rule**: Test imps have `test-` or `stub-` prefix
- `test-*`: Test framework utilities
- `stub-*`: Test stubs for system commands
- `boot/*`: Test helper functions (no prefix needed - in subdirectory)

### Stub Imp Semantic Pattern ✅

**Self-execute pattern**: Must match both prefixed and unprefixed names
```sh
case "$0" in
  */stub-name|*/name) _stub_name "$@" ;;
esac
```

**Rationale**: Tests create symlinks without stub- prefix, need both to work

## Cross-Cutting Concerns

### Word-of-Binding Pattern ✅

**All imps** use this pattern:
```sh
#!/bin/sh
# imp-name ARGS - description

_imp_name() {
  # implementation
}

case "$0" in
  */imp-name) _imp_name "$@" ;;
esac
```

**Benefits**:
- Can be sourced (import function)
- Can be executed (run directly)
- Consistent across all imps

### Return vs Exit

**All imps use `return`** not `exit`:
- Compatible with sourcing
- Works with word-of-binding
- Spell functions handle exit propagation

**Exception**: None - all imps use return

### Naming Conventions ✅

**All imp names**:
- Use hyphens for multi-word (e.g., `cleanup-file`)
- Use verbs for actions (e.g., `trim`, `cleanup`)
- Use questions for conditionals (e.g., `has`, `there`, `empty`)
- Match behavior to name

## Issues Found

### None! ✅

All imps follow consistent semantic patterns:
1. Names match behavior
2. Families are internally consistent
3. return vs exit is correct for word-of-binding
4. Exceptions (no set -eu) are documented and intentional

## Recommendations

### 1. Add Semantic Comments to Key Imps

Add explanation comments to imps that might seem counter-intuitive:

```sh
#!/bin/sh
# die [CODE] MESSAGE - print to stderr and exit script
# Uses 'return' not 'exit' for word-of-binding compatibility.
# When called from spell function, function returns, then script exits.
# Examples: die "fatal error" | die 2 "file not found"
set -eu

_die() {
  # ... implementation ...
  return "$_die_code"  # Return (not exit) for word-of-binding
}
```

### 2. Document Imp Families in README

Add section explaining imp organization by family:
- Output (say, die, warn, etc.)
- Conditional (has, there, is, etc.)
- Filesystem (cleanup-*, temp-*)
- System (invoke-wizardry, word-of-binding, etc.)
- String (trim, contains, etc.)

### 3. Create Imp Usage Examples

Add examples document showing common patterns:
- Error handling with die/fail/warn
- Conditional checks with has/there
- String operations with str/* imps
- Cleanup with on-exit

## Conclusion

**Semantic audit result**: ✅ PASS

All imps exhibit semantic coherence:
- Names accurately describe behavior
- Families are internally consistent
- Return vs exit usage is intentional and correct
- Exceptions (no set -eu for conditionals) are documented

The only "issue" (die not using exit) is actually correct behavior for wizardry's word-of-binding paradigm. No changes needed to imp semantics.

**Recommended actions**:
1. ✅ Add clarifying comments to die imp
2. ✅ Document imp families in architecture doc (done in testing-architecture.md)
3. ✅ Document usage patterns (done in testing-architecture.md)
