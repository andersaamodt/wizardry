# AI Agent Onboarding Guide

Welcome to wizardry! This guide will help you get oriented quickly and avoid common pitfalls.

## Step 1: Understand the Project (5 minutes)

Read these in order:

1. **`README.md`** (sections: Values, Policies, Design Tenets, Engineering Standards)
   - **Why?** Understand the project's philosophy and what makes good wizardry code
   - **Key takeaway:** Wizardry values simplicity, cross-platform compatibility, teaching, and self-healing behavior

2. **`.github/copilot-instructions.md`** (this is short, ~100 lines)
   - **Why?** Get the critical rules and quality standards
   - **Key takeaway:** POSIX sh only, tests required, preserve specs and lore

3. **`.github/QUICK-REFERENCE.md`** (templates and patterns)
   - **Why?** See working examples of spells, imps, and tests
   - **Key takeaway:** Copy these templates when creating new files

## Step 2: Learn the Architecture (5 minutes)

### File Types

| Type | Location | Purpose | Example |
|------|----------|---------|---------|
| **Spell** | `spells/category/name` | User-facing command | `spells/arcane/look` |
| **Imp** | `spells/.imps/family/name` | Micro-helper (internal) | `spells/.imps/out/say` |
| **Test** | `.tests/category/test-name.sh` | Test for spell/imp | `.tests/arcane/test-look.sh` |
| **Bootstrap** | `install`, `spells/install/core/` | Pre-wizardry scripts | `install` |

### Key Concepts

- **Spell** = A focused, self-contained script that does one thing well
- **Imp** = Smallest building block; abstracts common patterns (e.g., `has`, `say`, `die`)
- **Scroll** = A linear spell with minimal functions (ideal form)
- **Test** = POSIX sh script that exercises a spell's behavior
- **Function discipline** = Spells should have `show_usage()` + at most 1-2 other functions

### Directory Structure

```
spells/
  arcane/           # "Magical" everyday utilities
  cantrips/         # Small utility spells
  divination/       # Detection/discovery spells
  system/           # System-level operations
  .imps/            # Micro-helpers organized by family:
    cond/           # Conditional tests (has, there, is)
    out/            # Output and logging (say, warn, die)
    fs/             # Filesystem operations
    str/            # String operations
    sys/            # System utilities
    test/           # Test-only imps (stubs, helpers)

.tests/             # Mirrors spells/ structure
  arcane/
    test-look.sh
  .imps/
    out/
      test-say.sh
```

## Step 3: Know the Tools (2 minutes)

| Tool | Purpose | Usage |
|------|---------|-------|
| `lint-magic` | Check spell style compliance | `lint-magic spells/category/name` |
| `checkbashisms` | Verify POSIX compliance | `checkbashisms spells/category/name` |
| `.tests/category/test-name.sh` | Run specific test | `.tests/arcane/test-look.sh` |
| `test-magic` | Run all tests (requires install) | `test-magic` |

## Step 4: Common Workflows

### Creating a New Spell

1. **Plan**: Is this one focused thing? Can it be < 100 lines? Will you need ≤ 3 functions?
2. **Copy template** from `.github/QUICK-REFERENCE.md`
3. **Implement** the spell following patterns in `.github/instructions/spells.instructions.md`
4. **Create test** at `.tests/category/test-spell-name.sh` (NON-NEGOTIABLE)
5. **Run test** to verify it works
6. **Lint**: `lint-magic spells/category/spell-name`
7. **Check POSIX**: `checkbashisms spells/category/spell-name`

### Creating a New Imp

1. **Plan**: Does it do exactly ONE thing? Is it < 50 lines? Zero or one function?
2. **Determine type**: Conditional (no `set -eu`) or Action (`set -eu`)?
3. **Copy template** from `.github/QUICK-REFERENCE.md`
4. **Implement** following `.github/instructions/imps.instructions.md`
5. **Create test** at `.tests/.imps/family/test-imp-name.sh` (REQUIRED)
6. **Run test** to verify
7. **Lint and check POSIX**

### Modifying Existing Code

1. **Read the spec**: Look at the spell's opening comment and `--help` output
2. **Don't change the spec** unless explicitly asked
3. **Don't change flavor text** (MUD-themed descriptions) unless asked
4. **Make minimal changes** to achieve the goal
5. **Run existing tests** before and after your changes
6. **Update tests** if behavior changes

## Step 5: Common Pitfalls (Important!)

### ❌ Don't Do This

| Mistake | Why It's Wrong | Correct Approach |
|---------|----------------|------------------|
| Use `#!/bin/bash` | Not POSIX; wizardry is sh | `#!/bin/sh` |
| Skip creating tests | CI will fail; tests are required | Always create test files |
| Use `[[ ]]` or `==` | Bash-isms | Use `[ ]` and `=` |
| Use `echo` | Not portable | Use `printf '%s\n'` |
| Unquoted variables `$var` | Breaks with spaces | Always quote: `"$var"` |
| No default: `value=$1` | Fails with `set -u` | Use `value=${1-}` |
| Imperative errors: "Please install X" | Not self-healing | "spell-name: X not found" + auto-fix |
| Add 4+ functions to a spell | Proto-library; needs refactoring | Split into multiple spells or use imps |
| Guess test results | Misleading | Run tests and report actual output |
| Test naming: `test_name.sh` | Wrong pattern | Use `test-name.sh` (hyphens!) |

### ✅ Do This

| Best Practice | Why | Example |
|---------------|-----|---------|
| Read README.md first | Understand project values | (before any changes) |
| Use imps for common patterns | DRY, consistent | `has git \|\| fail "git required"` |
| Keep spells focused | Maintainability | One spell = one action |
| Use descriptive errors | Self-documenting | `die "spell-name: sshfs not found"` |
| Test terminal I/O only | Test real wizardry | Stub `fathom-cursor`, not menu logic |
| Run tests after changes | Verify nothing broke | `.tests/category/test-name.sh` |
| Follow existing patterns | Consistency | Study model spells |

## Step 6: Where to Look for Help

**Stuck on...** → **Read this:**

- How to write a spell → `.github/instructions/spells.instructions.md`
- How to write an imp → `.github/instructions/imps.instructions.md`
- How to write a test → `.github/instructions/tests.instructions.md`
- Output and logging → `.github/instructions/logging.instructions.md`
- Cross-platform issues → `.github/instructions/cross-platform.instructions.md`
- Proven patterns → `.github/instructions/best-practices.instructions.md`
- Quick template → `.github/QUICK-REFERENCE.md`
- Full style guide → `.AGENTS.md`
- Project philosophy → `README.md`

## Step 7: Model Code to Study

**Learn by example** — these are exemplary implementations:

### Spells
- **`spells/arcane/forall`** — Minimal, focused, well-documented
- **`spells/arcane/look`** — Excellent help text, error handling, self-installation
- **`spells/cantrips/menu`** — Complex but well-structured with clear discipline

### Imps
- **`spells/.imps/out/say`** — Simple action imp with self-execute pattern
- **`spells/.imps/cond/has`** — Conditional imp (note: no `set -eu`)
- **`spells/.imps/sys/on-exit`** — Signal handling pattern

### Tests
- **`.tests/arcane/test-forall.sh`** — Comprehensive test coverage
- **`.tests/.imps/out/test-say.sh`** — Simple imp test
- **`.tests/cantrips/test-menu.sh`** — Complex spell test with stubs

## Step 8: Your First Contribution Checklist

Before submitting any changes:

- [ ] Read README.md (at least Values, Design Tenets, Engineering Standards)
- [ ] Reviewed `.github/copilot-instructions.md`
- [ ] Consulted relevant instruction file (spells/imps/tests/logging/cross-platform)
- [ ] Created tests for any new spells or imps
- [ ] **Ran tests and verified they pass** (don't guess!)
- [ ] Checked style with `lint-magic`
- [ ] Verified POSIX compliance with `checkbashisms`
- [ ] Used templates from QUICK-REFERENCE.md
- [ ] Preserved existing `--help` text and flavor text (unless explicitly changing)
- [ ] Made minimal, surgical changes
- [ ] All variables quoted, using `${var-}` for optional args
- [ ] Error messages are descriptive, not imperative

## Quick Reference Card

Keep this handy:

```sh
# Spell template (minimal)
#!/bin/sh
# Brief description

show_usage() { cat <<'USAGE'
Usage: spell-name [args]
Description.
USAGE
}

case "${1-}" in
--help|--usage|-h) show_usage; exit 0 ;; esac

require-wizardry || exit 1
set -eu
. env-clear

# Main logic
```

**Common patterns:**
```sh
# Check command exists
has git || fail "git required"

# Default value
name=${1-}                  # Empty if unset
path=${1:-/default/path}    # Use default if unset/empty

# Output
say "Normal message"        # Always shown
info "Processing..."        # WIZARDRY_LOG_LEVEL >= 1
debug "Debug info"          # WIZARDRY_LOG_LEVEL >= 2

# Errors
warn "spell-name: warning message"
die "spell-name: fatal error"
die 2 "spell-name: usage error"
```

**Test pattern:**
```sh
#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_feature() {
  _run_spell "spells/category/name" arg
  _assert_success && _assert_output_contains "expected"
}

_run_test_case "description" test_feature
_finish_tests
```

---

## You're Ready!

You now know:
- ✅ Where to find documentation
- ✅ What spells, imps, and tests are
- ✅ How to create new files
- ✅ Common mistakes to avoid
- ✅ How to verify your work

**Start small:** Try reading a simple spell like `spells/arcane/look` and its test `.tests/arcane/test-look.sh` to see how everything fits together.

**When in doubt:** Look at existing code for patterns, consult the QUICK-REFERENCE, and always run your tests!

Good luck, and may your spells cast true! 🧙‍♂️✨
