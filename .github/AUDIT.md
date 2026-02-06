# Wizardry Project Audit Framework

This document provides a structured, AI-performable audit of the Wizardry project based on its core ethos (Values, Policies, Design Tenets, and Engineering Standards as defined in README.md).

The audit converts ethos principles into actionable, repeatable verification parameters that can be systematically checked across the entire codebase.

**Related Documentation:**
- **README.md** - Project philosophy (Values, Policies, Design Tenets, Engineering Standards)
- **FULL_SPEC.md** - Technical specification
- **EXEMPTIONS.md** - Documented exceptions to standards
- **LESSONS.md** - Debugging insights

---

## Audit Checklist

This checklist converts each ethos principle into specific, repeatable verification steps.

### 🔤 Definitions & Terminology

- [ ] **1.1** Imps are counted as spells in all metrics and documentation
- [ ] **1.2** The term "spells" includes both user-facing spells and imps unless explicitly differentiated
- [ ] **1.3** Glossary terms in README.md match usage throughout codebase
- [ ] **1.4** Technical terminology is consistent across all documentation files
- [ ] **1.5** MUD-themed terms (arcana, cantrips, etc.) are used consistently

### 🌍 Cross-Platform Support

- [ ] **2.1** All target platforms are supported (debian, arch, macos, nixos)
- [ ] **2.2** Code does not explicitly support non-target platforms (e.g., fedora, bsd) unless necessary
- [ ] **2.3** All spells have cross-platform support where appropriate
- [ ] **2.4** Platform-neutral POSIX-compliant code is the default
- [ ] **2.5** Platform-specific code paths are clearly marked and justified
- [ ] **2.6** Platform detection uses `uname -s` consistently
- [ ] **2.7** Package manager detection works on all target platforms
- [ ] **2.8** PATH configuration works on all target platforms (especially macOS)
- [ ] **2.9** Temp directory handling accounts for macOS trailing slash in TMPDIR
- [ ] **2.10** No use of GNU-specific flags (e.g., `find -executable` vs `-perm /111`)

### 🚫 No Globals Policy

- [ ] **3.1** The globals in declare-globals are reasonable and minimal
- [ ] **3.2** Environment variables are NOT used to pass data between scripts
- [ ] **3.3** Arguments are used instead of environment variables for inter-script communication
- [ ] **3.4** All environment variable usage is documented and justified
- [ ] **3.5** Any exceptions are documented in EXEMPTIONS.md
- [ ] **3.6** User configuration via env vars is clearly distinguished from inter-script coordination
- [ ] **3.7** No hidden state passing via environment (verify WIZARDRY_LOG_LEVEL is config only)

### ⚡ No Functions Policy

- [ ] **4.1** No spells use functions (except `show_usage()` and minimal helpers per guidelines)
- [ ] **4.2** Function discipline is followed: `show_usage()` + at most 1-2 helpers
- [ ] **4.3** Spells with 2-3 extra functions are documented in EXEMPTIONS.md
- [ ] **4.4** No spells have 4+ extra functions (would indicate proto-library needing decomposition)
- [ ] **4.5** Scripts are linear and don't contain unnecessary control flow
- [ ] **4.6** Complex logic is extracted into imps rather than helper functions
- [ ] **4.7** Bootstrap scripts follow same function discipline
- [ ] **4.8** Imps have zero functions (flat, linear execution only)

### ✨ Minimalism

- [ ] **5.1** Spells are not bloated with gradually-added ornamentation
- [ ] **5.2** Everything in each spell has a purpose
- [ ] **5.3** Code fits within a streamlined model of POSIX best practices
- [ ] **5.4** No redundant or duplicate functionality across spells
- [ ] **5.5** Feature creep is actively resisted
- [ ] **5.6** Dependencies are minimal (prefer POSIX built-ins)
- [ ] **5.7** Each spell does one thing well (Unix philosophy)
- [ ] **5.8** Imps are atomic and single-purpose

### 📚 Didacticism (Teaching & Documentation)

- [ ] **6.1** Spells are well-commented for novices
- [ ] **6.2** Complex solutions include comments explaining WHY
- [ ] **6.3** Special cases are documented to prevent accidental removal
- [ ] **6.4** Comments are helpful without being excessive
- [ ] **6.5** Opening description comments are present and accurate (1-2 lines)
- [ ] **6.6** `--help` text is complete and serves as the spec
- [ ] **6.7** Code is written to be readable and educational
- [ ] **6.8** Novice-friendly variable names are used
- [ ] **6.9** Uncommon POSIX idioms are explained in comments
- [ ] **6.10** Magic values and hard-coded constants are explained

### ⚙️ POSIX Compliance

- [ ] **7.1** All scripts use `#!/bin/sh` shebang (no bash/zsh)
- [ ] **7.2** All scripts use `set -eu` strict mode (except conditional imps)
- [ ] **7.3** Conditional imps exempt from `set -eu` are documented
- [ ] **7.4** No bash-specific features (`[[`, `==`, arrays, `local`, etc.)
- [ ] **7.5** Use `$()` instead of backticks
- [ ] **7.6** Use `[ ]` instead of `[[ ]]`
- [ ] **7.7** Use `=` instead of `==` for string comparison
- [ ] **7.8** Use `.` instead of `source`
- [ ] **7.9** Use `printf` instead of `echo`
- [ ] **7.10** Use `command -v` instead of `which`
- [ ] **7.11** Use `pwd -P` instead of `realpath`
- [ ] **7.12** All variables are properly quoted: `"$var"`
- [ ] **7.13** Optional arguments use defaults: `${1-}` or `${1:-default}`
- [ ] **7.14** checkbashisms passes on all shell scripts
- [ ] **7.15** lint-magic passes on all shell scripts
- [ ] **7.16** Custom POSIX compliance checks make sense and are comprehensive
- [ ] **7.17** No portable command usage (e.g., `find -executable`)

### 📦 Portable Build

- [ ] **8.1** List of compiled spells makes sense (standalone, useful scripts)
- [ ] **8.2** List of excluded spells is justified (non-standalone or wizardry-dependent)
- [ ] **8.3** Compiled spells work without wizardry infrastructure
- [ ] **8.4** Portable build is tested and functional
- [ ] **8.5** Dependencies for standalone spells are documented

### 🎯 Values Alignment

- [ ] **9.1** Useful - Spells support common everyday computer tasks
- [ ] **9.2** Menu-driven - System manageable via `menu` without memorizing commands
- [ ] **9.3** Teaching community - Code serves as didactic exemplars
- [ ] **9.4** Cross-platform - Works on UNIX-like systems generally
- [ ] **9.5** File-first - All state in files (preferably human-readable text)
- [ ] **9.6** POSIX sh-first - Shell is primary language
- [ ] **9.7** FOSS missing link - Integrates UNIX tools into workflows
- [ ] **9.8** Semantic synthesis - Encapsulates platform details
- [ ] **9.9** Fun - Magic/MUD flavor text is present without obscuring functionality

### 📜 Policies Compliance

- [ ] **10.1** Non-commercial - No commercial integrations or dependencies
- [ ] **10.2** FOSS-first suite - Opinionated selection of free software
- [ ] **10.3** Built-in tools first - Uses OS package managers
- [ ] **10.4** Hand-finished AI code - AI-generated code is reviewed
- [ ] **10.5** No AI integration - Spells don't call AI services
- [ ] **10.6** No fallback forks - Fix primary path instead of adding alternates

### 🎨 Design Tenets

- [ ] **11.1** Minimalism - Fewest moving parts
- [ ] **11.2** Atomicity - Small, self-contained units
- [ ] **11.3** One magical action - One coherent action per spell
- [ ] **11.4** Document-in-place - `--help` fully specifies behavior
- [ ] **11.5** Interface-neutral - GUIs are thin skins over shell scripts
- [ ] **11.6** Menu specialization - Complex workflows use dedicated menus
- [ ] **11.7** Menu transparency - Menu items show clear commands
- [ ] **11.8** Output-first UX - Output readable and pipeable
- [ ] **11.9** Self-healing tone - Offers to fix problems vs barking orders

### 🔧 Engineering Standards - Shell & Idioms

- [ ] **12.1** Single-shell stance - All code is POSIX sh with `#!/bin/sh` and `set -eu`
- [ ] **12.2** POSIX-safe idioms - Proper command substitution, no `which`, etc.
- [ ] **12.3** Portable pathing - Uses `pwd -P` for resolution
- [ ] **12.4** Platform detection - Uses `uname -s` for kernel detection
- [ ] **12.5** Early descriptiveness - 1-2 line opening comment in all executables
- [ ] **12.6** Help-on-tap - `--help`/`-h`/`--usage` print concrete usage
- [ ] **12.7** Strict-yet-flat flows - Few functions, linear flow
- [ ] **12.8** Script-like scripts - Flat, shell-friendly logic

### 🏗️ Engineering Standards - Structure & Style

- [ ] **13.1** Function discipline - `show_usage()` + max 1-2 helpers
- [ ] **13.2** Front-facing spells - All spells are user-facing executables
- [ ] **13.3** Spell-by-name invocation - Spells call each other by name from PATH
- [ ] **13.4** Hyphenated, extensionless names - No `.sh`, hyphens for multi-word
- [ ] **13.5** Careful quoting - Variables quoted unless intentional word splitting
- [ ] **13.6** `printf` over `echo` - Use `printf '%s\n'` for portability
- [ ] **13.7** Deliberate temp handling - `mktemp` with cleanup
- [ ] **13.8** Gentle error contract - Try to repair prerequisites
- [ ] **13.9** Error prefixing - Errors to stderr with spell name prefix
- [ ] **13.10** Unified logging tone - Consistent style
- [ ] **13.11** Standardized flag parsing - Consistent pattern
- [ ] **13.12** Input normalization - Shared helpers normalize inputs
- [ ] **13.13** Linting & formatting - `lint-magic` passes
- [ ] **13.14** Standard exit codes - Proper use of 0/1/2/126/127/130
- [ ] **13.15** Directory-resolution idiom - Canonical pattern
- [ ] **13.16** Validation helpers - Reusable input checks
- [ ] **13.17** Naming scheme - Functions use snake_case (when needed)

### ✅ Testing Requirements

- [ ] **14.1** Tests are the spec - Behavior fully specified by tests
- [ ] **14.2** Tests are POSIX shell - Tests are POSIX-compliant
- [ ] **14.3** Help-as-spec - `--help` is primary spec
- [ ] **14.4** Mirrored tree - `.tests/` mirrors `spells/` structure
- [ ] **14.5** Shared test harness - Tests use imps for consistency
- [ ] **14.6** Unique behavior focus - Tests cover spell-specific behaviors
- [ ] **14.7** Full mode coverage - All paths and errors tested
- [ ] **14.8** Explicit shims - Minimal stubbing (only terminal I/O)
- [ ] **14.9** Sandboxed execution - `test-magic` uses bubblewrap isolation
- [ ] **14.10** Tests required - All tests pass before merge
- [ ] **14.11** Test file naming - Use hyphens not underscores: `test-name.sh`
- [ ] **14.12** All new spells/imps have corresponding tests

### 🎭 Theming & Flavor

- [ ] **15.1** MUD-themed vocabulary is used consistently
- [ ] **15.2** Magic/fantasy flavor text enhances usability
- [ ] **15.3** Theming doesn't obscure functionality
- [ ] **15.4** Theme is appropriate to spell purpose
- [ ] **15.5** Flavor text is neither excessive nor absent
- [ ] **15.6** Glossary terms are used correctly

### 📋 Documentation Standards

- [ ] **16.1** README.md is most canonical source for ethos
- [ ] **16.2** FULL_SPEC.md contains technical details (no redundancy with README)
- [ ] **16.3** SHELL_CODE_PATTERNS.md documents POSIX patterns
- [ ] **16.4** CROSS_PLATFORM_PATTERNS.md documents platform compatibility
- [ ] **16.5** EXEMPTIONS.md documents all exceptions
- [ ] **16.6** LESSONS.md contains debugging insights
- [ ] **16.7** Documentation is non-redundant across files
- [ ] **16.8** AI-facing docs are in `.github/` directory
- [ ] **16.9** User-facing docs are in project root

### 🔒 Security & Quality

- [ ] **17.1** No secrets committed to repository
- [ ] **17.2** Input validation for user-provided data
- [ ] **17.3** Safe handling of file paths (no injection)
- [ ] **17.4** Proper use of temp files with cleanup
- [ ] **17.5** No use of `eval` on untrusted input
- [ ] **17.6** Proper error handling prevents data loss
- [ ] **17.7** File operations are safe (check before overwrite)

### 🚀 Installation & Bootstrap

- [ ] **18.1** Bootstrap scripts work before wizardry is installed
- [ ] **18.2** Bootstrap scripts don't use wizardry infrastructure
- [ ] **18.3** `install` script works with minimal dependencies
- [ ] **18.4** PATH setup is correct on all platforms
- [ ] **18.5** Installation is idempotent
- [ ] **18.6** Uninstall/banish works correctly
- [ ] **18.7** Install/uninstall are symmetric

### 📊 Code Quality Metrics

- [ ] **19.1** No long lines (>100 chars) except quoted text (>60% quoted OK)
- [ ] **19.2** Consistent indentation (2 spaces)
- [ ] **19.3** No mixed tabs/spaces
- [ ] **19.4** No trailing whitespace
- [ ] **19.5** Files end with newline
- [ ] **19.6** Consistent variable naming (lowercase with underscores)
- [ ] **19.7** No dead code
- [ ] **19.8** No commented-out code blocks
- [ ] **19.9** No TODO comments without issues

### 🎯 Spell-Specific Standards

- [ ] **20.1** Each spell has opening description (1-2 lines)
- [ ] **20.2** Each spell has `show_usage()` function
- [ ] **20.3** Each spell handles `--help`/`-h`/`--usage`
- [ ] **20.4** Each spell uses proper exit codes
- [ ] **20.5** Spell names are unique and memorable
- [ ] **20.6** Spells are in appropriate category folders
- [ ] **20.7** Related spells are grouped logically

### 🔬 Imp-Specific Standards

- [ ] **21.1** Imps do exactly one thing
- [ ] **21.2** Imps have zero functions (flat execution)
- [ ] **21.3** Imps are in appropriate demon family folders
- [ ] **21.4** Imp names are self-documenting
- [ ] **21.5** Imps use space-separated args (no flags)
- [ ] **21.6** Imps have comment header (no `--help`)
- [ ] **21.7** Imps are cross-platform
- [ ] **21.8** Imps are reused by at least 2 spells (or planned for reuse)

---

## File Inventory & Audit Tracking

**See [AUDIT_RESULTS.md](AUDIT_RESULTS.md) for the complete audit results table.**

The audit results are maintained in a separate file to keep the rubric document focused. AUDIT_RESULTS.md contains:
- Executive summary with statistics
- Critical failures (🔴) requiring immediate attention
- Warnings (🟡) needing review
- Complete audit table for all 1395 files in the repository

**Legend:**
- 🟢 **Pass** - Meets all applicable standards
- 🟡 **Warning** - Minor issues or needs attention  
- 🔴 **Fail** - Significant issues requiring fixes
- ⚪ **N/A** - Not applicable to this file type
- 🔧 **Fixed** - Issue was resolved in this audit iteration

### Table Structure (in AUDIT_RESULTS.md)

| File Path | Last Audit | Result | Code | Docs | Theme | Policy | Issues | Fixes |
|-----------|------------|--------|------|------|-------|--------|--------|-------|
| *Complete table in AUDIT_RESULTS.md* | YYYY-MM-DD | 🟢/🟡/🔴/⚪ | 🟢/🟡/🔴/⚪ | 🟢/🟡/🔴/⚪ | 🟢/🟡/🔴/⚪ | 🟢/🟡/🔴/⚪ | Issues found | 🔧 if fixed |

### Column Descriptions

The rubric's 21 sections (184 items) are compressed into these columns:

1. **File Path** - Relative path from repository root
2. **Last Audit** - Date of most recent audit (YYYY-MM-DD format)
3. **Result** - Overall audit result (worst of all categories)
4. **Code** - Code Quality: Sections 7 (POSIX), 12-13 (Eng. Standards), 19 (Quality Metrics), 4 (Functions)
5. **Docs** - Comment Quality: Section 6 (Didacticism), opening comments, help text
6. **Theme** - Theming: Section 15 (Theming & Flavor), appropriate MUD vocabulary
7. **Policy** - No Policy Violations: Sections 3 (No Globals), 9-11 (Values/Policies/Tenets), 17 (Security)
8. **Issues** - Specific problems found during audit
9. **Fixes** - Changes made (🔧 indicates fixes applied in this iteration)

### Audit Workflow

When conducting an audit:

1. **Select file(s)** to audit from inventory
2. **Run through applicable checklist items** above
3. **Document issues** found
4. **Apply fixes** as needed
5. **Re-verify** after fixes
6. **Update table row** with:
   - Current date in "Last Audit"
   - Color-coded result (🟢 after fixes applied)
   - Color-coded assessment for each category
   - Bulleted list of changes made (if any)
7. **Commit changes** with descriptive message

### File Categories for Audit

Files are categorized by type for appropriate audit criteria:

**Shell Scripts (Spells)**
- Apply: Checklist sections 1-21
- Location: `spells/*/`, `install`
- Expected: All shell standards, theming, testing

**Shell Scripts (Imps)**
- Apply: Checklist sections 1, 2, 3, 5, 6, 7, 13, 14, 19, 21
- Location: `spells/.imps/*/`
- Expected: All imp-specific standards

**Test Scripts**
- Apply: Checklist sections 1, 2, 6, 7, 13, 14, 19
- Location: `.tests/*/`
- Expected: POSIX compliance, testing standards

**Documentation**
- Apply: Checklist sections 1, 16
- Location: `*.md`, `.github/*.md`
- Expected: Accuracy, non-redundancy, clarity

**Templates**
- Apply: Checklist sections 1, 15, 17
- Location: `.templates/*/`
- Expected: Security, appropriate theming

**Configuration**
- Apply: Checklist sections 1, 17
- Location: `.*ignore`, `.github/workflows/*`
- Expected: Security, completeness

**Desktop Apps**
- Apply: Checklist sections 1, 10, 17
- Location: `.apps/*/`
- Expected: Security, no policy violations

---

## Audit Execution Guide

### Quick Audit Commands

```sh
# POSIX compliance check
find spells .tests -type f ! -name '*.md' -exec checkbashisms {} \;

# Style/quality check
lint-magic --all

# Run all tests
test-magic

# Count functions in spells (should be ≤3: show_usage + 1-2 helpers)
grep -c '^[a-z_]*()' spells/*/* | grep -v ':0$' | grep -v ':1$' | grep -v ':2$' | grep -v ':3$'

# Find environment variable usage (audit for globals policy)
grep -r 'export ' spells/ | grep -v WIZARDRY_LOG_LEVEL

# Check for bash-isms in usage
grep -r '\[\[' spells/
grep -r ' == ' spells/

# Verify all spells have tests
comm -23 <(find spells -type f | sort) <(find .tests -type f | sed 's/\.tests/spells/' | sed 's/test-//' | sed 's/\.sh$//' | sort)
```

### Systematic Audit Process

1. **Preparation**
   - Pull latest code
   - Review recent changes in EXEMPTIONS.md and LESSONS.md
   - Identify audit scope (full audit vs targeted review)

2. **Automated Checks**
   - Run all automated tools (checkbashisms, lint-magic, test-magic)
   - Document any failures

3. **Manual Review**
   - Work through checklist systematically
   - Sample representative files from each category
   - Focus on recent changes and high-risk areas

4. **Documentation**
   - Update file inventory table
   - Add new lessons to LESSONS.md
   - Document new exemptions in EXEMPTIONS.md
   - Update FULL_SPEC.md if behavior clarified

5. **Fixes**
   - Apply fixes for identified issues
   - Re-run automated checks
   - Verify fixes don't break functionality

6. **Reporting**
   - Summarize audit findings
   - Track metrics over time
   - Identify systemic issues for project improvement

---

## Metrics & Trends

Track these metrics over time to measure project health:

### Quantitative Metrics

- Total files audited: ___/1394
- Files passing all checks: ___
- Files with warnings: ___
- Files with failures: ___
- POSIX compliance rate: ___%
- Test coverage: ___%
- Function discipline compliance: ___%
- Documentation completeness: ___%

### Qualitative Trends

- Code quality trajectory: [Improving/Stable/Declining]
- Comment quality: [Improving/Stable/Declining]
- Theming appropriateness: [Improving/Stable/Declining]
- Policy adherence: [Improving/Stable/Declining]

### Common Issues Found

*Track recurring issues here to inform systemic improvements*

1. ___
2. ___
3. ___

---

## Version History

- **2026-02-06**: Initial audit framework created
  - Comprehensive checklist covering all ethos principles
  - File inventory table structure established
  - Audit workflow documented

---

*This audit framework is a living document. Update it as standards evolve and new patterns emerge.*
