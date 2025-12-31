# AI Documentation Structure

## Overview

Wizardry's AI-facing documentation is organized to be **concise** and **hierarchical**, helping AI agents quickly find essential information without being overwhelmed by verbosity.

## Primary Documentation (508 lines total)

These files are the **main entry points** that AI agents should read:

1. **`.AGENTS.md`** (205 lines)
   - Quick reference for AI agents
   - Critical rules that AI often misses
   - Templates and common patterns
   - Workflow checklists
   - **When to read**: Start here for quick guidance

2. **`.github/copilot-instructions.md`** (303 lines)
   - Main Copilot guide
   - Comprehensive but condensed
   - References detailed instruction files
   - **When to read**: Primary source of truth for GitHub Copilot

## Detailed Reference Documentation

These files provide **topic-specific details** and are embedded by GitHub Copilot automatically based on file context (via `applyTo:` directives):

### Instruction Files (`.github/instructions/`)

| File | Lines | Purpose | ApplyTo |
|------|-------|---------|---------|
| `spells.instructions.md` | 212 | Spell writing guide | `spells/**` |
| `imps.instructions.md` | 255 | Imp (micro-helper) guide | `spells/.imps/**` |
| `tests.instructions.md` | 235 | Testing framework | `.tests/**` |
| `logging.instructions.md` | 294 | Output and error handling | `spells/**` |
| `cross-platform.instructions.md` | 105 | Platform compatibility | `spells/**,.tests/**` |
| `castable-uncastable-pattern.instructions.md` | 248 | Self-execute patterns | `spells/**` |
| `glossary-and-function-architecture.instructions.md` | 292 | Function naming architecture | `spells/**,.tests/**,spells/.imps/**` |
| `best-practices.instructions.md` | 467 | Proven patterns from codebase | `spells/**,.tests/**` |
| `imp-set-eu.instructions.md` | 84 | Imp strict mode rules | `spells/.imps/**` |
| `dual-pattern-testing.instructions.md` | 190 | Dual execution pattern tests | `.tests/**` |
| `testing-environment.md` | 380 | CI vs local differences | `.tests/**` |

**Total: 2,762 lines** (embedded only when working on relevant files)

### Other Reference Files (`.github/`)

| File | Lines | Purpose |
|------|-------|---------|
| `EXEMPTIONS.md` | 723 | Documents all exceptions to project rules |
| `SPELL_LEVELS.md` | 744 | Spiral debug organization (active project) |
| `BOOTSTRAPPING.md` | 180 | Bootstrap architecture and function naming |
| `CODE_POLICY_SET_EU.md` | 225 | Interactive shell set -e edge cases |
| `CODE_POLICY_FUNCTION_CALLS.md` | 101 | Function variable call patterns |
| `WORD_OF_BINDING.md` | 266 | Spell loading architecture |
| `SHELL_IDIOSYNCRASIES.md` | 350 | Shell-specific quirks |
| `SPIRAL_DEBUG.md` | 91 | Active debugging project |
| `CODEX.md` | 108 | OpenAI Codex instructions |

## Archived Documentation (`.github/archive/`)

Historical debugging and investigation files that are no longer actively used for AI guidance:

- `DEBUG_MENU_TESTING.md`
- `MAC_DEBUGGING_GUIDE.md`
- `INVESTIGATION_SUMMARY.md`
- `MAC_INSTALL_FIX_SUMMARY.md`
- `MAC_TERMINAL_HANG_FIX.md`
- `TEST_ZSH_FIX.md`
- `HANDLE_COMMAND_NOT_FOUND_TOGGLE.md`

See `.github/archive/README.md` for details.

## How GitHub Copilot Uses This Structure

1. **Always reads**: `.github/copilot-instructions.md` (main guide)
2. **Contextually embeds**: Instruction files based on `applyTo:` directive
   - Working on `spells/arcane/copy`? → Embeds `spells.instructions.md`, `logging.instructions.md`, etc.
   - Working on `.tests/arcane/test-copy.sh`? → Embeds `tests.instructions.md`, `testing-environment.md`, etc.
3. **References**: Other detailed files as needed

## Benefits of This Structure

1. **Fast loading**: Primary docs are only 508 lines (down from 3,871)
2. **No duplication**: Each concept documented once, referenced elsewhere
3. **Context-aware**: Detailed guides embedded only when relevant
4. **Maintainable**: Changes to patterns updated in one place
5. **Scalable**: Can add new instruction files without bloating primary docs

## For AI Agents

**Quick Start:**
1. Read `.github/copilot-instructions.md` first
2. Use `.AGENTS.md` for quick reference
3. Trust that detailed instruction files will be embedded when needed
4. Reference files like `EXEMPTIONS.md` when dealing with exceptions

**Common Queries:**
- "How do I write a spell?" → Check copilot-instructions.md templates
- "What are the test requirements?" → Both primary docs emphasize this
- "Why is my set -eu causing issues?" → See imp-set-eu.instructions.md or castable-uncastable-pattern.instructions.md
- "What patterns should I follow?" → See best-practices.instructions.md

## Maintenance

When adding new documentation:
- **Essential rules**: Add to copilot-instructions.md (keep under 1000 lines total)
- **Quick tips**: Add to .AGENTS.md
- **Detailed guides**: Create new `.github/instructions/*.md` file with `applyTo:` directive
- **Edge cases**: Add to relevant CODE_POLICY or reference file
- **Debugging notes**: Use `.github/archive/` for historical investigations

## History

**Before (Dec 2025):**
- Primary AI documentation: ~3,871 lines across 14+ files
- Many duplicate concepts
- Debug files cluttering .github/
- Hard for AI to keep all rules in mind

**After (Dec 2025):**
- Primary AI documentation: 508 lines (86.9% reduction)
- Zero duplication
- Debug files archived
- Clear hierarchy: primary → detailed → reference
