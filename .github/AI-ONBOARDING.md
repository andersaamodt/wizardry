# AI Agent Onboarding Guide

Welcome to wizardry! This guide will help you get oriented quickly and avoid common pitfalls.

## Step 1: Essential Reading

1. **`README.md`** (Values, Policies, Design Tenets, Engineering Standards)
   - Understand the project's philosophy and what makes good wizardry code
   - **Key takeaway:** Wizardry values simplicity, cross-platform compatibility, teaching, and self-healing behavior

2. **`.github/copilot-instructions.md`** (critical rules and quality standards)
   - **Key takeaway:** POSIX sh only, tests required, preserve specs and lore

3. **`.github/QUICK-REFERENCE.md`** (templates and patterns)
   - Copy these templates when creating new files

## Step 2: Architecture Overview

### File Types

| Type | Location | Purpose |
|------|----------|---------|
| **Spell** | `spells/category/name` | User-facing command |
| **Imp** | `spells/.imps/family/name` | Micro-helper (internal) |
| **Test** | `.tests/category/test-name.sh` | Test for spell/imp |
| **Bootstrap** | `install`, `spells/install/core/` | Pre-wizardry scripts |

### Key Concepts

- **Spell** = Focused, self-contained script that does one thing well
- **Imp** = Smallest building block; abstracts common patterns (`has`, `say`, `die`)
- **Test** = POSIX sh script that exercises a spell's behavior
- **Function discipline** = Spells have `show_usage()` + at most 1-2 other functions

## Step 3: Common Workflows

### Creating a New Spell

1. **Plan**: One focused thing? < 100 lines? ≤ 3 functions?
2. **Copy template** from `.github/QUICK-REFERENCE.md`
3. **Implement** following `.github/instructions/spells.instructions.md`
4. **Create test** at `.tests/category/test-spell-name.sh` (REQUIRED)
5. **Run test** to verify
6. **Lint**: `lint-magic spells/category/spell-name`
7. **Check POSIX**: `checkbashisms spells/category/spell-name`

### Creating a New Imp

1. **Plan**: One thing? < 50 lines? Zero or one function?
2. **Determine type**: Conditional (no `set -eu`) or Action (`set -eu`)?
3. **Copy template** from `.github/QUICK-REFERENCE.md`
4. **Implement** following `.github/instructions/imps.instructions.md`
5. **Create test** at `.tests/.imps/family/test-imp-name.sh` (REQUIRED)
6. **Run test** and lint

## Step 4: Common Pitfalls

### ❌ Don't Do This

| Mistake | Correct |
|---------|---------|
| `#!/bin/bash` | `#!/bin/sh` |
| Skip tests | Always create test files |
| `[[ ]]` or `==` | `[ ]` and `=` |
| `echo` | `printf '%s\n'` |
| `$var` unquoted | `"$var"` |
| `value=$1` | `value=${1-}` |
| "Please install X" | "spell-name: X not found" + auto-fix |
| 4+ functions | Split into spells or use imps |
| `test_name.sh` | `test-name.sh` (hyphens!) |

### ✅ Do This

- Read README.md first (understand project values)
- Use imps for common patterns: `has git || fail "git required"`
- Keep spells focused (one spell = one action)
- Use descriptive errors: `die "spell-name: sshfs not found"`
- Test terminal I/O only (stub `fathom-cursor`, not wizardry internals)
- Run tests after changes
- Follow existing patterns

## Step 5: Documentation Map

**Need help with...** → **Read:**

- Spell writing → `.github/instructions/spells.instructions.md`
- Imp writing → `.github/instructions/imps.instructions.md`
- Testing → `.github/instructions/tests.instructions.md`
- Logging/output → `.github/instructions/logging.instructions.md`
- Cross-platform → `.github/instructions/cross-platform.instructions.md`
- Proven patterns → `.github/instructions/best-practices.instructions.md`
- Templates → `.github/QUICK-REFERENCE.md`
- Full style guide → `.AGENTS.md`

## Step 6: Model Code

**Learn by example:**

- **Spells**: `spells/arcane/forall` (minimal), `spells/arcane/look` (excellent help text), `spells/cantrips/menu` (complex but structured)
- **Imps**: `spells/.imps/out/say` (action), `spells/.imps/cond/has` (conditional), `spells/.imps/sys/on-exit` (signal handling)
- **Tests**: `.tests/arcane/test-forall.sh` (comprehensive), `.tests/.imps/out/test-say.sh` (simple)

## Step 7: First Contribution Checklist

Before submitting:

- [ ] Read README.md (Values, Design Tenets, Engineering Standards)
- [ ] Consulted relevant instruction file
- [ ] Created tests for any new spells or imps
- [ ] **Ran tests and verified they pass** (don't guess!)
- [ ] Checked style with `lint-magic`
- [ ] Verified POSIX compliance with `checkbashisms`
- [ ] Used templates from QUICK-REFERENCE.md
- [ ] Preserved `--help` text and flavor text (unless explicitly changing)
- [ ] Made minimal, surgical changes
- [ ] Variables quoted, using `${var-}` for optional args
- [ ] Error messages are descriptive, not imperative

---

**Start small:** Read `spells/arcane/look` and `.tests/arcane/test-look.sh` to see how everything fits together.

**When in doubt:** Look at existing code, consult QUICK-REFERENCE.md, and always run your tests!

Good luck, and may your spells cast true! 🧙‍♂️✨
