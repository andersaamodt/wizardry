# Wizardry is the terminal's missing link

Wizardry is a collection of shell scripts to complete your terminal experience.
Themed as a magical MUD (Multi-User Dungeon), wizardry turns folders into rooms, and files into items.
Wizardry also includes a comprehensive set of POSIX shell tutorials, and optional free software suite.

## Status for target platforms:

**Current status:** 🟢 `install` and `menu` work well on Debian. Wizardry is brand new, so not all spells have been tested and debugged yet.

| OS                        | Shortname | Status                              |
| ------------------------- | --------- | ----------------------------------- |
| **Debian (and Ubuntu)**   | `debian`  | 🟢 **`install` + `menu` work well**   |
| **NixOS**                 | `nixos`   | 🟢 **`install` + `menu` work well**   |
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
git clone http://github.com/andersaamodt/wizardry/main ~/.wizardry
cd ~/.wizardry
chmod +x install
./install
```

This downloads wizardry to the default install location, `~/.wizardry`. After installing, you must reopen your terminal window before wizardry spells will work.

### NixOS Installation

On NixOS, the installer modifies `~/.config/nixpkgs/configuration.nix` (for home-manager users) to add wizardry paths. **The installer will ask for your permission before making any changes** and will automatically create a timestamped backup of your configuration file.

If you use system-level configuration (`/etc/nixos/configuration.nix`), you'll need to manually add wizardry to your PATH in that file instead.

After installation completes, run:
```bash
home-manager switch     # If using home-manager with ~/.config/nixpkgs/configuration.nix
```

The backup file is saved as `configuration.nix.wizardry.TIMESTAMP` in the same directory, allowing you to restore your previous configuration if needed.

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

## Spellbook

The Spellbook is your personal grimoire for managing and organizing spells. Access it by typing `spellbook` or selecting it from the main menu.

### Features

* **Browse spells by category**: Explore spells organized into magical categories
* **Save custom commands**: Create and save your own shell commands for quick access
* **Memorize spells**: Add frequently-used spells to your Cast menu for instant casting
* **Delete custom commands**: Remove commands you no longer need

### Spell Categories

Wizardry organizes spells into the following magical categories:

* **arcane**: Advanced magical operations and meta-commands
* **cantrips**: Simple, frequently-used utility spells
* **contacts**: Manage your address book and contacts
* **divination**: Detect and discover information about your system
* **enchant**: Transform and manipulate data formats
* **install**: Install and manage software packages
* **kryptos**: Cryptographic operations and secure hashing
* **mud**: Multi-User Dungeon interface and commands
* **spellcraft**: Tools for creating and managing your own spells
* **system**: System management and maintenance tasks
* **translocation**: Navigate directories and manage bookmarks
* **war**: Process management and system monitoring
* **wards**: Security and protection spells

When you select a spell from the Spellbook, you can cast it immediately, memorize it for the Cast menu, view its help documentation, or test it. Custom commands can also be deleted from the spell action menu.

## Imps

Imps (infraspells/microscripts) are the smallest semantic building blocks in wizardry. They live in `spells/.imps/` and abstract common shell patterns into readable, well-documented microscripts with short semantic names.

### What are Imps?

An **imp** is a microscript that:

* Does exactly one thing
* Has an aptly-chosen, semantic name that reads naturally in code
* Uses space-separated arguments instead of `--flags`
* Has no `--help` flag (just a comment header—imps are for coding, not running standalone)
* Is cross-platform, abstracting OS differences behind a clean interface
* Makes spells read almost like English while remaining POSIX-compliant

### Imps vs Cantrips

| Aspect | Cantrips | Imps |
|--------|----------|------|
| **Use case** | User-facing utilities | Building blocks for scripts |
| **Invocation** | Command line or scripts | Primarily within scripts |
| **Arguments** | `--flag` style with `--help` | Space-separated, positional |
| **Standalone use** | Common | Rare (words in a script) |
| **Examples** | `ask_yn`, `say`, `menu` | `is`, `on`, `has`, `ok` |

### Why Imps?

1. **Readability**: Spells become English-like while remaining POSIX-compliant
2. **Cross-platform**: Platform differences hidden behind semantic names
3. **Teaching**: Each imp is a paragon of good shell style
4. **Correctness**: Battle-tested implementations avoid common shell pitfalls

### Imp Design Principles

* **Apt naming**: Names should be the most natural word for what the imp does
* **Read like English**: `if on mac && has brew; then` reads naturally
* **Cross-platform**: Abstract away OS detection, package managers, path differences
* **Minimal**: No `--help`, no argument parsing complexity—just a comment and code
* **Single-purpose**: One imp, one job

### Example Usage

Without imps:
```sh
if [ -d "$path" ] && [ -n "$(ls -A "$path" 2>/dev/null)" ]; then
    # directory exists and is not empty
fi

case "$(uname -s)" in
Darwin) brew install git ;;
Linux) apt-get install git ;;
esac
```

With imps:
```sh
if is dir "$path" && nonempty dir "$path"; then
    # directory exists and is not empty
fi

on mac && brew install git
on debian && apt-get install git
```

### Available Imps

**Existence & Type Testing**
* **is** `TYPE PATH` - test if path meets condition (file/dir/link/exec/readable/writable/empty/set/unset)
* **exists** `PATH` - test if path exists (any type)
* **missing** `PATH` - test if path does NOT exist
* **nonempty** `TYPE PATH` - test if file has content or dir has entries

**Command Availability**
* **has** `CMD` - test if command exists on PATH
* **lacks** `CMD` - test if command is NOT available
* **need** `CMD [MSG]` - exit with error if command not found
* **any** `CMD...` - return first available command from list

**Platform Detection**
* **on** `PLATFORM` - test if running on platform (mac/linux/debian/nixos/arch/fedora/bsd)
* **os** - print current OS identifier

**Data Flow**
* **first** `[FILE]` - return first line of input or file
* **lines** `[FILE]` - count lines
* **trim** - remove leading/trailing whitespace
* **lower** - convert to lowercase
* **each** `CMD...` - run command for each line of stdin

**Control Flow**
* **ok** `CMD...` - run command silently, succeed if it succeeds
* **fail** `MSG` - print to stderr and exit with failure
* **either** `A B` - output first non-empty value
* **otherwise** `DEFAULT` - output stdin if non-empty, else default

## Free software suite

Wizardry includes a curated free software suite which can be easily and optionally installed from the `menu`. Criteria for inclusion:

* Software that helps accomplish basic computer tasks (messaging, document editing, photos, sharing, etc.)
* Free software is best; non-commercial open-source an acceptable alternative
* Inclusions are opinilnsted; the free software suite is our recommendations of the best free software
* No redundant apps; we will choose the best one to include for each purpose, or offer a clear choice if necessary

Using the free software suite makes it easy to establish a standardized software environment across OSes, without having to use a heavier package manager or containerized solution. Wizardry helps you install the right software in the correct way, using built-in package managers on each OS when possible.

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
* No wrappers; all files are standalone, portable, and front-facing.
* Bootstrap awareness: The install script (`./install`) and core install scripts (in `spells/install/core`) run before wizardry is on PATH, so they alone cannot assume that wizardry spells are already available in PATH.
* Expose and use new documented (in `--help usage note`) arguments to pass data to scripts, instead of passing in shell variables.

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
* Shims exist only within tests; whenever a test needs a shim, that test script must create and manage it explicitly.
