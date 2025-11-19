# Menu Cross-Platform Readiness Checklist

## Human checklist (rest is by and for AI)
- [ ] Add mud menu and get all items on it working (the mud menu unit test needs to be redone to match)
- [ ] Restore `main-menu`/`mud` integration so menu-forwarding tests pass again
- [ ] Debug install-menu and add nginx or bitcoin to it
- [ ] Add other spells I already have, make POSIX-compliant and tidy up
- [ ] Review all existing spells for bugs and refactor
- [ ] Fix enchant/read-magic family regressions (argument validation, space handling, helper fallbacks, attribute listing)
- [ ] Repair hashchant attr write failures so it stores the hash on POSIX systems
- [ ] Make installation workflow reliable across shells (bashrc/zshrc handling, overwrite prompts)
- [ ] Harden jump-to-marker/mark-location flows (prompting text, absolute path handling, rejecting missing paths)
- [ ] Revisit path-wizard edge cases for non-PATH lines and alternate rc files
- [ ] Test detect-magic, read-magic, enchanting and disenchanting items, hashchant
- [ ] Eventually, add recursive language parser
- [ ] selecting Exit menu item with Enter key should not print "exiting"

## Foundational shell and environment work
- [x] Decide on supported shell(s) (strict POSIX `sh` vs Bash) and document the requirement so that menu dependencies target the same baseline.
- [x] Audit every helper the menu family sources (`colors`, `await-keypress`, `cursor-blink`, `fathom-*`, `move-cursor`, `assertions`) and refactor them to run with the chosen POSIX shell (replace Bash arrays, `${BASH_SOURCE}`, `[[` tests, etc.).
  - [x] `spells/cantrips/colors`: switch shebang to `/bin/sh`, clarify sourcing instructions, and replace the `echo -n` example with a portable `printf` usage.
  - [x] `spells/cantrips/await-keypress`: rewrite the raw keypress loop without Bash `$'\x'` escapes or `read -s -n/-t`, depend on `stty`/`dd` availability checks, and ensure Tab/backspace handling distinguishes keys correctly.
  - [x] `spells/cantrips/cursor-blink`: keep the POSIX shell but change the usage string to `cursor-blink on|off`, add stderr output plus exit codes for misuse, and optionally detect terminals lacking DEC private mode.
  - [x] `spells/cantrips/fathom-cursor`: replace `bash` shebang, `local`, `$'\E[6n'`, and `read -sdR` with portable `printf`/`IFS` parsing, expose failures when the terminal refuses the `DSR` query, and retain the verbose flag semantics.
  - [x] `spells/cantrips/fathom-terminal`: keep the POSIX shell but remove long-option parsing, guard `tput` with assumption checks or fallbacks, and ensure tests reference the portable assertions helper via a relative path.
  - [x] `spells/cantrips/move-cursor`: adopt `/bin/sh`, validate numeric coordinates, restore a trailing newline, and require `printf` support for 1-indexed terminals.
  - [x] `spells/cantrips/assertions`: convert to `/bin/sh`, drop `local`, silence debug `echo` statements, and ensure failures use consistent messaging/exit codes.
  - [x] `spells/menu/install-menu`: replace GNU-specific `find` flags, precompute menu entries without arithmetic relying on Bash `$(( ))` extensions, and surface assumption checks for each optional `*-menu` or `*-status` helper.
- [ ] Replace hard GNU dependencies in these helpers with assumption checks that can install or guide installation of the required utilities across Debian, macOS, and NixOS.
  - [x] `spells/cantrips/await-keypress`: gate `dd`/`stty` usage and support non-interactive devices for tests.
  - [x] `spells/cantrips/fathom-cursor`: gate `dd`/`stty` usage, allow scripted input, and clarify failure messages.
  - [x] `spells/cantrips/fathom-terminal`: require `tput` before querying terminfo values.
  - [x] `spells/menu/install-menu`: drop the `awk` dependency and ensure the `menu` command is checked before use.
- [x] Ensure the helpers fall back gracefully when optional capabilities are missing (e.g., disable colours if the terminal lacks ANSI support).
  - [x] `spells/cantrips/colors`: detect `NO_COLOR`, dumb terminals, or zero-colour terminfo entries and blank out the palette.
  - [x] `spells/cantrips/cursor-blink`: skip emitting control sequences when the terminal lacks cursor controls.
  - [x] `spells/cantrips/move-cursor`: gracefully no-op when cursor positioning is unavailable.

## Installation and discovery
- [ ] Define a standard `--install` contract for spells: document what the flag does, how it edits shell rc files, and how scripts should behave when invoked non-interactively.
- [ ] Refactor the global `install` entry point to call each spell's `--install` handler (or detect capability automatically) while failing gracefully on unsupported platforms.
- [ ] Update the menu scripts and all dependencies to implement the `--install` flag by reusing the shared installer logic instead of mutating dotfiles directly.
- [ ] Detect the user's login shell on each platform (Linux Bash, macOS zsh, NixOS defaults) and update the appropriate rc/profile file without breaking alternative shells.

## Menu spell hardening
- [ ] Document and isolate the Bash requirements in `spells/cantrips/menu` (accepted exception), ensuring its POSIX helpers satisfy the agreed shell baseline before attempting a future rewrite.
- [ ] Replace direct cursor-control calls with portable abstractions or wrap them so that macOS/BSD utilities can provide equivalents (e.g., use `tput` or terminfo queries).
- [ ] Ensure `fathom-terminal`, `fathom-cursor`, and `move-cursor` work on Debian, macOS, and NixOS (fix reliance on GNU `stty`, `tput`, or `/proc`).
- [ ] Validate that the menu keeps the terminal state consistent (restores cursor blink, handles SIGINT/SIGTERM) across shells.
- [ ] Provide a cross-platform OS maintenance menu (e.g., "Update everything") that either wraps distro-native package managers or installs prerequisite tooling per platform.

## Platform verification
- [ ] Run the Bats tests (`tests/test_menu_spells.bats`, `tests/test_cantrips.bats`) on Debian, macOS, and NixOS, fixing any environment-specific failures.
- [ ] Perform manual smoke tests of `menu/main-menu` and `menu/install-menu` on each target platform to confirm interactive behaviour, including arrow navigation and exit paths.
- [ ] Capture regressions or missing capabilities discovered during testing and feed them back into the checklist until all items pass.

## Documentation and follow-up
- [ ] Document the installation story and usage expectations for the menu spells in the repository (README or dedicated docs section).
- [ ] Record any remaining platform-specific limitations (e.g., terminals without ANSI support) and plan follow-up tasks if necessary.
