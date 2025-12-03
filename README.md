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

## Arcana

An arcana is a grand working, a spell that knows the proper way to install and correctly configure a certain piece of software across all supported platforms.

Wizardry includes a curated free software suite which can be easily and optionally installed from the `menu`.

Criteria for inclusion:

* Software that helps accomplish basic computer tasks (messaging, document editing, photos, sharing, etc.)
* Free software is best; non-commercial open-source an acceptable alternative
* Inclusions are opinionated; the free software suite is our recommendations of the best free software
* No redundant apps; we will choose the best one to include for each purpose, or offer a clear choice if necessary

Using the free software suite makes it easy to establish a standardized software environment across OSes, without having to use a heavier package manager or containerized solution. Wizardry helps you install the right software in the correct way, using built-in package managers on each OS when possible.

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

## Principles:

### Project Values

These values make the wizardry project what it is, and distinguish it from similar projects.

| Principle     | Description |
| ------------- | ----------- |
| Useful        | Wizardry is use-case-driven, developed to support specific, common, everyday computer tasks. |
| Menu-driven         | A user should be able to manage their entire system by typing 'menu', without having to remember or type commands. |
| Teaching community   | Scripts are well-commented and written as clearly as possible. Wizardry is community of practice; scripts codify collective knowledge. |
| Cross-platform      | Scripts are POSIX-compliant and as cross-platform as possible. |
| POSIX sh-first          | To use languages beyond POSIX-compliant shell, there must be a good reason. This skips debates about which other projects to include as dependencies in our project. |
| File-first    | All state is stored in files, ideally human-readable text files. No databases, because they enclose data in one opaque file (requiring import/export steps). |
| Non-commercial | This project is non-commercial, and so we always prefer free software over merely open-source software, and we always prefer the least commercialized software. |
| FOSS missing link   | Wizardry provides the glue that integrates other UNIX command-line tools together. |
| Semantic synthesis   | Scripts evolve toward higher-order spellbooks by encapsulating platform details behind concise syntax and deterministic, grammar-like recursive parser. This effectively extends the POSIX shell language. |
| Fun       | Wizardry themes scripts as spells, and adds optional fantasy flavor text to the shell user experience. |

### Design Principles

| Principle           | Description |
| ------------------- | ----------- |
| Minimalism          | Do the most with the fewest moving parts. |
| Atomicity           | Each script and part of wizardry is as small and self-contained a unit as possible. These small, reliable parts are then combined. |
| Test-driven development | Unit tests are used to specify and test code, with a goal of maintaining 100% unit test coverage. |
| Assumption-checking    | Scripts confirm their assumptions (directories, dependencies, PATH entries) and repair gaps automatically so installations stay reliable. |
| Document-in-place   | Every spell's --help message fully specifies the behavior and usage of that spell; helpful messages and documentation for the user are included portably in scripts and where they are needed in UI. |
| Interface-neutral   | GUIs are thin layers that simply pass commands through to shell scripts. This makes it easy to swap out web platforms or build additional interfaces. |

### Code Policies

| Principle             | Description |
| --------------------- | ----------- |
| Front-facing  | Every spell is a user-facing executable; no hidden library directories or helper files. |
| Output-first          | Spells communicate by printing results so humans and spells consume the same text; exported environment variables are a fallback for rare cases. |
| Hand-finished AI code | Using AI to generate reusable, well-commented POSIX shell scripts is a great use of AI; scripts should be hand-reviewed and tested. However, wizardry itself will not interface with AI. |
| Menu specialization | Wizardry organizes complex workflows as dedicated menus that call one spell per menu item. |
| Menu transparency | Menu item commands should be didactic—clear one-line commands using standard tools, not wizardry scripts, so users learn real shell commands. |
| Script-like scripts  | Keep scripts script-like: favor flat flows with few functions so behavior stays readable and hackable from the shell. |
| Wizardry available   | Spells can assume other wizardry spells are already in the PATH and should invoke them by name instead of long paths. |
| No globals, no wrappers, minimal functions | No global env variables unless absolutely necessary. No wrappers as they break front-facing. Linear flat scripts preferred to functions. |
| Self-healing failures | When a spell encounters a missing prerequisite or failed assumption, it should fix the problem automatically or offer to fix it—never quit with an error that tells the user to fix it themselves. Error messages must not be written in the imperative (e.g., "Please install X" or "Run Y to fix"). |

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
