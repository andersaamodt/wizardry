# Wizardry is the terminal's missing link

Wizardry is a collection of shell scripts to complete your terminal experience.
Themed as a magical MUD (Multi-User Dungeon), wizardry turns folders into rooms, and files into items.
Wizardry also includes a comprehensive set of POSIX shell tutorials, and optional free software suite.

## Status for target platforms:

**Current status:** 🟢 `install` and `menu` work well on Debian. Wizardry is brand new, so not all spells have been tested and debugged yet.

| OS                        | Shortname | Status                              |
| ------------------------- | --------- | ----------------------------------- |
| **Debian (and Ubuntu)**   | `debian`  | 🟢 **`install` + `menu` work well**   |
| **NixOS**                 | `nixos`   | 🟢 **`menu` works well**              |
| **MacOS**                 | `macos`   | 🟡 **`install` + `menu` untested**    |
| **Arch**                  | `arch`    | 🟠 **currently unsupported**          |
| **Android (Linux-based)** | —         | 🟠 **currently unsupported**          |
| **Windows**               | —         | ✘ **no support planned (except WSL)** |

## Installation

### Easy install script

Run the following line in a terminal to download and run the wizardry installer script:

```
curl -fsSL https://raw.githubusercontent.com/andersaamodt/wizardry/main/install | sh
```
or:
```
wget -qO- https://raw.githubusercontent.com/andersaamodt/wizardry/main/install | sh
```
The install script requires `tar` plus either `curl` or `wget` to be available.

### Install with git

To download wizardry using git and then install it:

```
git clone http://github.com/andersaamodt/wizardry/main ~/.tower
cd ~/.tower
chmod +x install
./install
```

This downloads wizardry to the default install location, `~/.tower`. After installing, you must reopen your terminal window before wizardry spells will work.

## Usage

To use wizardry, simply type:

```
menu
```
This displays an interactive menu. Most (soon all) wizardry spells and features will be discoverable through the menu.

## Spells

A spell is a specially-curated shell script:

* Lives in the `spells/` folder (or subfolder)
* Does something useful or interesting
* Is clearly-written and well-commented for novices
* Is themed like a fantasy MUD
* Is cross-platform
* Has no `.sh` extension for easy invocation
* Has a brief opening description comment (~2 lines)
* Has a `--help` usage note which ultimately *is* its spec
* Ideally, has a test script at a corresponding path under `tests/`, which serves as a fully-specified operationalized spec
* Is polished and fails elegantly
* Works well when used in a menu (interactively)

This spec helps scripts evolve into living, polished exemplars of communal knowledge about best practices in using and optimizing the shell.

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
| Interface-neutral   | GUIs are thin layers that simply pass commands through to shell scripts. This makes it easy to swap out web platforms or build additional interfaces. |
| Test-driven development | Unit tests are used to specify and test code, with a goal of maintaining 100% unit test coverage. |
| Assumption-checking    | Scripts confirm their assumptions (directories, dependencies, PATH entries) and repair gaps automatically so installations stay reliable. |
| Document-in-place   | Every spell's --help message fully specifies the behavior and usage of that spell; helpful messages and documentation for the user are included portably in scripts and where they are needed in UI. |

### Code Policies

| Principle             | Description |
| --------------------- | ----------- |
| Front-facing  | Every spell is a user-facing executable; no hidden library directories or helper files. |
| Output-first          | Spells communicate by printing results so humans and spells consume the same text; exported environment variables are a fallback for rare cases. |
| Hand-finished AI code | Using AI to generate reusable, well-commented POSIX shell scripts is a great use of AI; scripts should be hand-reviewed and tested. However, wizardry itself will not interface with AI. |
| Menu specialization | Wizardry organizes complex workflows as dedicated menus that call one spell per menu item. |
| Script-like scripts  | Keep scripts script-like: favor flat flows with few functions so behavior stays readable and hackable from the shell. |
| Wizardry available   | Spells can assume other wizardry spells are already in the PATH and should invoke them by name instead of long paths. |

### AI directives
* Preserve the spec: Do not edit the spec comments at the top of script, nor the --help usage instructions of a script, unless specifically instructed.
* Preserve the lore: Do not delete, modify, or add more flavor text unless specifically instructed.
* Qualities of a good script: Brevity, well-commented for novice POSIX shell devs, flat / minimal functions / linear, clarity, portability (including cross-platform), composability, non-redundancy, minimalism.
* No globals: Do not use shell variables unless absolutely necessary (use parameters or stdout instead).
* Bootstrap awareness: The install script runs before wizardry is on PATH, so it alone cannot assume that wizardry spells are already available in PATH.

## Testing

Run the complete shell test suite with:

```
test-magic
```

The spell discovers every `test_*.sh` file in `tests/` and executes each in a sandboxed bubblewrap environment.

Principles of the testing suite:

* Tests are simply POSIX-compliant shell scripts that exercise the expected behaviors of each spell.
* Each spell's `--help` usage note *is* its primary spec; each unit test is considered the full operationalized spec for a spell.
* Test files live in `tests/` and mirror the structure of the `spells/` directory. One test script per spell.
* Tests source `test_common.sh` to standardize testing procedures and logging.
* Each test's subtests should cover all valid and failure modes. Since spells call each other, each spell's test should avoid redundancy with other spells' tests by focusing on unique behaviors.
