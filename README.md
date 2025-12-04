# Wizardry is the terminal's missing link

Wizardry is a collection of shell scripts to complete your terminal experience.
Themed as a magical MUD (Multi-User Dungeon), wizardry turns folders into rooms, and files into items.
Wizardry also includes a comprehensive set of POSIX shell tutorials, and optional free software suite.

Wizardry includes a set of interactive menus that transparently show what command each menu item will call, making discovering and using the command line much easier. Wizardry assembles cross-platform UNIX knowledge into usable menus and memorable commands.

The language of magic—a human heirloom—is rich in evocative words for hidden forces and abstract transformations, making it a natural fit for extending the terminal's vocabulary, binding the worlds of thought and myth together as effective language.

## Status for target platforms:

**Current status:** 🟢 `install` and `menu` work well on Debian. Wizardry is brand new, so not all spells have been tested and debugged yet.

| OS                        | Shortname | Status                              |
| ------------------------- | --------- | ----------------------------------- |
| **Debian (and Ubuntu)**   | `debian`  | 🟢 **`install` + `menu` work well**   |
| **NixOS**                 | `nixos`   | 🟢 **`install` + `menu` work well**   |
| **MacOS**                 | `macos`   | 🟡 **`install` + `menu` untested**    |
| **Arch**                  | `arch`    | 🟠 **untested**          |
| **Android (Linux-based)** | —         | 🟠 **currently unsupported**          |
| **Windows**               | —         | ✘ **no support planned (except WSL)** |

## Installation

### Easy install script

Run the following line in a terminal to download and run the wizardry installer script:

```
curl -fsSL https://raw.githubusercontent.com/andersaamodt/wizardry/main/install | sh
```
The install script requires `tar` plus either `curl` or `wget` to be available.

### Install with git

To download wizardry using git and then install it:

```
git clone https://github.com/andersaamodt/wizardry ~/.wizardry
cd ~/.wizardry
./install
```

This downloads wizardry to the default install location, `~/.wizardry`. After installing, you must reopen your terminal window before wizardry spells will work.

## Usage

To use wizardry, simply type:

```
menu
```
This displays an interactive menu. Most (soon all) wizardry spells and features will be discoverable through the menu.

## Spells

A spell is a specially-curated shell script:

* Lives in the `spells/` folder (or subfolder)
* Has a unique name (all spells are in PATH together)
* Does something useful or interesting
* Is clearly-written and well-commented for novices
* Is themed like a fantasy MUD
* Is cross-platform
* Has no `.sh` extension for easy invocation
* Has a brief opening description comment (~2 lines)
* Has a `--help` usage note which ultimately *is* its spec
* Has a test script at a corresponding path under `.tests/`, which serves as a fully-specified operationalized spec
* Is polished and fails elegantly
* Works well when used in a menu (interactively)

This spec helps scripts evolve into living, polished exemplars of communal knowledge about best practices in using and optimizing the shell.

### Spellbook

The Spellbook is your personal grimoire for casting and organizing spells. Access it by typing `spellbook` or selecting it from the main menu.

Spell categories:

* custom commands
* arcane
* cantrips
* crypto
* divination
* enchantment  
* mud
* psi
* spellcraft
* translocation
* war
* wards

### Imps

Imps are the smallest semantic building blocks in wizardry. They live in `spells/.imps/` and abstract common shell patterns into readable, well-documented microscripts.

An **imp** is a microscript that:

* Does exactly one thing
* Does not contain functions
* Has a self-documenting name that novices can understand without looking it up (use hyphens for multi-word names)
* Uses space-separated arguments instead of `--flags`
* Has no `--help` flag (just a comment header—imps are for coding, not running standalone)
* Is cross-platform, abstracting OS differences behind a clean interface
* Makes spells read almost like English while remaining POSIX-compliant

Push as much logic as possible into imps for maximum semanticization.

## Arcana

An arcana is a grand working, a spell that knows the proper way to install and correctly configure a certain piece of software across all supported platforms.

Wizardry includes a curated free software suite which can be easily and optionally installed from the `menu`.

Criteria for inclusion:

* Software that helps accomplish basic computer tasks (messaging, document editing, photos, sharing, etc.)
* Free software is best; non-commercial open-source an acceptable alternative
* Inclusions are opinionated; the free software suite is our recommendations of the best free software
* No redundant apps; we will choose the best one to include for each purpose, or offer a clear choice if necessary

Using the free software suite makes it easy to establish a standardized software environment across OSes, without having to use a heavier package manager or containerized solution. Wizardry helps you install the right software in the correct way, using built-in package managers on each OS when possible.

## Magical Glossary

| Term | Definition |
| ---- | ---------- |
| **arcanum** (pl. **arcana**) | A grand working—a spell that installs and configures software across supported platforms, presented as a menu of functions. Also refers to the apps themselves. |
| **bootstrap spell** | A spell that can run before wizardry is fully installed. These self-contained scripts (namely `install` and spells in `spells/install/core/`) don't rely on other wizardry spells. |
| **cantrip** | A small utility spell for common tasks. |
| `cast` | To execute a spell. Memorized spells appear in the `cast` menu for quick access. |
| **crypto** | Cryptographic spells for hashing and security. |
| **daemon** | A background process that runs continuously, typically started at system boot. |
| **demon family** | A subfolder within `spells/.imps/` that groups related imps by function. Each folder represents a family of imps that share a common purpose (e.g., `str/` for string operations, `fs/` for filesystem operations). |
| **divination** | Spells that detect or discover information. |
| **enchant** / **enchantment** | Spells that add or manipulate extended attributes (metadata) on files. |
| `forget` | Remove a spell from your memorized (`cast`) list. |
| **imp** | The smallest building block of magic—a microscript that does exactly one thing. Imps dwell in `spells/.imps/`. |
| `learn` | Add a spell to your shell environment, making it permanently available. Some spells must be learned before use. |
| `memorize` | Add a spell to your `cast` menu for quick access. |
| **portal** | A persistent connection between two computers via SSH, created with `open-portal`, for MUD travel. |
| **portkey** | A bookmark to a remote location. Use `enchant-portkey` to create one and `follow-portkey` to teleport there. (Future: If you have the `touch` hook installed, touching a portkey will also activate it.) |
| **scribe** | Create a new custom spell. |
| **spell** | A specially-curated shell script that lives in `spells/`, has a unique name, and follows wizardry conventions. |
| `spellbook` | Your personal grimoire for organizing and casting spells. Access it with `spellbook` or from the main `menu`. Also refers to custom spell folders. |
| **spellcraft** | The writing of shell scripts. |
| **tome** | A text file containing the contents of several other text files concatenated together, so a whole folder of spells can be sent or carried easily. |
| **ward** | A protective spell for security or access control. |

## **Ethos & Standards**

Wizardry’s conceptual architecture is organized into four layers that together define its purpose, behavior, and expectations.

### **1. Core Values**

These values describe the foundational intentions and philosophical commitments of the project.

| Value              | Description                                                                              |
| ------------------ | ---------------------------------------------------------------------------------------- |
| Useful             | Built around concrete, everyday computing tasks.                                         |
| Menu-driven        | A user should control the whole system by typing `menu`.                                 |
| Teaching community | Wizardry is a didactic commons; scripts codify shared knowledge.                         |
| Cross-platform     | Portable across UNIX-like systems; no distro parochialism.                               |
| POSIX sh-first     | POSIX `sh` is the lingua franca; other languages require strong justification.           |
| File-first         | All state lives in ordinary files; no opaque databases.                                  |
| Non-commercial     | Prefers free software and least-commercial options.                                      |
| FOSS missing link  | Wizardry supplies integrative glue among standard UNIX tools.                            |
| Semantic synthesis | Scripts evolve toward higher-order grammars and clean abstraction of platform detail.    |
| Fun                | Magic, MUD vocabulary, and flavor text enliven the terminal without obscuring mechanics. |

### **2. Policies**

These policies outline Wizardry’s broader ecosystem commitments and governance stance.

| Policy                         | Description                                                                              |
| ------------------------------ | ---------------------------------------------------------------------------------------- |
| Non-commercial stance          | Wizardry itself is non-commercial; selects the least commercial free tools.              |
| FOSS-first selection           | The bundled software suite is an opinionated FOSS-forward curation with no redundancies. |
| Built-in package managers      | Arcana prefer native OS package managers over heavy external systems.                    |
| Hand-finished AI contributions | AI may draft POSIX shell, but all code is manually reviewed, annotated, and tested.      |
| No AI integration              | Wizardry never invokes AI tools at runtime.                                              |

### **3. Design Tenets**

These tenets articulate how Wizardry should behave and present itself at the user level.

| Tenet               | Description                                                                             |
| ------------------- | --------------------------------------------------------------------------------------- |
| Minimalism          | Few moving parts; elegant reduction.                                                    |
| Atomicity           | Spells and imps are small, composable units.                                            |
| Document-in-place   | `--help` serves as each spell’s living spec.                                            |
| Interface-neutral   | GUIs are transparent skins; shell remains the ground truth.                             |
| Menu specialization | Complex workflows appear as dedicated menus invoking single spells.                     |
| Menu transparency   | Menus show real one-line commands using standard tools, teaching natural shell.         |
| Output-first        | Scripts communicate primarily via printed output readable by humans *and* other spells. |
| Self-healing tone   | Scripts repair missing prerequisites or offer fixes without imperative commands.       |

### **4. Engineering Standards**

These standards define the required behaviors and constraints for all spells, imps, and supporting code.

| Standard                           | Description                                                                             |
| ---------------------------------- | --------------------------------------------------------------------------------------- |
| POSIX shell stance                 | All code is POSIX `sh` with `#!/bin/sh` and `set -eu`.                                  |
| POSIX-safe idioms                  | Prefer `$( )`, avoid backticks, avoid `which`, use `command -v`.                        |
| Portable pathing                   | Use `pwd -P`; avoid non-portable tools like `realpath`.                                 |
| Platform detection                 | Detect kernel via `uname -s`; explicit PATH setup in bootstrap scripts.                 |
| Hyphenated, extensionless commands | Spells and imps omit `.sh` and use hyphens for clarity and shell-friendliness.          |
| Early descriptiveness              | Each executable opens with a concise purpose comment (1–2 lines).                       |
| Help-on-tap                        | `--help`/`-h`/`--usage` provide concrete, exhaustive usage.                             |
| Flat, strict flows                 | Use `set -eu`; minimal functions; behavior stays hackable and visible.                  |
| Script-like scripts                | Favor linear, readable shells over function forests; no hidden library directories.     |
| Front-facing executables           | Everything end-user relevant is a standalone executable; no private wrappers.           |
| Spell-by-name invocation           | Spells call other spells by name, assuming wizardry is on PATH.                         |
| Careful quoting                    | Always quote variables unless intentional splitting; empty values use `var=''`.         |
| `printf` over `echo`               | Use `printf '%s\n'` for portable, predictable output.                                   |
| Deliberate temp handling           | Create temps via `mktemp` and clean methodically.                                       |
| Error prefixing                    | Errors go to stderr with clear spell-name prefix.                                       |
| Gentle error contract              | Scripts attempt repair or offer repair paths; non-zero exit means genuine failure.      |
| Unified logging tone               | Logging and interruption semantics are consistent across spells.                        |
| Standardized flag parsing          | All spells converge on a single argument/flag parsing pattern.                          |
| Input normalization                | Shared helpers normalize paths and other user inputs.                                   |
| Linting & formatting baseline      | Shared POSIX shell formatting rules enforced project-wide.                              |
| Standard exit codes                | Common helpers define exit codes and error shaping.                                     |
| Directory-resolution idiom         | One canonical pattern for locating sibling resources.                                   |
| Validation helpers                 | Shared suite for validating arguments, environment, and paths.                          |
| Naming scheme                      | Unified conventions for verbs, internal functions, and spell intent.                    |
| `vet-spell` parity                 | `vet-spell --strict` gradually applies to all spells, ensuring cross-platform fidelity. |

### **5. Testing Standards**

These engineering standards describe how Wizardry’s behavior is validated and enforced.

| Testing Rule          | Description                                                                |
| --------------------- | -------------------------------------------------------------------------- |
| Tests are the spec    | Each spell’s behavior is fully specified by its `.tests/` counterpart.     |
| Mirrored tree         | Every spell has a corresponding `test_*.sh` in the same relative location. |
| Shared test harness   | Tests source `test_common.sh` for logging and helpers.                     |
| Unique behavior focus | Tests concentrate on a spell’s own semantics, not redundant coverage.      |
| Full mode coverage    | Subtests cover valid paths and failure modes.                              |
| No implicit shims     | Any shim used in testing is declared within that test.                     |
| Sandboxed execution   | `test-magic` runs all tests inside a bubblewrap environment.               |

## Testing

Run the complete shell test suite with:

```
test-magic
```

The spell discovers every `test_*.sh` file in `.tests/` and executes each in a sandboxed bubblewrap environment.

Principles of the testing suite:

* Tests are simply POSIX-compliant shell scripts that exercise the expected behaviors of each spell.
* Each spell's `--help` usage note *is* its primary spec; each unit test is considered the full operationalized spec for a spell.
* Test files live in `.tests/` and mirror the structure of the `spells/` directory. One test script per spell.
* Tests source `test_common.sh` to standardize testing procedures and logging.
* Each test's subtests should cover all valid and failure modes. Since spells call each other, each spell's test should avoid redundancy with other spells' tests by focusing on unique behaviors.
* Shims exist only within tests; whenever a test needs a shim, that test script must create and manage it explicitly.
