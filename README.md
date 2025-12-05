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

# **Ethos and Standards**

Wizardry has four layers of guidance that define its purpose, behavior, and conventions.

## **Values**

These values express why the project exists and what principles guide its development.

| Value              | Description                                                                                                      |
| ------------------ | ---------------------------------------------------------------------------------------------------------------- |
| Useful             | Wizardry is use-case-driven, created to support common everyday computer tasks.                                  |
| Menu-driven        | A user should be able to manage their entire system by typing `menu`, without memorizing commands.               |
| Teaching community | Scripts are written as didactic exemplars. Wizardry is a community of practice; code encodes shared knowledge.   |
| Cross-platform     | Wizardry is for UNIX-like systems in general, not a single distro.                                               |
| File-first         | All state is stored in files, ideally human-readable text. No databases that enclose data in opaque blobs.       |
| POSIX sh-first     | POSIX `sh` is the lingua franca. Other languages are only used when there is a strong reason.                    |
| FOSS missing link  | Wizardry supplies the “glue” that integrates standard UNIX tools into coherent workflows.                        |
| Semantic synthesis | Scripts evolve toward higher-order grammars that encapsulate platform details behind concise, composable syntax. |
| Fun                | Magic and MUD flavor text are first-class: they make the terminal more playful without hiding what is going on.  |

## **Policies**

These policies describe Wizardry’s stance toward software freedom, tooling, and the broader ecosystem.

| Policy                | Description                                                                                                                     |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Non-commercial        | Wizardry itself is non-commercial. We prefer free software over merely open-source and choose the least commercialized options. |
| FOSS-first suite      | The bundled software suite is an opinionated selection of free / non-commercial tools for everyday tasks. No redundant apps.    |
| Built-in tools first  | Where possible, arcana use each OS’s built-in package managers rather than heavy external packaging layers.                     |
| Hand-finished AI code | AI may help draft POSIX shell, but final scripts are hand-reviewed, commented, and tested.                                      |
| No AI integration     | Wizardry spells themselves do not call out to AI tools or services.                                                             |

## **Design Tenets**

These tenets define how Wizardry should feel to use and how spells present themselves.

| Tenet               | Description                                                                                                                  |
| ------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| Minimalism          | Do the most with the fewest moving parts.                                                                                    |
| Atomicity           | Spells and imps are small, self-contained units that combine into larger workings.                                           |
| Document-in-place   | Every spell’s `--help` fully specifies its behavior; documentation lives where it is used.                                   |
| Interface-neutral   | GUIs are thin skins over shell scripts. Any interface simply passes commands through to spells.                              |
| Menu specialization | Complex workflows are organized as dedicated menus that call one spell per menu item.                                        |
| Menu transparency   | Menu items show clear, one-line commands using standard tools so users learn real shell syntax.                              |
| Output-first UX     | Humans and spells consume the same text. Output is designed to be readable at the prompt and pipeable into other tools.      |
| Self-healing tone   | When something goes wrong, spells offer to fix it instead of barking orders at the user. Errors are factual, not imperative. |

## **Engineering Standards**

These standards describe the technical requirements that all spells, menus, and supporting scripts must fulfill.

| Standard                        | Description                                                                                               |
| ------------------------------- | --------------------------------------------------------------------------------------------------------- |
| Single-shell stance             | All code runs as POSIX `sh` with `#!/bin/sh` and `set -eu`.                                               |
| POSIX-safe idioms               | Use `$( )` instead of backticks; avoid `which`; prefer `command -v`.                                      |
| Portable pathing                | Use `pwd -P` for resolution; avoid non-portable tools like `realpath`.                                    |
| Platform detection              | Detect kernels with `uname -s`; make PATH setup explicit and portable.                                    |
| Early descriptiveness           | Each executable opens with a 1–2 line comment describing its purpose.                                     |
| Help-on-tap                     | `--help` / `-h` / `--usage` print concrete usage, not hand-waving.                                        |
| Strict-yet-flat flows           | `set -eu`, few functions, linear flow so behavior stays readable and hackable.                            |
| Script-like scripts             | Favor flat, shell-friendly logic over elaborate function trees. No hidden libraries.                      |
| Front-facing spells             | Every spell is a user-facing executable; no private wrapper binaries that hide behavior.                  |
| Spell-by-name invocation        | Spells call other spells by name, assuming wizardry is already on `PATH`.                                 |
| Hyphenated, extensionless names | Executables omit `.sh` and use hyphens for multi-word commands.                                           |
| Careful quoting                 | Quote variables unless word splitting is intentional; use `var=''` for empty vars.                        |
| `printf` over `echo`            | Use `printf '%s\n'` for portability; do not depend on `echo` quirks.                                      |
| Deliberate temp handling        | Create temp files with `mktemp` and clean them up deterministically.                                      |
| Gentle error contract           | Spells try to repair missing prerequisites or offer a fix; they only exit non-zero when real work failed. |
| Error prefixing                 | Error messages go to stderr and are prefixed with the spell name for attribution.                         |
| Unified logging tone            | Logging and prompts follow a consistent style and interruption semantics.                                 |
| Standardized flag parsing       | All spells converge on a single pattern for parsing flags and arguments.                                  |
| Input normalization             | Shared helpers normalize user paths and other inputs.                                                     |
| Linting & formatting            | Default formatting and linting settings for POSIX shell are applied consistently.                         |
| Standard exit codes             | Common helpers define exit codes and error shaping.                                                       |
| Directory-resolution idiom      | One canonical pattern for locating sibling resources.                                                     |
| Validation helpers              | A reusable suite provides common input checks.                                                            |
| Naming scheme                   | A consistent naming scheme governs internal functions and verbs.                                         |

## Testing

Run the complete shell test suite with:

```
test-magic
```

The spell discovers every `test_*.sh` file in `.tests/` and executes each in a sandboxed bubblewrap environment.

Principles of the testing suite:

| Testing Rule          | Description |
| --------------------- | ----------- |
| Tests are the spec    | Each spell’s behavior is fully specified by its `test_*.sh` counterpart. |
| Tests are POSIX shell | Tests are simply POSIX-compliant shell scripts that exercise expected behaviors. |
| Help-as-spec          | Each spell's `--help` usage note is its primary spec; each unit test is the operationalized spec. |
| Mirrored tree         | `.tests/` mirrors `spells/` structurally: one test script per spell. |
| Tests use imps        | Test helpers are imps in `spells/.imps/test/`; there is no shared `test_common` file. |
| No exemptions         | There are no exceptions to any testing requirements under any circumstances. |
| Unique behavior focus | Each test covers that spell’s unique behaviors and failure modes, avoiding redundant coverage. |
| Full mode coverage    | Subtests cover all valid paths and error conditions. |
| Explicit shims        | Shims exist only within tests; each test that needs one creates and manages it explicitly. |
| Sandboxed execution   | The `test-magic` spell discovers and runs all tests in an isolated bubblewrap environment. |
| Tests required | All tests are required to pass before new code may be merged. |
