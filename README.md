# Wizardry is a collection of bash scripts to complete your terminal experience.

**Current status:** `install` and `menu` work well on Debian. Wizardry is brand new, so not all spells have been tested and debugged yet.

## Principles:

* **Didacticism:** Scripts are well-commented and written as clearly as possible.

* **Bash-first:** To use languages beyond POSIX-compliant bash, there must be a good reason. This skips debates about which other projects to include as dependencies in our project.

* **Menu-driven:** Wizardry includes a 'menu' command that displays an interactive menu. A user should be able to manage their entire system by typing 'menu', without having to remember or type commands.

* **Cross-platform:** Scripts are POSIX-compliant and as cross-platform as possible.

* **File-first:** All state is stored in files, ideally human-readable text files. No databases, because they enclose data in one opaque file (requiring import/export steps).

* **Minimalism:** The goal is to do as much as possible with the fewest number of moving parts.

* **Atomicity:** Each script and part of wizardry is as small and self-contained a unit as possible. These small, reliable parts are then combined.

* **Non-commercial:** This project is non-commercial, and so we always prefer free software over merely open-source software, and we always prefer the least commercialized software.

* **Interface-neutral:** GUIs designed with wizardry are merely thin layers that pass commands through to shell scripts (or other UNIX tools). This makes it easy to swap out web platforms or build additional interfaces.

* **Hand-finished AI code:** Using AI to generate reusable, well-commented bash scripts is a great use of AI; scripts should be hand-reviewed and tested. However, wizardry itself will not touch or interact with AI.

* **Test-driven development:** Unit tests are used to specific and test code, with a goal of maintaining 100% unit test coverage.

* **Tight integration:** The goal of wizardry is to provide the glue that integrates other UNIX command-line tools together.

* **Grammar:** Wizardry will include a recursive parser that can parse commands in a flexible yet deterministic way. This effectively extends the bash language.

* **Useful:** Wizardry is use-case-driven, developed to support specific, common, everyday computer tasks.

## Target platforms:

| OS                        | Shortname | Status                              |
| ------------------------- | --------- | ----------------------------------- |
| **Debian (and Ubuntu)**   | `debian`  | 🟢 **`install` + `menu` work well** |
| **NixOS**                 | `nixos`   | 🟢 **`menu` works well**            |
| **MacOS**                 | `macos`   | 🟡 **support planned**              |
| **Arch**                  | `arch`    | 🟠 **support planned later**        |
| **Android (Linux-based)** | —         | ✘ **no support planned**            |
| **Windows**               | —         | ✘ **no support planned**            |

## Testing

Wizardry ships a shell-based test suite in `tests/` that exercises every spell and verifies coverage.

### Running the suite

Run all checks with:

```
./tests/run.sh
```

The script wipes the previous coverage workspace, enumerates all `test_*.bats` suites, runs them with Bats, and then aggregates the recorded `bash -x` traces into a coverage report. If any executable lines are missed the run exits non-zero so coverage regressions are easy to spot. The helper script `tests/check_posix_bash.sh` also prints advisory warnings about spells whose shebangs are not plain `#!/bin/sh`.

### Selecting tests

Pass `--list` to print the discovered test files without executing them, `--only PATTERN` to restrict the run to specific `.bats` files (the pattern is evaluated relative to `tests/`), `--no-coverage` to skip the coverage report, or `--` followed by any arguments you want to forward directly to the underlying Bats runner (for example `./tests/run.sh -- --filter copy`).

### Offline usage and dependencies

The harness downloads bats-core and companion libraries on demand so the shell tests can use Bats helpers without vendoring the framework. When a local installation is available you can override the download step with `BATS_BIN=/path/to/bats` or `BATS_DIR=/path/to/prepared/vendor` (containing the `bats-core`, `bats-support`, `bats-assert`, and `bats-mock` directories); the script also falls back to `command -v bats` before attempting to fetch anything.

### Directory layout

The `tests/` tree keeps reusable helpers out of the way of the individual test files:

* `tests/run.sh` – entry point that drives the suites, coverage, and warnings.
* `tests/lib/` – shared shell utilities used by the harness (coverage processing, stub helpers, Bats bootstrapping, and similar).
* `tests/test_helper/` – loader invoked by each Bats test via `load 'test_helper/load'`; it wires up the vendored assertion libraries, exports convenience helpers, and sources the scripts in `tests/lib/`.
* `tests/vendor/` – populated on demand with bats-core, bats-support, bats-assert, and bats-mock when they are downloaded.
* `tests/report_coverage.sh` – aggregates traces and enforces 100% spell coverage.

Individual Bats files continue to live directly under `tests/`, so contributors can find and run suites without digging into the helper directories.
