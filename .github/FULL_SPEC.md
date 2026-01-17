# Wizardry Full Specification

**Version**: 1.0.1  
**Last Updated**: 2026-01-10

## Purpose and Format

This is the canonical specification for the wizardry project. Every feature, subsystem, constraint, and behavioral detail is documented here in atomic form.

**Format**: Section headings with flat bullet lists. Each bullet is one sentence describing one conceptual unit or constraint.

**Organization**: Sections are organized under spell level headings (matching spell-levels imp, banish, test-magic, demo-magic), with multiple feature/subsystem sections under each level.

## Documentation Organization

Wizardry uses several focused documentation files. Keep content in the right document and avoid redundancy:

**Core documentation hierarchy:**

0. **README.md** - **MOST CANONICAL** - Project overview, philosophy (Values, Policies, Design Tenets, Engineering Standards), installation, user-facing features
1. **FULL_SPEC.md** ← **YOU ARE HERE** - Technical specification (implementation details, feature constraints, system architecture)
2. **SHELL_CODE_PATTERNS.md** - POSIX shell patterns and best practices (how/idioms)
3. **CROSS_PLATFORM_PATTERNS.md** - Cross-platform compatibility patterns
4. **EXEMPTIONS.md** - Documented exceptions to standards
5. **LESSONS.md** - Debugging insights and lessons learned

**Purpose**: Each document covers distinct content. README.md is the most canonical source for project philosophy and standards. FULL_SPEC.md focuses on technical implementation details and does NOT duplicate README.md content. Cross-reference between documents as needed.

**Maintenance**:
- Add new spec lines when implementing new features
- Update existing lines when features change or are clarified
- Reference and clarify this spec when debugging or when spec seems vague/outdated
- Keep synchronized with LESSONS.md when lessons reveal spec gaps or contradictions
- Ask user for revision when spec is confusing or conflicts are found
- Keep spec non-redundant - don't repeat constraints documented elsewhere in the same section

**Usage**: AI agents should reference this document frequently, present portions to users when seeking clarification, and keep it updated as the authoritative source of truth.

---

## Level 0: POSIX & Platform Foundation

### POSIX Shell Environment

- All wizardry code must run as POSIX sh (not bash, zsh, or other shells)
- Every executable file must start with `#!/bin/sh` shebang (no alternative shebangs allowed)
- All scripts must use `set -eu` strict mode (exit on error, error on undefined variables)
- Conditional imps (cond/, lex/, some menu/ families) are exempt from `set -eu` because they return exit codes for flow control
- The `set -eu` line must appear exactly once per file (no duplicates) after help handler but before main logic
- Sourced-only scripts that affect the parent shell must use `set +eu` (permissive mode) to avoid changing user's shell options

### POSIX Utilities Requirements

- Core utilities required: `sh`, `printf`, `test`, `command`, `[ ]`
- Path utilities required: `dirname`, `basename`, `cd`, `pwd`
- File utilities required: `cat`, `grep`, `find`, `sort`, `cp`, `mv`, `rm`
- Text processing required: `awk`, `sed`
- Temporary file creation: `mktemp` (for files and directories)
- System detection: `uname` (for kernel/platform detection)
- Download tools: either `curl` or `wget` must be available
- Archive tool: `tar` must be available
- Terminal settings: `stty` must be available for interactive features

### Platform Detection

- Operating system detected via `uname -s` (returns kernel name: Darwin, Linux, FreeBSD, etc.)
- Linux distribution detected via `/etc/os-release` file (when present)
- Package manager availability must be detected on each platform
- Architecture detected via `uname -m` (x86_64, aarch64, etc.)
- Platform detection must normalize variations (e.g., x86_64/amd64, aarch64/arm64)

### PATH Configuration

- Standard PATH must include both `/bin` and `/usr/bin` (especially critical on macOS)
- Bootstrap scripts must establish baseline PATH before `set -eu`: `/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin`
- PATH setup must check for existing standard directories before modification to avoid duplication
- Empty PATH at shell startup (macOS CI issue) must be detected and fixed

### Cross-Platform Compatibility

- Supported platforms: Linux (Debian, Ubuntu, Arch, Fedora, NixOS, Alpine), macOS 10.15+, BSD (FreeBSD, OpenBSD - limited)
- Code must work across shells: dash (Ubuntu default), bash (common), zsh (macOS default)
- Use `command -v` for checking command availability (never `which` or hardcoded paths like `/usr/bin/tool`)
- Use `pwd -P` for path resolution (never `realpath` which is not portable to all platforms)
- Use `find -type f -perm /111` or `-perm -100` for executable detection (never GNU-specific `-executable`)
- macOS-specific: TMPDIR often ends with `/`, requiring normalization via `${TMPDIR%/}` or `sed 's|//|/|g'`
- Use temp file pattern with TMPDIR: `mktemp -d "${TMPDIR:-/tmp}/prefix.XXXXXX"`

### POSIX Shell Idioms

- Use `$()` for command substitution (never backticks)
- Use `[ ]` for tests (never bash-specific `[[ ]]`)
- Use `=` for string comparison (never bash-specific `==`)
- Use `.` for sourcing (never bash-specific `source`)
- Quote all variable expansions unless word splitting is intentional: `"$var"`
- Provide defaults for optional arguments: `value=${1-}` (empty) or `value=${1:-default}`
- Use `printf '%s\n'` for output (never `echo` which has platform-specific behavior)
- No arrays (not POSIX) - use space-separated strings or multiple variables
- No `local` keyword (not POSIX) - use regular variable assignment
- Parameter expansion for string manipulation: `${var#pattern}` `${var##pattern}` `${var%pattern}` `${var%%pattern}`
- Parameter expansion for basename: `${file##*/}` (100x faster than subprocess `basename`)
- Parameter expansion for dirname: `${file%/*}` (faster than subprocess)
- Use `CDPATH=` to disable CDPATH for predictable cd behavior: `CDPATH= cd "$dir"`

### Standard Exit Codes

- 0: Success
- 1: General error
- 2: Usage/argument error  
- 126: Command cannot execute
- 127: Command not found
- 130: Interrupted (Ctrl-C)

---

## Level 1: Banish & Validation Infrastructure

### Wizardry Installation

- Wizardry must be installed to a directory (default: `~/.wizardry`)
- Installation directory path stored in `WIZARDRY_DIR` environment variable
- Spellbook directory path stored in `SPELLBOOK_DIR` environment variable (default: `~/.spellbook`)
- MUD configuration directory path stored in `MUD_DIR` environment variable
- `invoke-wizardry` must be sourceable and available after installation
- RC files (.bashrc, .zshrc, etc.) must source invoke-wizardry for shell integration

### Installation Process

- Installation can proceed via git clone or tarball download
- Installation requires either git or tar, plus curl or wget
- The `install` script is a bootstrap script that runs before wizardry is available
- Bootstrap scripts cannot use wizardry imps (must be self-contained)
- Installation must detect user's RC file and add wizardry initialization
- Installation must handle interruption/cancellation by cleaning up downloaded files

### Banish Spell (Assumption Checking & Self-Healing)

- Banish validates system state incrementally by spell level (0-28)
- Banish accepts level argument (e.g., `banish 3` validates levels 0-3)
- Banish without arguments defaults to level 3 (POSIX + wizardry + glossary + menu)
- Each banish level recursively validates all previous levels first
- Each level checks assumptions using corresponding check scripts
- Banish offers to self-heal broken assumptions with user confirmation
- Banish runs tests for spells at that level automatically (no prompt required)
- Banish supports flags: `--verbose` (detailed output), `--no-tests` (skip tests), `--no-heal` (report only)

### Output and Logging System

- All spells use standardized output imps from `out/` family
- Logging respects `WIZARDRY_LOG_LEVEL` environment variable: 0 (critical only), 1 (info), 2+ (debug)
- Level 0 (default): `say`, `warn`, `die`, `fail`, `success`, `usage-error` always shown
- Level 1+: `info` and `step` shown when WIZARDRY_LOG_LEVEL >= 1
- Level 2+: `debug` shown when WIZARDRY_LOG_LEVEL >= 2 (prefixed with "DEBUG:")
- `say` outputs to stdout with newline
- `warn` outputs warning to stderr (does not exit)
- `die` outputs error to stderr and exits with code 1 (or custom code if specified)
- `fail` outputs error to stderr and returns 1 (does not exit - for use in conditionals)
- `success` outputs success message to stdout
- `info` outputs informational message to stdout (respects log level)
- `step` outputs step message for multi-step processes to stdout (respects log level)
- `debug` outputs debug message to stderr with DEBUG: prefix (respects log level)
- `usage-error` outputs usage error to stderr and returns exit code 2
- Error messages must be descriptive not imperative (describe problem, don't tell user what to do)
- Error messages must be prefixed with spell name: "spell-name: error description"

### Signal Handling and Cleanup

- Use `on-exit` imp to register cleanup commands for EXIT, HUP, INT, TERM signals
- Cleanup functions registered with `on-exit` run automatically on script exit or interruption
- Use `clear-traps` imp to remove all signal handlers when cleanup is already done
- Temporary files created with `temp-file` imp
- Temporary directories created with `temp-dir` imp
- Cleanup files with `cleanup-file` imp
- Cleanup directories with `cleanup-dir` imp
- Bootstrap scripts must define their own cleanup patterns (cannot use wizardry imps)

### Conditional Imps (Testing & Flow Control)

- Conditional imps return exit codes for flow control (0 = true, non-zero = false)
- Conditional imps must NOT use `set -eu` because non-zero exits indicate false not error
- Conditional imp families: `cond/` (has, there, is, empty, etc.), `lex/` (parsing helpers), some `menu/` helpers
- Conditional imps designed for use in `if`, `&&`, `||` chains
- All other imps (action imps) must use `set -eu` strict mode
- Action imp families: `fs/`, `out/`, `paths/`, `pkg/`, `str/`, `sys/`, `text/`, `input/`, `lang/`

---

## Level 2: Installation Infrastructure

### Wizardry Globals

- Only three project-wide globals allowed: `WIZARDRY_DIR`, `SPELLBOOK_DIR`, `MUD_DIR`
- Globals managed by `declare-globals` imp
- Globals must be accessed with `set -u` to catch undefined variable errors
- All other variables must be lowercase (no all-caps local variables)
- Uppercase variables are reserved for environment variables
- Lowercase variables must never be exported (violates convention)
- Standard environment variables may be modified when needed: PATH, HOME, TMPDIR, IFS, CDPATH, SHELL, EDITOR, PAGER

### Variable Naming Convention

- Local variables must be lowercase: `distro`, `output`, `file_path`
- Environment variables must be uppercase: `WIZARDRY_DIR`, `PATH`, `HOME`
- Never export lowercase variables
- Never use uppercase for local variables (creates confusion with environment variables)
- Test infrastructure variables are exception (uppercase for coordination): TEST_FAILURE_REASON, TEST_SKIP_REASON, WIZARDRY_TEST_COMPILED

### File Operations

- Temporary files must use `temp-file` imp which wraps mktemp
- Temporary directories must use `temp-dir` imp which wraps mktemp -d
- Cleanup must use `cleanup-file` and `cleanup-dir` imps
- Register cleanup with `on-exit` for automatic execution on exit/interrupt
- File paths must be normalized to handle double slashes (macOS TMPDIR issue)
- Absolute paths constructed via cd/pwd pattern: `abs_path=$(cd "$(dirname "$file")" && pwd -P)/$(basename "$file")`
- Script directory detection: `script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)`

### String Operations

- String containment check: `str/contains` imp or `case` pattern matching
- String comparison: `str/equals`, `str/differs` imps or `=` test operator
- String prefix check: `str/starts` imp or `case` pattern
- String suffix check: `str/ends` imp or `case` pattern  
- Trim whitespace: `str/trim` imp
- Case conversion: `str/lower`, `str/upper` imps
- String length: `${#var}` parameter expansion

### Path Operations

- Get here (current directory): `paths/here` imp
- Get parent directory: `paths/parent` imp
- Get filename from path: `paths/file-name` imp (or `${path##*/}` for performance)
- Get absolute path: `paths/abs-path` imp
- Normalize path (remove .., ., //, trailing /): `paths/norm-path` imp
- Script directory: `paths/script-dir` imp
- Expand tilde paths: `paths/tilde-path` imp
- Make directories: `paths/make` imp
- Strip trailing slashes: `paths/strip-trailing-slashes` imp

---

## Level 3: Glossary & Parsing System

### Gloss Generation

- Glosses are generated for all spells to enable space-separated command syntax
- `generate-glosses` spell creates shell functions and aliases for multi-word commands
- Glossary directory contains executable gloss files (one per first word)
- Only glossary directory added to PATH (not spell or imp directories)
- Glosses enable `main menu` to work the same as `main-menu`
- Gloss generation runs synchronously during shell initialization (not backgrounded)

### Parsing System (parse imp)

- `parse` imp reconstructs multi-word commands from space-separated arguments
- Parser tries longest match first (e.g., `env or VAR` tries `env_or_VAR` → `env_or` → `env`)
- Parser searches in order: preloaded functions → wizardry spells → system commands
- Parser skips both functions AND aliases when trying system commands as fallback
- Parsing is deterministic and always resolves to most specific command match
- Space-separated commands work for all wizardry spells
- Multi-word spell names use hyphens: `main-menu`, `install-menu`, `jump-to-marker`

### Synonym System

- Synonyms (aliases) allow users to create custom command shortcuts
- Synonyms stored in `SPELLBOOK_DIR/.synonyms` as shell aliases
- Default synonyms can be overridden by user-defined synonyms
- Synonyms can be reset to defaults with `reset-default-synonyms` spell
- Custom synonyms managed via `add-synonym`, `edit-synonym`, `delete-synonym` spells
- Synonyms for hyphenated spells must expand to space-separated form to route through glosses
- Example: `alias jump-to-location='jump to marker'` not `'jump-to-marker'` (latter would execute not source)

### Synonym Naming Constraints

- Synonym words must be non-empty simple names
- Synonym words cannot contain: `/` `\` `|` `&` `;` `(` `)` `<` `>` `*` `?` `[` `]` `$` backtick `'` `"` space tab
- Synonym words cannot start with dash `-` (reserved for flags)
- Synonym words cannot start with dot `.` (reserved for hidden files)
- Synonym words cannot start with number (shell naming constraint)
- Shell keywords cannot be overridden: if, then, else, elif, fi, case, esac, for, while, until, do, done, in, function, time, select, {, }, [[, ]], !
- Protected builtins cannot be overridden: alias, cd, command, eval, exec, exit, export, pwd, return, set, shift, trap, unset, source, break, continue
- Critical system commands cannot be overridden: sh, find, grep, awk, sed, cat, ls, etc.
- Shell builtin `read` cannot be overridden (breaks while loops) even though `read-magic` spell exists
- Shell builtin `disable` cannot be overridden (bash builtin for disabling commands)

### Known Parser Limitations

- Parser cannot handle spaces within arguments for multi-word commands (would require quoting mechanism)
- Parser resolves ambiguity by longest match (no interactive disambiguation menu implemented yet)
- Characters in synonym words are restricted to prevent shell injection and parsing errors

---

## Level 4: Menu System

### Menu Architecture

- Interactive menu system is primary user interface to wizardry
- Menu invoked via `menu` command (also `main menu`, `main-menu`, or just typing `menu`)
- Menus display numbered list of commands with clear one-line descriptions
- Menu items show transparent commands using standard tools (teaching-oriented)
- Each menu item calls exactly one spell (no hidden multi-step operations)
- Complex workflows organized as dedicated menus (not hidden in scripts)

### Terminal Requirements

- Terminal must support ANSI escape codes for menu display
- TTY must be readable/writable for interactive input
- Terminal size detected via `fathom-terminal` spell
- Cursor position detected via `fathom-cursor` spell
- Cursor movement via ANSI escape codes (`move-cursor` spell)
- Cursor visibility control via `cursor-blink` spell

### Menu Navigation

- Navigation via number input (select item by number)
- Arrow keys for navigation (requires `await-keypress` spell)
- Keypress detection via `await-keypress` spell (handles ANSI escape sequences)
- Terminal raw mode for keypress detection (TTY must support stty)
- Terminal state saved with `tty-save` and restored with `tty-restore` imps

### Menu Display

- Menu rows rendered with consistent formatting
- Selected items highlighted (when supported)
- Categories shown with titles (via `menu/category-title` imp)
- Exit/back options labeled clearly (via `menu/exit-label` imp)
- Menu cursor positioned below menu items (via positioning functions)
- Menu cleans up terminal state on exit or interrupt

### Color System

- Colors defined in `cantrips/colors` spell (meant to be sourced)
- Color variables intentionally all-caps (match ANSI standard, improve readability)
- Colors: RED, GREEN, BLUE, YELLOW, CYAN, WHITE, BLACK, PURPLE, GREY/GRAY, LIGHT_BLUE
- Bright colors: BRIGHT_* variants (e.g., BRIGHT_RED, BRIGHT_GREEN)
- Background colors: BG_* variants (e.g., BG_BLACK, BG_RED)
- Formatting: RESET, BOLD, ITALICS, UNDERLINED, BLINK, INVERT, STRIKE
- Theme colors: THEME_WARNING, THEME_SUCCESS, THEME_ERROR, THEME_MUTED, THEME_HIGHLIGHT, THEME_HEADING, THEME_DIVIDER
- ESC variable holds ASCII escape character for building sequences
- Colors respect `WIZARDRY_COLORS_AVAILABLE` environment variable

---

## Level 5: Extended Attributes (Enchantment System)

### Extended Attribute Support

- Extended attributes (xattr) store metadata on files
- Extended attribute support varies by platform and filesystem
- macOS uses xattr natively
- Linux requires xattr tools package
- Fallback mechanisms when xattr unavailable (implementation varies by spell)
- Extended attribute helpers: `fs/attribute-tool-check`, `fs/attribute-list`, `fs/attribute-get`, `fs/attribute-set`, `fs/attribute-get-batch`

### Enchantment Spells

- `enchant` adds extended attributes (metadata) to files
- `disenchant` removes extended attributes from files
- `enchantment-to-yaml` converts xattr to YAML format
- `yaml-to-enchantment` converts YAML to xattr
- Enchantments enable MUD flavor (items have magical properties)
- Enchantments used for portkeys (bookmarks), room descriptions, player data

---

## Level 6: Task Priorities System

### Priority Management

- Tasks can have numeric priority values
- `get-priority` retrieves current priority for a task
- `get-new-priority` calculates new priority value
- `prioritize` sets priority for a task
- `upvote` increments priority
- `deprioritize` decrements priority
- Priorities stored in files (file-first architecture)

---

## Level 7-13: Domain-Specific Features

### Cryptography (Level 7)

- `hash` spell supports multiple hash algorithms
- Hash algorithms: MD5, SHA1, SHA256, SHA512, etc.
- `evoke-hash` displays hash value
- `hashchant` applies hash to input with chanting flavor

### SSH & Remote Access (Level 8)

- `validate-ssh-key` checks SSH key validity
- `enchant-portkey` creates SSH bookmarks
- `follow-portkey` connects via saved bookmark
- `open-portal` creates persistent SSH connection
- `open-teletype` opens interactive remote session
- SSH services can be reloaded/restarted

### Wards (Security) (Level 9)

- `ssh-barrier` hardens SSH security
- Security focused on SSH configuration
- Wards protect system via access control

### MUD Features (Level 10-11)

- MUD theme turns directories into rooms, files into items
- `look` describes current directory as a room
- `decorate` adds descriptions to directories/files
- `identify-room` detects room type (codebase features)
- CD hook integration for MUD navigation
- Command-not-found hook for flavor text (optional)
- Player management: `select-player`, `add-ssh-player`, `new-player`, `set-player`

### Navigation (Level 12)

- `jump-to-marker` navigates to bookmarked location
- `mark-location` creates navigation bookmark
- Markers stored in MARKERS_DIR

### Arcane File Operations (Level 13)

- `copy` copies files
- `trash` moves files to trash (safe deletion)
- `jump-trash` navigates to trash directory
- `forall` executes command for each file in directory
- `read-magic` reads and displays file contents
- `file-list` lists files with formatting

---

## Level 14-21: System Infrastructure

### Testing Infrastructure (Level 14)

- Test framework in `.tests/` directory mirrors `spells/` structure
- Every spell must have corresponding test file: `spells/category/spell-name` → `.tests/category/test-spell-name.sh`
- Test naming uses hyphens: `test-spell-name.sh` not `test_spell-name.sh`
- Tests are POSIX shell scripts that exercise spell behaviors
- Test bootstrap framework in `spells/.imps/test/test-bootstrap`
- Test helpers: `_run_spell`, `_assert_success`, `_assert_failure`, `_assert_output_contains`, `_assert_error_contains`
- Temp directory creation: `make_tempdir` helper
- `test-spell` runs individual spell test (includes common structural tests by default)
- `test-magic` discovers and runs all tests in `.tests/` directory
- Tests run in sandboxed bubblewrap environment (when available)
- Sandboxing gracefully falls back when bubblewrap unavailable
- Tests must stub terminal I/O (fathom-cursor, fathom-terminal, stty) not wizardry internals
- Stub imps in `spells/.imps/test/stub-*` provide reusable mocking
- Stub directory must be FIRST in PATH to override real commands
- Test real wizardry code; stub only bare minimum (terminal I/O)

### System Configuration (Level 15)

- Configuration stored in files (file-first architecture)
- `config` spell manages configuration
- Configuration helpers: `fs/config-get`, `fs/config-set`, `fs/config-has`, `fs/config-del`
- `logs` manages log viewing
- `package-managers` detects available package managers

### System Maintenance (Level 16)

- `update-wizardry` updates wizardry installation
- `update-all` updates system and wizardry
- `kill-process` terminates processes
- Process management commands available

### Divination (Detection) (Level 17)

- `detect-rc-file` finds user's shell RC file
- `detect-magic` analyzes file contents
- RC file candidates vary by shell: .bashrc, .zshrc, .profile, etc.
- RC file selection respects shell-specific conventions

### Service Management (Level 18-20)

- Service template installation via `install-service-template`
- Service status check: `is-service-installed`
- Service control: `enable-service`, `disable-service`, `start-service`, `stop-service`, `restart-service`, `service-status`
- Service removal: `remove-service`
- Services use systemd on Linux (when available)
- Service management requires appropriate privileges

---

## Level 22: Spellcraft (Development Tools)

### Spell Creation

- `scribe-spell` creates new spell from template
- New spells start with proper shebang, help handler, strict mode
- Spell templates follow project conventions
- Spells stored in `spells/category/` directories
- Spell categories: arcane, cantrips, crypto, divination, enchant, mud, psi, spellcraft, translocation, war, wards, .wizardry, menu

### Spell Management

- `learn` copies or links spell to spellbook (makes permanently available)
- `forget` removes spell from spellbook
- `erase-spell` deletes spell file
- `memorize` adds spell to cast menu for quick access
- Memorized spells appear in `cast` menu

### Linting and Validation

- `lint-magic` checks spell compliance with project standards
- Linting checks: POSIX compliance, style, naming, structure, function discipline
- `checkbashisms` tool detects bash-specific code (not in wizardry but used in CI)
- `validate-spells` validates all spells meet requirements

### Compilation (Doppelganger)

- `compile-spell` (via `doppelganger`) creates standalone spell
- Compiled spells inline all dependencies (imps) into single file
- Doppelganger creates portable builds (untested, not recommended for production)
- Compilation skip list: common words (is, fail, empty) and interactive imps
- Interactive imps must remain external for test stubbing: ask-*, await-keypress, select-input, read-line, tty-*
- Compiled spells exempt from flag/argument limits (inlined imp code inflates counts)
- Compiled spells exempt from function collision checks (intentional duplication)

### Synonym Management  

- `add-synonym` creates custom command alias
- `edit-synonym` modifies existing synonym
- `delete-synonym` removes synonym
- `reset-default-synonyms` restores default aliases
- `thesaurus` spell provides synonym browsing interface

### Tome Management

- `bind-tome` combines multiple files into single tome (concatenation)
- `unbind-tome` extracts files from tome
- Tomes enable easy transport of spell collections

### YAML Utilities

- `merge-yaml-text` merges YAML documents

---

## Level 23-26: Menu Infrastructure

### Core Menus (Level 23)

- `main-menu` is primary entry point (aliased as `menu`)
- `spellbook` menu organizes personal spells
- `spellbook-store` manages spellbook storage
- `cast` menu lists memorized spells for quick access
- `spell-menu` shows operations for specific spell

### System Menus (Level 24)

- `system-menu` for system configuration
- `install-menu` for software installation
- `synonym-menu` for synonym management
- `thesaurus` for browsing synonyms

### MUD Menus (Level 25)

- `mud-menu` for MUD features
- `mud-settings` for MUD configuration
- `mud-admin-menu` for MUD administration
- `mud` spell launches MUD interface

### Domain Menus (Level 26)

- `network-menu` for network operations
- `services-menu` for service management
- `shutdown-menu` for shutdown operations
- `priorities` menu (also `priority-menu`) for task priorities
- `users-menu` for user management

---

## Level 28: Optional Arcana (Third-Party Software)

### Arcana Architecture

- Arcana are installation wizards for optional third-party software
- Each arcanum knows correct installation method for all supported platforms
- Arcana stored in `spells/.arcana/` directory
- Arcana are exempt from some wizardry standards (bootstrap context)
- Arcana scripts allowed to use functions (documented exception to flat-file paradigm)
- Goal for arcana: minimize functions, aim for flat implementation when possible

### Available Arcana

- Core: Essential system tools, clipboard helpers, bubblewrap sandbox
- Bitcoin: Bitcoin Core node installation and management
- Lightning: Lightning Network node installation
- Node: Node.js runtime installation
- Tor: Tor network installation and configuration
- Simplex Chat: Simplex Chat messaging app
- MUD: MUD feature installation and CD hook

---

## Spell Structure and Style

### File Organization

- Spells in `spells/` directory (user-facing commands)
- Imps in `spells/.imps/` directory (micro-helpers, internal reusable)
- Tests in `.tests/` directory (mirror spell structure exactly)
- Bootstrap scripts: `install`, `spells/install/core/*` (run before wizardry available)

### Spell Requirements

- Shebang: `#!/bin/sh` (exactly, no variations)
- Opening comment: 1-2 lines describing purpose
- Help handler: `case "${1-}" in --help|--usage|-h) show_usage; exit 0 ;; esac` before `set -eu`
- Strict mode: `set -eu` after help handler, before main logic
- Usage function: `show_usage()` with heredoc (displays help text)
- Spell name in usage: "Usage: spell-name [options] [arguments]"
- Help text is primary spec (describes expected behavior)
- Cross-platform compatibility (work on Linux, macOS, BSD)
- No `.sh` extension (executables are extensionless)
- Multi-word names use hyphens: `spell-name` not `spell_name`
- Spell files must be executable (chmod +x)
- Tests required for every spell (non-negotiable)

### Imp Requirements

- Shebang: `#!/bin/sh`
- Opening comment: brief description (no show_usage function)
- Strict mode: `set -eu` for action imps, NO `set -eu` for conditional imps
- Imps are flat linear scripts (no functions, no wrappers)
- Imps do exactly one thing (single responsibility)
- Imps have self-documenting names (novices can understand without lookup)
- Imps use space-separated arguments (no `--flags`)
- No `--help` flag required (opening comment serves as spec)
- Cross-platform compatibility (abstract OS differences)
- Tests required for every imp (non-negotiable)

### Function Discipline

- Spells should be flat, linear scripts (scrolls, not programs)
- Maximum 1 function total in spells (including usage function)
- Usage/help text should be inline, not in a function
- Imps must have 0 functions (flat scripts only)
- Helper functions in spells discouraged (prefer flat code or extract to imps)
- Functions named in snake_case when needed: `show_usage`, `detect_os`, `validate_input`
- NEVER use hyphens in function names (POSIX shell doesn't support them)

### Code Style

- Quote all variables: `"$var"` not `$var`
- Provide defaults for optional args: `value=${1-}` or `value=${1:-default}`
- Use `printf '%s\n'` not `echo`
- Use `command -v` not `which`
- Use `[ ]` not `[[ ]]`
- Use `=` not `==` for string comparison
- Use `case` for pattern matching (more efficient than multiple ifs)
- Disable CDPATH for reliable cd: `CDPATH= cd "$dir"`
- One `set -eu` per file maximum (no duplicates)
- Bootstrap scripts define inline helpers (cannot use imps)

### Naming Conventions

- Spell names: lowercase with hyphens for multi-word (`main-menu`, `read-magic`)
- Imp names: lowercase with hyphens (`has`, `say`, `temp-file`)
- Function names: snake_case (`show_usage`, `cleanup`)
- Variable names: lowercase snake_case (`file_path`, `distro`)
- Environment variables: UPPERCASE (`WIZARDRY_DIR`, `PATH`, `HOME`)
- Never export lowercase variables (violates convention)
- Never use uppercase for local variables (creates confusion)

### Error Handling

- Errors go to stderr with spell name prefix: `printf '%s\n' "spell-name: error" >&2`
- Use output imps for consistency: `die`, `warn`, `fail`
- Error messages descriptive not imperative: "git not found" not "Please install git"
- Self-healing preferred: fix problems instead of demanding user action
- Exit codes: 0 (success), 1 (error), 2 (usage error), 126/127 (command issues), 130 (interrupted)

### Testing Requirements

- Every spell must have test file in `.tests/` (non-negotiable)
- Test file naming: `test-spell-name.sh` (hyphens not underscores)
- Test location mirrors spell: `spells/cat/spell` → `.tests/cat/test-spell.sh`
- Tests cover: help output, success cases, error cases, platform-specific fallbacks
- Tests use test framework helpers: `_run_spell`, `_assert_success`, `_assert_output_contains`
- Tests bootstrap via `test-bootstrap` imp (finds repo root, sources framework)
- Stub terminal I/O (fathom-cursor, stty) not wizardry logic
- Test results must be verified by running tests (never assume/guess pass/fail)
- Report actual test counts: "5/5 tests passed" not "tests should pass"

---

## Project Values and Philosophy

**See README.md for the canonical source of project philosophy and standards.**

README.md contains the complete "Ethos and Standards" section with:
- **Values** - Why the project exists and what principles guide its development
- **Policies** - Wizardry's stance toward software freedom, tooling, and the ecosystem  
- **Design Tenets** - How Wizardry should feel to use and how spells present themselves
- **Engineering Standards** - Technical requirements that all spells, menus, and supporting scripts must fulfill

This specification (FULL_SPEC.md) focuses on implementation details and does not duplicate README.md content.

---

## Build and Deployment

### Portable Build

- Portable build automatically generated (compiled standalone spells)
- Generated builds currently untested and not recommended for production
- Builds available as GitHub Actions artifacts (nightly)
- Doppelganger mode compiles spells with inlined dependencies

### CI/CD

- All CI checks required (no exemptions, no `continue-on-error`)
- GitHub Actions workflows in `.github/workflows/`
- Linting must pass: `lint-magic` and `checkbashisms`
- All tests must pass before merge (test-magic run in CI)
- Compilation tested separately (test-doppelganger skipped in regular runs)

---

## Exemptions and Special Cases

### Bootstrap Scripts

- `install`, `spells/install/core/*` cannot use wizardry imps (run before installation)
- Bootstrap scripts must be self-contained with inline helpers
- Bootstrap scripts establish PATH before using commands

### Test Infrastructure

- Test imps in `spells/.imps/test/` require `test-` or `stub-` prefix
- Stub imps may use flags (mimic system command interfaces)
- Stub imps may have functions (for state management and flag parsing)
- Stubs purpose is temporary (improve testability to reduce reliance on stubs)
- test-doppelganger skipped in regular test runs (separate CI workflow, nearly doubles runtime)

### Arcana Scripts

- `.arcana/` scripts allowed to use functions (documented exception)
- Goal: minimize functions in arcana, aim for flat when possible
- Arcana exempt from some standards (bootstrap context)

### Systemd Service Files

- `*.service` files exempt from shell checks (not shell scripts)
- Systemd unit files: `spells/.arcana/bitcoin/bitcoin.service`, `spells/.arcana/tor/tor.service`

### Color Variables

- Color variables in `cantrips/colors` intentionally all-caps
- Matches ANSI standard, improves readability
- Colors meant to be sourced like environment variables

---

## Documentation and Maintenance

### AI-Facing Documentation

- `.github/copilot-instructions.md`: Comprehensive coding standards, templates, workflows
- `.github/FULL_SPEC.md`: This file - canonical specification
- `.github/LESSONS.md`: Lessons learned from debugging (one sentence each)
- `.github/SHELL_CODE_PATTERNS.md`: POSIX shell patterns and quirks
- `.github/CROSS_PLATFORM_PATTERNS.md`: Cross-platform compatibility knowledge
- `.github/EXEMPTIONS.md`: All deviations from standards with justifications
- `spells/.imps/sys/spell-levels` imp: Canonical spell level definitions (code)
- `.github/instructions/*.md`: Topic-specific detailed instructions

### Spell Level System Synchronization

- **CRITICAL**: Four files must be kept in sync when spell levels change: `spells/.imps/sys/spell-levels`, `spells/wards/banish`, `spells/.wizardry/test-magic`, `spells/spellcraft/demo-magic`
- When adding/moving spells between levels in spell-levels, update the corresponding level sections in banish, test-magic, and demo-magic
- When changing level names or numbers in spell-levels, update all three companion files
- All four files use the same level numbering (0-27) and must reference the same spells per level
- spell-levels is the canonical source - the other three files derive their level organization from it

### Documentation Maintenance

- Add new patterns to SHELL_CODE_PATTERNS.md as discovered
- Add new cross-platform quirks to CROSS_PLATFORM_PATTERNS.md as found
- Add lessons to LESSONS.md after every bug fix (one sentence)
- Increment lesson counters for recurring lessons (avoid duplication)
- Update FULL_SPEC.md when features added or changed
- Ask user for clarification when spec vague or contradictory
- Keep FULL_SPEC.md synchronized with LESSONS.md
- Reference FULL_SPEC.md frequently when coding or reviewing

### User-Facing Documentation

- README.md: Project overview, installation, usage, philosophy
- .AGENTS.md: Quick reference for AI agents
- Spell `--help` text: Primary spec for each spell (concrete, not hand-waving)
- Tutorial files in `tutorials/`: Educational examples

---

## Version History

- 1.0.1 (2026-01-10): Removed redundant "Project Values and Philosophy" section (now references README.md as canonical source); clarified documentation hierarchy
- 1.0.0 (2026-01-10): Initial comprehensive specification extracted from all project documentation
