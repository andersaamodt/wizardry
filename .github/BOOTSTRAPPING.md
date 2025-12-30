# Wizardry Bootstrapping and Initialization Paradigm

## Overview

This document defines the **bootstrapping and initialization sequence** for wizardry—the ordered phases through which a system progresses from bare POSIX to a fully functional wizardry environment. Understanding this sequence is critical for both users and developers.

## Key Concepts

### Bootstrap vs Initialization

- **Bootstrapping**: The process of preparing a system to run wizardry (Phases 0-2)
- **Initialization**: The process of activating wizardry in a shell session (Phase 3)
- **Validation**: The process of verifying wizardry readiness at different levels (Phase 4)

### Bootstrap Script vs Bootstrap Spell

- **Bootstrap script**: A script that runs **before** wizardry is fully installed and available. These scripts cannot assume wizardry is in PATH or that imps are available.
  - Examples: `install`, `spells/install/core/*`, `detect-distro`, `detect-rc-file`
  - Characteristics: Self-contained, minimal dependencies, inline implementations
  
- **Bootstrap spell**: A spell that can be invoked **after** wizardry is installed, but represents foundational functionality needed early in the spell level hierarchy.
  - Examples: `banish` (Level 1), `validate-spells` (Level 1)
  - Characteristics: Can use wizardry imps, assumes `invoke-wizardry` has been sourced

## The Five Phases of Wizardry Bootstrapping

```
Phase 0: POSIX Foundation
    ↓
Phase 1: Download & Install
    ↓
Phase 2: Shell Integration
    ↓
Phase 3: Runtime Invocation
    ↓
Phase 4: Validation & Banishment
```

### Phase 0: POSIX Foundation (Spell Level 0)

**Purpose**: Ensure the system has a working POSIX environment.

**Prerequisites**: None (most fundamental level)

**Actions**:
- POSIX shell available (`/bin/sh`)
- Core utilities present (`cat`, `grep`, `awk`, `sed`, `find`, etc.)
- Standard PATH includes `/bin` and `/usr/bin`
- Either `curl` or `wget` available for downloads
- `tar` available for unpacking archives
- Package manager available (platform-specific)

**Validation**: Run `detect-posix` or `banish 0`

**Responsible scripts**:
- `spells/divination/detect-posix` - Validates POSIX environment
- `spells/divination/detect-distro` - Identifies OS and package manager
- `spells/system/verify-posix` - Comprehensive POSIX validation

**Self-healing**: Spell Level 0 spells can attempt to install missing POSIX utilities, but this is platform-specific and may require manual intervention if package managers aren't available.

---

### Phase 1: Download & Install (Spell Level 1 Prerequisites)

**Purpose**: Download wizardry files and place them on disk.

**Prerequisites**: Phase 0 complete

**Actions**:
1. User runs `./install` (from cloned repo) OR `curl ... | sh` (remote install)
2. Install script downloads/copies wizardry to `~/.wizardry` (or user-specified location)
3. Sets `WIZARDRY_DIR` environment variable
4. Validates directory structure exists (`spells/`, `spells/.imps/`, etc.)

**Validation**: Check that `$WIZARDRY_DIR/spells` exists and is readable

**Responsible scripts**:
- `install` - Main installer (bootstrap script, not a spell)
- `spells/.arcana/core/install-core` - Core prerequisite installer (bootstrap script)

**Output**: Wizardry files on disk at `$WIZARDRY_DIR`

**Note**: At this phase, wizardry is **downloaded but not yet usable**. The spells are on disk but not in PATH, and no shell integration exists.

---

### Phase 2: Shell Integration (Spell Level 1 Completion)

**Purpose**: Integrate wizardry into the user's shell startup files.

**Prerequisites**: Phase 1 complete

**Actions**:
1. Install script detects shell configuration file (`.bashrc`, `.zshrc`, etc.)
2. Adds source line to rc file: `. "$WIZARDRY_DIR/spells/.imps/sys/invoke-wizardry"`
3. Optionally enables MUD features (CD hook, etc.)
4. Creates `~/.spellbook` directory for user spells
5. Creates uninstall script

**Validation**: Grep for `invoke-wizardry` in shell rc file

**Responsible scripts**:
- `install` - Adds source line to shell rc
- `spells/divination/detect-rc-file` - Identifies correct shell rc file (bootstrap script)
- `spells/.imps/sys/nix-shell-add` - NixOS-specific shell integration (bootstrap script)

**Output**: Shell configuration modified, but **wizardry not yet active in current shell**

**Note**: At this phase, wizardry will be available in **new shell sessions**, but the current terminal hasn't loaded it yet.

---

### Phase 3: Runtime Invocation (Spell Levels 2-3)

**Purpose**: Activate wizardry in a running shell session.

**Prerequisites**: Phase 2 complete (or manual sourcing of invoke-wizardry)

**Actions**:
1. Shell sources `invoke-wizardry` during startup (or user sources it manually)
2. `invoke-wizardry` sets up environment:
   - Sets `WIZARDRY_DIR`
   - Sets `SPELLBOOK_DIR`
   - Creates glossary directory
   - Pre-loads essential imps (Levels 0-3)
   - Pre-loads essential spells (Levels 0-3)
   - Starts background gloss generation
3. Glossary system makes all spells available via PATH
4. Menu system becomes functional

**Validation**: Run `command -v menu` - should find the menu function

**Responsible scripts**:
- `spells/.imps/sys/invoke-wizardry` - Main runtime initialization (bootstrap script)
- `spells/.imps/sys/word-of-binding` - Spell/imp loading mechanism
- `spells/system/generate-glosses` - Creates glosses (thin wrappers for PATH)

**Output**: Wizardry fully functional in current shell

**Critical distinction**: This is **invocation**, not installation. Installation (Phase 1-2) happens once. Invocation (Phase 3) happens every time a new shell starts.

---

### Phase 4: Validation & Banishment (Spell Levels 1-29)

**Purpose**: Validate wizardry readiness at progressively higher levels of functionality.

**Prerequisites**: Phase 3 complete (wizardry invoked)

**Actions**:
1. User runs `banish N` where N is the desired validation level (0-29)
2. Banish validates each level from 0 through N:
   - Checks assumptions (files exist, commands available, etc.)
   - Attempts self-healing if issues found
   - Validates spells and imps at that level
3. Reports success/failure for each level

**Validation levels**:
- `banish 0` - POSIX foundation only
- `banish 1` - Wizardry installed and validated
- `banish 2` - Glossary system ready
- `banish 3` - Menu system functional (default)
- `banish 4-29` - Progressive feature validation
- `banish all` - Full system validation

**Responsible scripts**:
- `spells/system/banish` - Main validation orchestrator (bootstrap spell)
- `spells/system/validate-spells` - Spell/imp existence checker (bootstrap spell)
- `spells/.imps/sys/spell-levels` - Level definition data

**Output**: Confidence that wizardry is ready for use at the specified level

**Note**: Banish is **not part of installation**. It's a validation and maintenance tool. You can run `banish` any time to verify system health, but it requires wizardry to already be invoked (Phase 3 complete).

---

## The Bootstrap Paradox: Banish vs Install

### The Conceptual Problem

Ideally, `banish` would run **before** installing wizardry to prepare the system. However, `banish` is itself a wizardry spell that requires:
- Wizardry to be installed (Phase 1 complete)
- Wizardry to be invoked (Phase 3 complete)
- Access to wizardry imps and spells

### The Resolution

**Banish is not a pre-installation tool—it's a post-installation validator.**

The correct sequence is:

```
1. User ensures POSIX foundation exists (manual or detect-posix)
2. User runs ./install (Phase 1-2)
3. User sources invoke-wizardry OR opens new terminal (Phase 3)
4. User runs banish to validate (Phase 4)
```

**Why this works**:
- Phase 0 (POSIX) is validated by `detect-posix` and handled by the install script
- Install script is self-contained and handles missing prerequisites
- Banish runs after installation to validate that everything is correct
- If banish finds issues, it self-heals them

**Mental model**: Think of `banish` as "git status" for wizardry health, not as a setup script.

---

## Bootstrap Script Requirements

Scripts that run **before** Phase 3 (invoke-wizardry) must follow special rules:

### Cannot Assume

- ❌ Wizardry is in PATH
- ❌ Imps are available as commands
- ❌ Other wizardry spells exist
- ❌ `WIZARDRY_DIR` is set (unless setting it themselves)
- ❌ User has wizardry-specific environment

### Must Be

- ✅ Self-contained (all logic inline or in the same file)
- ✅ POSIX-compliant (`#!/bin/sh`)
- ✅ Explicit about dependencies (check before using)
- ✅ Executable directly from cloned repo
- ✅ Functional when downloaded via curl/wget

### Examples of Bootstrap Scripts

**Pure bootstrap scripts** (run before any wizardry exists):
- `install` - Main installer
- `spells/install/core/*` - Core prerequisite installers
- `spells/divination/detect-posix` - Can run standalone
- `spells/divination/detect-distro` - Can run standalone
- `spells/divination/detect-rc-file` - Can run standalone

**Hybrid bootstrap scripts** (start as bootstrap, become wizardry-aware):
- `install` - Uses wizardry spells after downloading them
- Helpers like `detect-rc-file` can be called both ways

---

## Spell Level Correspondence

The bootstrapping phases align with spell levels:

| Phase | Spell Levels | Description |
|-------|--------------|-------------|
| Phase 0 | Level 0 | POSIX Foundation |
| Phase 1 | Level 1 (partial) | Installation on disk |
| Phase 2 | Level 1 (complete) | Shell integration |
| Phase 3 | Levels 2-3 | Invocation (Glossary + Menu) |
| Phase 4 | Levels 0-29 | Validation at any level |

**Key insight**: Spell levels define **functional capabilities**, not installation phases. A system can have all spells installed (Phase 1-2 complete) but not be validated past Level 3 until someone runs `banish N`.

---

## Bootstrapping Use Cases

### Fresh Install (Developer)

```bash
# Phase 0: Already have POSIX (or would detect and fix)
git clone https://github.com/andersaamodt/wizardry ~/.wizardry
cd ~/.wizardry

# Phase 1-2: Install and integrate
./install

# Phase 3: Invoke (new terminal or source)
# Option A: New terminal (auto-invokes)
# Option B: Source manually
. ~/.wizardry/spells/.imps/sys/invoke-wizardry

# Phase 4: Validate
banish 3  # Validate through menu system
```

### Remote Install (End User)

```bash
# Phase 0: Already have POSIX (or install handles it)

# Phase 1-2: One-command install
curl -fsSL https://raw.githubusercontent.com/andersaamodt/wizardry/main/install | sh

# Phase 3: Invoke (new terminal recommended)
# Close and reopen terminal

# Phase 4: Validate and use
menu  # If this works, validation passed
banish 3  # Explicit validation
```

### Repair Broken Installation

```bash
# Phase 3: Invoke (if not already)
. ~/.wizardry/spells/.imps/sys/invoke-wizardry

# Phase 4: Diagnose and repair
banish 1 --no-heal  # Diagnose without fixing
banish 1  # Diagnose and self-heal

# If Level 1 works, validate higher levels
banish 3  # Menu system
banish all  # Everything
```

### CI/Automated Testing

```bash
# Phase 0-2: Install wizardry (cached or fresh)
./install

# Phase 3: Source invoke-wizardry
. spells/.imps/sys/invoke-wizardry

# Phase 4: Validate specific levels
banish 12  # Validate through testing infrastructure
test-magic  # Run test suite
```

---

## The Role of `require-wizardry`

### What is `require-wizardry`?

`require-wizardry` is an **imp** (micro-helper) that checks if wizardry has been invoked in the current shell session. It verifies that:
- `WIZARDRY_DIR` is set
- `WIZARDRY_DIR` points to a valid wizardry installation (has `spells/` directory)

### When to Use `require-wizardry`

**Use in castable spells** (spells that can be both executed and sourced):

```sh
#!/bin/sh

spell_name() {
case "${1-}" in
--help|--usage|-h)
  spell_name_usage
  return 0
  ;;
esac

require-wizardry || return 1  # ← Check before using wizardry features

set -eu
env-clear

# Spell logic that uses wizardry imps/spells
}

castable "$@"
```

**Why use `return 1` instead of `exit 1`?**

When a spell is sourced (not executed), `exit` would terminate the entire shell session. Using `return` exits only the function, making the spell safe to source.

### When NOT to Use `require-wizardry`

**Don't use in bootstrap scripts** (Phase 0-2):
- `install`
- `spells/install/core/*`
- `detect-posix`, `detect-distro`, `detect-rc-file`
- Any script that runs before invoke-wizardry

These scripts run **before** wizardry is invoked, so `require-wizardry` would always fail.

**Don't use in imps** (usually):

Imps are loaded by invoke-wizardry itself, so they can assume wizardry is available. Exception: imps that might be called during bootstrap (rare).

### `require-wizardry` vs `invoke-wizardry`

| Aspect | `require-wizardry` | `invoke-wizardry` |
|--------|-------------------|-------------------|
| **Type** | Imp (checker) | Imp (initializer) |
| **Purpose** | Verify wizardry is ready | Initialize wizardry |
| **When** | Inside spells | Shell startup |
| **Action** | Check + error if not ready | Set up environment |
| **Exit** | Returns 1 if not ready | Returns 1 if setup fails |
| **Frequency** | Every spell execution | Once per shell session |

**Mental model**:
- `invoke-wizardry` = "Turn on wizardry" (Phase 3)
- `require-wizardry` = "Is wizardry on?" (runtime check)

### Test Mode Exception

In test mode (`WIZARDRY_TEST_HELPERS_ONLY=1`), `require-wizardry` always returns success. This allows tests to run spells without going through full invocation, since test-bootstrap sets up PATH directly.

---

## Environment Variables by Phase

### Phase 0: POSIX Foundation
- `PATH` - Must include `/bin`, `/usr/bin`
- `HOME` - Usually set by OS
- `TMPDIR` - Usually set by OS

### Phase 1: Download & Install
- `WIZARDRY_INSTALL_DIR` - Override default install location
- `WIZARDRY_INSTALL_ASSUME_YES` - Non-interactive install
- `WIZARDRY_INSTALL_MUD` - Auto-enable MUD features

### Phase 2: Shell Integration
- (none - all handled by install script)

### Phase 3: Runtime Invocation
- `WIZARDRY_DIR` - Set by invoke-wizardry (required by require-wizardry)
- `SPELLBOOK_DIR` - Set by invoke-wizardry
- `WIZARDRY_DEBUG` - Enable diagnostic output
- `_WIZARDRY_INVOKED` - Set to 1 by invoke-wizardry (prevents re-invocation)

### Phase 4: Validation
- `WIZARDRY_LOG_LEVEL` - Control verbosity (0-2)
- (Level-specific environment variables as needed)

### Testing
- `WIZARDRY_TEST_HELPERS_ONLY` - Set to 1 in tests (makes require-wizardry always succeed)

---

## Key Components and Their Relationships

This section clarifies how the main bootstrapping components relate to each other.

### The Bootstrap Trinity

```
install (bootstrap script)
    ↓ downloads/configures
invoke-wizardry (bootstrap script → becomes runtime)
    ↓ initializes
require-wizardry (runtime checker)
    ↓ validates
banish (validation spell)
```

### Component Comparison Table

| Component | Type | Phase | Can Use Wizardry? | Purpose |
|-----------|------|-------|-------------------|---------|
| `install` | Bootstrap script | 1-2 | No (self-contained) | Download and configure wizardry |
| `detect-posix` | Bootstrap script | 0 | No (self-contained) | Validate POSIX environment |
| `detect-distro` | Bootstrap script | 0 | No (self-contained) | Identify OS and package manager |
| `detect-rc-file` | Bootstrap script | 2 | No (self-contained) | Find shell rc file |
| `invoke-wizardry` | Bootstrap script | 3 | No (but loads wizardry) | Initialize wizardry environment |
| `require-wizardry` | Imp | 3+ | Yes (is wizardry) | Check if wizardry is ready |
| `banish` | Spell (Level 1) | 4 | Yes (requires wizardry) | Validate spell levels |
| `validate-spells` | Spell (Level 1) | 4 | Yes (requires wizardry) | Check spell/imp existence |
| Regular spells | Spells | 3+ | Yes (assumes wizardry) | Normal functionality |

### Decision Tree: Which Component Do I Need?

```
Are you writing code that runs BEFORE wizardry is installed?
├─ Yes → Bootstrap script (self-contained, no wizardry)
│         Examples: install, detect-posix, detect-distro
│
└─ No → Is wizardry invoked (Phase 3 complete)?
    ├─ No → Cannot proceed (need invoke-wizardry first)
    │
    └─ Yes → What do you need to do?
        ├─ Check if wizardry is ready → Use require-wizardry
        ├─ Validate specific levels → Use banish N
        ├─ Check spell/imp existence → Use validate-spells
        └─ Normal spell functionality → Use regular spell patterns
```

### Execution Context Matrix

| Context | install | invoke-wizardry | require-wizardry | banish | Regular spell |
|---------|---------|-----------------|------------------|--------|---------------|
| Before wizardry installed | ✅ Run | ❌ Fail | ❌ Fail | ❌ Fail | ❌ Fail |
| After install, before invoke | ❌ Done | ✅ Run | ❌ Fail | ❌ Fail | ❌ Fail |
| After invoke, normal usage | ❌ Done | ✅ Noop | ✅ Pass | ✅ Run | ✅ Run |
| During test-bootstrap | ❌ N/A | ✅ Partial | ✅ Pass | ✅ Run | ✅ Run |

### Common Patterns

#### Pattern 1: Bootstrap Script (Cannot Use Wizardry)

```sh
#!/bin/sh
# detect-something - bootstrap script

set -eu

# Cannot use wizardry imps or spells
# Must check for commands before using them
if ! command -v git >/dev/null 2>&1; then
  printf 'Error: git not found\n' >&2
  exit 1
fi

# Self-contained logic here
```

#### Pattern 2: Regular Spell (Assumes Wizardry)

```sh
#!/bin/sh

spell_name() {
case "${1-}" in
--help) usage; return 0 ;; esac

require-wizardry || return 1  # Safety check

set -eu
env-clear

# Can freely use imps and other spells
has git || die "spell-name: git required"
say "Processing..."
}

castable "$@"
```

#### Pattern 3: Hybrid (Starts as Bootstrap, Becomes Wizardry)

```sh
#!/bin/sh
# install - hybrid script

# Phase 1: Bootstrap logic (self-contained)
set -eu
download_wizardry

# Phase 2: Now wizardry is available
WIZARDRY_DIR=/path/to/wizardry
export WIZARDRY_DIR

# Can now use wizardry helpers
"$WIZARDRY_DIR/spells/divination/detect-rc-file"
```

---

## Common Misconceptions

### ❌ "Run banish before install to prepare the system"

**Wrong**: Banish is a wizardry spell that requires wizardry to be installed and invoked.

**Right**: Run `install`, then run `banish` to validate.

### ❌ "invoke-wizardry installs wizardry"

**Wrong**: `invoke-wizardry` assumes wizardry is already installed. It's an initialization script.

**Right**: `install` installs wizardry. `invoke-wizardry` activates it in a shell session.

### ❌ "require-wizardry is the same as invoke-wizardry"

**Wrong**: They serve completely different purposes.

**Right**: `invoke-wizardry` initializes wizardry (Phase 3). `require-wizardry` checks if initialization succeeded (runtime validation).

### ❌ "All bootstrap scripts can use wizardry imps"

**Wrong**: Only scripts that run during/after Phase 3 can use imps.

**Right**: Scripts in `install` and `spells/install/core/` must be self-contained.

### ❌ "require-wizardry should use exit 1"

**Wrong**: `exit` terminates the shell when a spell is sourced.

**Right**: Use `return 1` so spells are safe to source without killing the shell.

### ❌ "Spell levels are installation phases"

**Wrong**: Spell levels define functional dependencies, not installation order.

**Right**: All spells are installed in Phase 1-2. Spell levels define validation order in Phase 4.

### ❌ "require-wizardry initializes wizardry"

**Wrong**: `require-wizardry` only checks if wizardry is ready.

**Right**: `invoke-wizardry` does initialization. `require-wizardry` does validation.

---

## Comparison with Traditional Software

| Wizardry Phase | Similar To |
|----------------|------------|
| Phase 0: POSIX Foundation | System requirements check |
| Phase 1: Download & Install | `sudo make install` |
| Phase 2: Shell Integration | `source ~/.bashrc` modification |
| Phase 3: Runtime Invocation | Shell startup sequence |
| Phase 4: Validation | `make test` / health check |

**Key difference**: Most software doesn't have Phase 3. Wizardry's glossary/invocation system is unique.

---

## Implementation Checklist

When creating or modifying wizardry components:

### For Bootstrap Scripts (Phase 0-2)
- [ ] Uses `#!/bin/sh` shebang
- [ ] Does not assume wizardry in PATH
- [ ] Does not use wizardry imps
- [ ] Checks for required commands before using them
- [ ] Works when run from fresh git clone
- [ ] Self-contained (or depends only on other bootstrap scripts)

### For Bootstrap Spells (Phase 4)
- [ ] Can run after `invoke-wizardry` is sourced
- [ ] Uses wizardry imps freely
- [ ] Validates specific spell level functionality
- [ ] Self-heals when possible
- [ ] Provides clear error messages when self-healing isn't possible

### For Regular Spells
- [ ] Assumes wizardry is invoked (Phase 3 complete)
- [ ] Uses `require-wizardry` if critical
- [ ] Declares spell level in `spell-levels` imp
- [ ] Has corresponding tests

---

## Maintenance and Evolution

As wizardry grows, maintain clarity about bootstrapping:

1. **New bootstrap scripts**: Document why they can't use wizardry
2. **New spell levels**: Update `spell-levels` imp and this document
3. **Banish improvements**: Keep aligned with spell level definitions
4. **Install changes**: Preserve bootstrap script characteristics

---

## Summary: The Complete Picture

```
┌─────────────────────────────────────────────────────────┐
│ Phase 0: POSIX Foundation (Level 0)                     │
│ • Validate: detect-posix                                │
│ • Fix: OS package manager + manual intervention         │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────┐
│ Phase 1: Download & Install (Level 1 prerequisites)    │
│ • Action: ./install (bootstrap script)                  │
│ • Downloads wizardry to ~/.wizardry                     │
│ • Wizardry on disk, not yet usable                      │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────┐
│ Phase 2: Shell Integration (Level 1 complete)          │
│ • Action: install adds invoke-wizardry to shell rc     │
│ • Creates ~/.spellbook                                  │
│ • Ready for invocation in new shells                    │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────┐
│ Phase 3: Runtime Invocation (Levels 2-3)               │
│ • Action: Shell sources invoke-wizardry at startup     │
│ • Loads imps, creates glosses, prepares environment     │
│ • Wizardry fully functional                             │
└────────────────┬────────────────────────────────────────┘
                 │
                 ↓
┌─────────────────────────────────────────────────────────┐
│ Phase 4: Validation & Banishment (Levels 0-29)         │
│ • Action: banish N (optional, for validation)          │
│ • Validates specific functionality levels               │
│ • Self-heals issues when possible                       │
│ • Provides confidence in system health                  │
└─────────────────────────────────────────────────────────┘
```

**Remember**: Installation (Phases 1-2) happens **once**. Invocation (Phase 3) happens **every shell**. Validation (Phase 4) happens **on demand**.

The spell level system (0-29) defines **what** wizardry can do at each tier of functionality. The bootstrap phases (0-4) define **how** wizardry gets from nothing to fully functional.
