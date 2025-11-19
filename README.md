# Wizardry is the terminal's missing link

Wizardry is a collection of bash scripts to complete your terminal experience.
Themed as a magical MUD (Multi-User Dungeon), wizardry turns folders into rooms, and files into items.
Wizardry also includes a comprehensive set of bash tutorials, and optional free software suite.

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

Run the installer directly with `wget` (or `curl`). The script prompts for the install location and defaults to `~/.tower`, then downloads wizardry into that directory and adds the spells to your `PATH`:

```
wget -qO- https://raw.githubusercontent.com/andersaamodt/wizardry/main/install | sh
```

Set `WIZARDRY_INSTALL_DIR=/path/to/location` (for example `WIZARDRY_INSTALL_DIR="$HOME/wizardry" wget ...`) if you need to run the installer non-interactively or want to change the default in advance. The install script requires `tar` plus either `curl` or `wget` to be available.

### Install with git

To download wizardry using git and then install it:

```
git clone http://github.com/andersaamodt/wizardry/main
chmod +x install
./install
```

After installing, you must reopen your terminal window before wizardry spells will work.

## Usage

To use wizardry, simply type:

```
menu
```
This displays an interactive menu. Most (soon all) wizardry spells and features will be discoverable through the menu.

## Principles:

### Project Values

| Principle     | Description |
| ------------- | ----------- |
| Didacticism   | Scripts are well-commented and written as clearly as possible. |
| Non-commercial | This project is non-commercial, and so we always prefer free software over merely open-source software, and we always prefer the least commercialized software. |
| Useful        | Wizardry is use-case-driven, developed to support specific, common, everyday computer tasks. |
| Bash-first          | To use languages beyond POSIX-compliant bash, there must be a good reason. This skips debates about which other projects to include as dependencies in our project. |
| Menu-driven         | A user should be able to manage their entire system by typing 'menu', without having to remember or type commands. |
| File-first    | All state is stored in files, ideally human-readable text files. No databases, because they enclose data in one opaque file (requiring import/export steps). |
| Cross-platform      | Scripts are POSIX-compliant and as cross-platform as possible. |
| FOSS missing link   | Wizardry provides the glue that integrates other UNIX command-line tools together. |
| Semantic synthesis   | Scripts evolve toward higher-order spellbooks by encapsulating platform details behind concise syntax and deterministic, grammar-like recursive parser. This effectively extends the bash language. |
| Magic theme       | Wizardry themes scripts as spells, and adds fantasy flavor text to the bash user experience. |

### Design Principles

| Principle           | Description |
| ------------------- | ----------- |
| Minimalism          | Do the most with the fewest moving parts. |
| Atomicity           | Each script and part of wizardry is as small and self-contained a unit as possible. These small, reliable parts are then combined. |
| Interface-neutral   | GUIs are thin layers that simply pass commands through to shell scripts. This makes it easy to swap out web platforms or build additional interfaces. |
| Test-driven development | Unit tests are used to specific and test code, with a goal of maintaining 100% unit test coverage. |
| Assumption-checking    | Scripts confirm their assumptions (directories, dependencies, PATH entries) and repair gaps automatically so installations stay reliable. |
| Document-in-place   | Include --help messages on every spell and include helpful messages and documentation for the user portably scripts and where they are needed in UI. |

### Code Policies

| Principle             | Description |
| --------------------- | ----------- |
| Front-facing  | Every spell is a user-facing executable; no hidden library directories or helper files. |
| Output-first          | Spells communicate by printing results so humans and spells consume the same text; exported environment variables are a fallback for rare cases. |
| Hand-finished AI code | Using AI to generate reusable, well-commented bash scripts is a great use of AI; scripts should be hand-reviewed and tested. However, wizardry itself will not interface with AI. |
| Menu specialization | Wizardry organizes complex workflows as dedicated menus that call one spell per menu item. |
| Script-like scripts  | Keep scripts script-like: favor flat flows with few functions so behavior stays readable and hackable from the shell. |

## Unit tests

Run the complete shell test suite with:

```
./tests/run.sh
```

The script discovers every `test_*.bats` file, installs any missing Bats dependencies, and produces a coverage report so regressions fail fast. Pass `--list`, `--only PATTERN`, or `--no-coverage` for quick filtering, and forward additional flags to Bats after `--` when needed.
