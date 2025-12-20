# Documentation Index for AI Agents

This file helps you quickly find the right documentation for your task.

## 🚀 Start Here (New to Wizardry?)

1. **`.github/AI-ONBOARDING.md`** — Complete step-by-step guide for new AI agents (START HERE!)
2. **`README.md`** — Project values, policies, design tenets, and engineering standards
3. **`.github/copilot-instructions.md`** — Quick overview and critical rules

## 📖 Core Documentation

### Quick Reference
- **`.github/QUICK-REFERENCE.md`** — Templates, patterns, and quick lookups

### Comprehensive Guide  
- **`.AGENTS.md`** — Full style guide, architectural details, and coding standards (773 lines)

## 🎯 Topic-Specific Instructions

All files in `.github/instructions/` use the `applyTo:` directive to indicate which files they cover.

### By File Type

| Working on... | Read this |
|---------------|-----------|
| Spells (`spells/**`) | `.github/instructions/spells.instructions.md` |
| Imps (`spells/.imps/**`) | `.github/instructions/imps.instructions.md` |
| Tests (`.tests/**`) | `.github/instructions/tests.instructions.md` |

### By Topic

| Topic | File | applyTo |
|-------|------|---------|
| **Spell writing** | `spells.instructions.md` | `spells/**` |
| **Imp writing** | `imps.instructions.md` | `spells/.imps/**` |
| **Testing** | `tests.instructions.md` | `.tests/**` |
| **Logging & output** | `logging.instructions.md` | `spells/**` |
| **Cross-platform** | `cross-platform.instructions.md` | `spells/**,.tests/**` |
| **Best practices** | `best-practices.instructions.md` | `spells/**,.tests/**` |
| **Test environment** | `testing-environment.md` | `.tests/**` |

## 🔍 Finding Information

### By Task

**I need to...**
- Create a new spell → `spells.instructions.md` + `QUICK-REFERENCE.md`
- Create an imp → `imps.instructions.md` + `QUICK-REFERENCE.md`
- Write a test → `tests.instructions.md` + `QUICK-REFERENCE.md`
- Add logging → `logging.instructions.md`
- Fix cross-platform issue → `cross-platform.instructions.md`
- Understand why test fails in CI → `testing-environment.md`
- Learn proven patterns → `best-practices.instructions.md`
- Understand project philosophy → `README.md`

### By Question

**What is...**
- A spell? → `README.md` (Spells section) + `spells.instructions.md`
- An imp? → `README.md` (Imps section) + `imps.instructions.md`
- The test framework? → `tests.instructions.md`
- Function discipline? → `best-practices.instructions.md` (Function Discipline section)
- Self-execute pattern? → `best-practices.instructions.md` (Self-Execute Pattern section)
- env-clear? → `best-practices.instructions.md` (env-clear Sourcing Pattern section)

**How do I...**
- Use output imps (say, warn, die)? → `logging.instructions.md`
- Handle errors? → `logging.instructions.md` (Error Handling section)
- Create temp files? → `QUICK-REFERENCE.md` or `.AGENTS.md`
- Check if command exists? → `QUICK-REFERENCE.md` (has command pattern)
- Make code cross-platform? → `cross-platform.instructions.md`
- Stub in tests? → `tests.instructions.md` (Stub Imps section)
- Avoid common mistakes? → `QUICK-REFERENCE.md` (Common Mistakes section)

## 📚 Reference Documentation

### Project-Wide

| File | Purpose | Length |
|------|---------|--------|
| `README.md` | Project overview, values, glossary | Long |
| `.AGENTS.md` | Comprehensive style guide | 773 lines |
| `.github/copilot-instructions.md` | Copilot entry point | ~100 lines |
| `.github/QUICK-REFERENCE.md` | Quick patterns | ~200 lines |
| `.github/AI-ONBOARDING.md` | Onboarding guide | ~400 lines |

### Specialized

| File | Purpose | Lines |
|------|---------|-------|
| `.github/EXEMPTIONS.md` | Documented exceptions to rules | Long |
| `.github/INTERACTIVE_SPELLS.md` | Interactive spell handling | Medium |
| `.github/COMPILED-TESTING.md` | Compiled spell testing | Short |
| `.github/workflows/README.md` | CI/CD workflows | Short |

## 🗂️ Historical Archive

Obsolete documentation is archived in `.github/archive/`:
- `MIGRATION-LOGGING.md` — Logging migration (completed)
- `CODEX.md` — OpenAI Codex instructions (superseded)
- `pr-557-fixes.md` — PR #557 fixes (integrated)

See `.github/archive/README.md` for details.

## 📋 Documentation Standards

All instruction files in `.github/instructions/` should:
1. Start with `# Title`
2. Include `applyTo: "path/pattern"` on line 2-3
3. Provide focused, actionable guidance
4. Reference other docs for additional context

## 🎓 Learning Path

**Recommended reading order for new AI agents:**

1. **`.github/AI-ONBOARDING.md`** (complete guide)
2. **`README.md`** (Values, Design Tenets, Engineering Standards sections)
3. **`.github/QUICK-REFERENCE.md`** (templates and patterns)
4. Topic-specific file based on your task:
   - Creating spell → `spells.instructions.md`
   - Creating imp → `imps.instructions.md`  
   - Creating test → `tests.instructions.md`
5. **`best-practices.instructions.md`** (proven patterns)
6. **`.AGENTS.md`** (comprehensive reference as needed)

## 🔗 Quick Links

**Most Common Tasks:**
- New spell template → `.github/QUICK-REFERENCE.md` → "Spell Template"
- New imp template → `.github/QUICK-REFERENCE.md` → "Imp Template"
- New test template → `.github/QUICK-REFERENCE.md` → "Test Template"
- Output patterns → `.github/instructions/logging.instructions.md`
- Common mistakes → `.github/QUICK-REFERENCE.md` → "Common Mistakes"

---

**Still can't find what you need?** Check `.AGENTS.md` — it's the comprehensive reference covering everything.
