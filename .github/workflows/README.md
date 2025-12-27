# GitHub Actions Workflows

This directory contains GitHub Actions workflows for testing and building wizardry.

## Error Consolidation

All workflows now include error reporting that creates artifacts when failures occur. The `consolidate-errors.yml` workflow automatically collects these error reports into a single consolidated report.

### How Error Consolidation Works

1. **Error Artifacts**: When any workflow fails, it creates an error artifact containing:
   - Job name and platform information
   - Failure details and error messages
   - Links to the workflow run for detailed logs

2. **Automatic Consolidation**: The `consolidate-errors.yml` workflow automatically triggers when any monitored workflow completes with a failure status.

3. **Consolidated Report**: Downloads all error artifacts and creates a single `consolidated-workflow-errors` artifact containing:
   - Summary of the failed workflow
   - All error details from individual jobs
   - Links to the original workflow run
   - Downloadable artifact for offline review

4. **Job Summary**: The consolidation workflow also creates a GitHub Actions job summary with the consolidated error report for quick viewing.

### Monitored Workflows

The following workflows are monitored for errors:
- Unit tests (all platforms: Nix, macOS, Arch, Debian, Ubuntu)
- POSIX, linting, and style checks
- Compile wizardry
- Test standalone compiled spells
- Test doppelganger compiled wizardry
- Demonstrate wizardry

### Accessing Error Reports

**To view consolidated errors:**
1. Go to the Actions tab
2. Find the "Consolidate workflow errors" run for your failed workflow
3. View the job summary for inline error details
4. Download the `consolidated-workflow-errors-*` artifact for the complete report

**To view individual workflow errors:**
1. Go to the Actions tab
2. Find the failed workflow run
3. Download the error artifact (e.g., `nix-errors`, `macos-errors`, `lint-errors`)

**Artifact Retention**: Error artifacts are retained for 30 days.

## Workflows

### consolidate-errors.yml

**Purpose**: Consolidates error reports from all workflows into a single unified report.

**Triggers**:
- Automatically runs when any monitored workflow completes with failure status
- Uses `workflow_run` trigger to detect workflow completions

**Features**:
- Downloads all error artifacts from the failed workflow run
- Creates a consolidated error report with:
  - Workflow name, conclusion, and run details
  - All error messages from individual jobs
  - Links to the original workflow run
  - Timestamp and event information
- Uploads consolidated report as an artifact (`consolidated-workflow-errors-*`)
- Creates GitHub Actions job summary for quick viewing
- Only runs when workflows fail (skips successful runs)

**Error Artifact Pattern**: Looks for artifacts matching `*-errors` pattern from:
- `nix-errors` - Nix platform test failures
- `macos-errors` - macOS platform test failures
- `arch-errors` - Arch Linux test failures
- `debian-errors` - Debian test failures
- `ubuntu-errors` - Ubuntu test failures
- `lint-errors` - Linting and POSIX check failures
- `compile-errors` - Compilation failures
- `standalone-errors` - Standalone spell test failures
- `doppelganger-errors` - Doppelganger test failures
- `demonstrate-errors` - Demonstrate wizardry test failures

**Retention**: Consolidated error artifacts are kept for 30 days.

### compile.yml

**Purpose**: Creates a compiled, standalone version of wizardry as an artifact.

**Triggers**:
- Push to main branch
- Pull requests
- Manual workflow dispatch

**Features**:
- Creates a doppelganger (compiled version) with all spells compiled to standalone executables
- Removes test files, SKIP-IF-COMPILED documentation, and development-only files
- Excludes `.tests/`, `SKIP-IF-COMPILED-*.md` files for a clean distribution
- Includes precompiled `spells/` directory (this is the source code for an open-source project)
- Uploads artifact directly (GitHub Actions automatically zips it)
- Uploads artifact with 90-day retention
- Automatically cleans up old artifacts, keeping only the 3 most recent
- **Error Reporting**: Creates `compile-errors` artifact if compilation fails

**Artifact Cleanup**:
The cleanup step:
- Uses GitHub Actions API to list all artifacts
- Handles pagination to fetch all artifacts (100 per page)
- Filters for `wizardry-compiled-*` artifacts
- Sorts by creation date and keeps only the N most recent (default: 3)
- Deletes older artifacts to save storage space
- Only runs on push events (not pull requests)

**Usage**:
To download the latest compiled wizardry:
1. Go to Actions → Compile wizardry → Latest successful run
2. Download the `wizardry-compiled-*` artifact
3. Extract and use the compiled version

### test-doppelganger.yml

**Purpose**: Tests the doppelganger (compiled wizardry) to ensure compiled spells work standalone.

**Features**:
- Creates a doppelganger in `/tmp/wizardry-doppelganger`
- Tests all compiled spells in isolation with minimal PATH
- Runs behavioral tests against compiled spells
- Also creates and uploads a doppelganger ZIP artifact
- Includes artifact cleanup (keeps last 3)
- **Error Reporting**: Creates `doppelganger-errors` artifact listing failed spells

### test-standalone-spells.yml

**Purpose**: Tests that individual spells compile and run standalone.

**Features**:
- Compiles all spells individually
- Tests each compiled spell in isolation with `env -i PATH="/usr/bin:/bin"`
- Runs behavioral tests on compiled spells
- Reports success rate and failures
- **Error Reporting**: Creates `standalone-errors` artifact with detailed failure information including failed spell names

### tests.yml

**Purpose**: Main test suite for wizardry spells.

**Features**:
- Runs all tests in `.tests/` directory across multiple platforms:
  - Nix (NixOS environment)
  - macOS (macos-latest)
  - Arch Linux (archlinux:latest container)
  - Debian (debian:stable-slim container)
  - Ubuntu (ubuntu-latest)
- Tests spells in the full wizardry environment
- Primary validation for spell functionality
- **Error Reporting**: Creates platform-specific error artifacts on failure (`nix-errors`, `macos-errors`, etc.)

### lint-posix.yml

**Purpose**: Validates POSIX shell compliance, linting, and code style.

**Features**:
- Runs `lint-magic` on all spells
- Checks for POSIX compliance with `checkbashisms`
- Validates spell formatting and style
- Ensures portability across different shells
- **Error Reporting**: Creates `lint-errors` artifact if any checks fail

### demonstrate-wizardry.yml

**Purpose**: Tests the demonstrate-wizardry tutorial functionality.

**Features**:
- Runs the demonstrate-wizardry test suite
- Validates the tutorial experience
- Ensures wizardry can be properly demonstrated to new users
- **Error Reporting**: Creates `demonstrate-errors` artifact on test failure

## Artifact Management

Both `compile.yml` and `test-doppelganger.yml` include artifact cleanup to manage storage:

**How it works**:
1. After successful artifact upload, the cleanup step runs
2. Fetches all artifacts using pagination (to handle repos with many artifacts)
3. Filters for artifacts matching the workflow's pattern
4. Sorts by creation date (newest first)
5. Keeps the N most recent artifacts (configurable, default: 3)
6. Deletes older artifacts via GitHub Actions API

**Why keep multiple artifacts**:
- Allows comparing recent builds
- Provides rollback options if latest build has issues
- Balances storage usage with availability

**Modifying retention count**:
Edit the `keepCount` variable in the cleanup step:
```javascript
const keepCount = 3;  // Change to desired number
```

## Running Workflows Manually

Most workflows can be triggered manually using workflow_dispatch:
1. Go to Actions tab
2. Select the workflow
3. Click "Run workflow"
4. Choose branch and run

## Permissions

Workflows require specific permissions:
- `contents: read` - Read repository contents
- `actions: write` - Required for artifact cleanup (delete artifacts)

## See Also

- [COMPILED-TESTING.md](../COMPILED-TESTING.md) - How compiled spell testing works
- [doppelganger spell](../../spells/spellcraft/doppelganger) - Creates compiled versions
- [compile-spell spell](../../spells/spellcraft/compile-spell) - Compiles individual spells
