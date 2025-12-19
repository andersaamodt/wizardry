# Best Practices Documentation - Summary

## What Was Added

A comprehensive best practices guide extracted from proven patterns in the wizardry codebase. This document serves as a reference for AI assistants and human contributors working on the project.

## Location

`.github/instructions/best-practices.instructions.md`

## Key Patterns Documented

1. **Self-Execute Pattern** - How spells can be both sourced and executed directly
2. **PATH Baseline Pattern** - Ensuring bootstrap scripts work on minimal systems
3. **env-clear Sourcing** - Preventing environment variable pollution
4. **Function Discipline** - Guidelines for limiting functions in spells
5. **Stub Imps** - Reusable test mocking via test imps
6. **Test Naming Convention** - Consistent `test-<name>.sh` format
7. **Test Bootstrap Pattern** - Unified test environment setup
8. **Descriptive Error Messages** - Self-healing philosophy in error handling
9. **require-wizardry Pattern** - Consistent dependency checking
10. **Variable Default Patterns** - Safe patterns with `set -u`
11. **Conditional Imps** - When to avoid `set -eu`
12. **Brief Help Text** - Keeping usage notes scannable
13. **Command Invocation** - Using spell names, not paths, in menus

## Why This Matters

These patterns are extracted from actual working code in the wizardry repository. They represent:
- **Proven solutions** to common challenges
- **Consistency** across the codebase
- **Best practices** that emerged organically from real use
- **Guidelines** for maintaining code quality

## Integration

The new document is referenced in:
- `.AGENTS.md` - Main agent instructions
- `.github/copilot-instructions.md` - Copilot custom instructions

## Usage

AI assistants should consult this document when:
- Writing new spells or imps
- Refactoring existing code
- Creating tests
- Understanding wizardry conventions
- Making architectural decisions

## Examples Provided

Each pattern includes:
- Clear explanation of the pattern
- Rationale for why it's used
- Code examples showing correct implementation
- References to actual files in the codebase
- Common mistakes to avoid

## Benefits for AI Assistants

1. **Faster onboarding** - Quick reference to proven patterns
2. **Better consistency** - Follow established conventions
3. **Fewer mistakes** - Learn from documented pitfalls
4. **Deeper understanding** - See why patterns exist, not just how
5. **Real examples** - Link to actual code for verification

## Maintenance

This document should be updated when:
- New patterns emerge from the codebase
- Existing patterns are refined
- Common mistakes are identified
- Best practices evolve

Keep it focused on **proven patterns** from **real code**, not theoretical guidelines.
