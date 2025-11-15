# Wizardry

Wizardry is a collection of Bash and POSIX shell scripts that complete your
terminal experience. It is stewarded as a body of knowledge created by a
community of practice, so the project continuously captures the lessons
required to get real systems working.

## Principles

- **Didacticism:** Scripts are well-commented and written as clearly as
  possible.
- **Bash-first:** To use languages beyond POSIX-compliant Bash there must be a
  good reason. This avoids debates about which other projects should become
  dependencies.
- **Menu-driven:** Wizardry includes a `menu` command that displays an
  interactive interface. A user should be able to manage their entire system by
  typing `menu`, without having to remember or type commands manually.
- **Cross-platform:** Scripts are POSIX-compliant and as cross-platform as
  possible, with explicit documentation for the rare Bash-only exceptions such
  as the interactive `menu` engine.
- **Assumption-checking:** Spells proactively detect missing prerequisites and
  help install the right free software so that users can reach a working state
  on their platform.
- **File-first:** All state is stored in files, ideally human-readable text
  files. Databases that hide data inside opaque blobs are avoided.
- **Minimalism:** The goal is to do as much as possible with the fewest number
  of moving parts.
- **Atomicity:** Each script and part of Wizardry is as small and
  self-contained a unit as possible. These small, reliable parts are then
  combined.
- **Non-commercial:** Wizardry is non-commercial, so we always prefer free
  software over merely open-source software and gravitate toward the least
  commercialised options.
- **Interface-neutral:** GUIs designed with Wizardry are thin layers that pass
  commands through to shell scripts (or other UNIX tools). This makes it easy
  to swap out web platforms or build additional interfaces.
- **Hand-finished AI code:** Using AI to generate reusable, well-commented Bash
  scripts is welcome, but every spell must be hand-reviewed and tested.
  Wizardry itself does not touch or interact with AI services.
- **Test-driven development:** Unit tests specify behaviour and maintain the
  goal of 100% unit-test coverage.
- **Tight integration:** Wizardry provides the glue that integrates other UNIX
  command-line tools together.
- **Grammar:** Wizardry will include a recursive parser that can parse commands
  in a flexible yet deterministic way, effectively extending the Bash
  language.
- **Useful:** Wizardry is use-case driven and developed to support specific,
  common, everyday computer tasks.

## Target platforms

- Standard Linux (e.g., Debian, Ubuntu, Arch)
- macOS
- NixOS
- _Not yet supported:_ Windows, Android

## Testing

Wizardry ships a shell-based test suite in `tests/` that exercises every spell
and verifies coverage.

### Running the suite

Run all checks with:

```sh
./tests/run.sh
```

The script wipes the previous coverage workspace, enumerates all
`test_*.bats` suites, runs them with Bats, and then aggregates the recorded
`bash -x` traces into a coverage report. If any executable lines are missed the
run exits non-zero so coverage regressions are easy to spot. The helper script
`tests/check_posix_bash.sh` also prints advisory warnings about spells whose
shebangs are not plain `#!/bin/sh`.

### Selecting tests

Pass `--list` to print the discovered test files without executing them,
`--only PATTERN` to restrict the run to specific `.bats` files (the pattern is
evaluated relative to `tests/`), `--no-coverage` to skip the coverage report,
or `--` followed by any arguments you want to forward directly to the
underlying Bats runner (for example `./tests/run.sh -- --filter copy`).

### Offline usage and dependencies

The harness downloads bats-core and companion libraries on demand so the shell
tests can use Bats helpers without vendoring the framework. When a local
installation is available you can override the download step with
`BATS_BIN=/path/to/bats` or `BATS_DIR=/path/to/prepared/vendor` (containing the
`bats-core`, `bats-support`, `bats-assert`, and `bats-mock` directories); the
script also falls back to `command -v bats` before attempting to fetch
anything.

### Directory layout

The `tests/` tree keeps reusable helpers out of the way of the individual test
files:

- `tests/run.sh` – entry point that drives the suites, coverage, and warnings.
- `tests/lib/` – shared shell utilities used by the harness (coverage
  processing, stub helpers, Bats bootstrapping, and similar).
- `tests/test_helper/` – loader invoked by each Bats test via
  `load 'test_helper/load'`; it wires up the vendored assertion libraries,
  exports convenience helpers, and sources the scripts in `tests/lib/`.
- `tests/vendor/` – populated on demand with bats-core, bats-support,
  bats-assert, and bats-mock when they are downloaded.
- `tests/report_coverage.sh` – aggregates traces and enforces 100% spell
  coverage.

Individual Bats files continue to live directly under `tests/`, so
contributors can find and run suites without digging into the helper
directories.
