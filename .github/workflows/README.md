# GitHub Actions Workflows

This directory contains GitHub Actions workflows for testing and building wizardry.

## Workflows

### collect-failures.yml

**Purpose**: Automatically collects failure outputs from all test workflows into a single, continuously updated location that Copilot can read.

**Triggers**:
- Runs after any test workflow completes (using `workflow_run` trigger)
- Monitors: Unit tests, POSIX/linting checks, compiled spell tests, doppelganger tests, dual-pattern validation, demonstrate-wizardry, compile

**Features**:
- Creates individual markdown files for each workflow in `.github/workflow-failures/`
- Updates files incrementally as each workflow completes
- Maintains a combined `README.md` index showing all current failures
- Commits files to repository (for main branch) so Copilot can read them
- Also uploads as a single cumulative artifact `workflow-failures-combined`
- Downloads previous artifact state to maintain cumulative history
- Successful workflows clear their failure reports
- Failed workflows add detailed failure information

**How It Works**:
1. When a workflow completes, this workflow triggers
2. Downloads previous failure reports from artifact (if exists)
3. Updates the markdown file for the completed workflow
4. Regenerates the combined README index
5. Uploads everything as a single `workflow-failures-combined` artifact
6. Commits to repository (main branch only)

**File Structure**:
- `.github/workflow-failures/README.md` - Combined index of all workflow statuses
- `.github/workflow-failures/<workflow-name>.md` - Individual workflow failure reports
- Each report includes:
  - Workflow status and metadata
  - Failed job details
  - Filtered failure output (collapsed)
  - Full log context (last 100 lines, collapsed)

**Usage for Copilot**:
When debugging workflow failures in a PR:
1. Download the `workflow-failures-combined` artifact from the latest "Collect test failures" run
2. Extract and review `.github/workflow-failures/README.md` for overview
3. Open individual workflow markdown files for detailed failure information
4. Copilot can also read these files directly if they've been committed to main

**Usage for Humans**:
1. Go to Actions → Collect test failures → Latest run
2. Download `workflow-failures-combined` artifact
3. Extract and open `README.md` for status overview
4. Click through to individual workflow reports for details

**Benefits**:
- ✅ Single artifact that updates cumulatively
- ✅ Copilot-readable (committed markdown files on main branch)
- ✅ Easy to download and review
- ✅ Shows current state of all workflows
- ✅ Only contains failures (successes clear previous failures)
- ✅ Timestamped and includes commit information
- ✅ Works for both PR and main branch workflows

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

### test-standalone-spells.yml

**Purpose**: Tests that individual spells compile and run standalone.

**Features**:
- Compiles all spells individually
- Tests each compiled spell in isolation with `env -i PATH="/usr/bin:/bin"`
- Runs behavioral tests on compiled spells
- Reports success rate and failures

### tests.yml

**Purpose**: Main test suite for wizardry spells.

**Features**:
- Runs all tests in `.tests/` directory
- Tests spells in the full wizardry environment
- Primary validation for spell functionality

### vet-spells.yml

**Purpose**: Lints and validates spell code quality.

**Features**:
- Runs `lint-magic` on all spells
- Checks for POSIX compliance with `checkbashisms`
- Validates spell formatting and style

### posix.yml

**Purpose**: Validates POSIX shell compliance.

**Features**:
- Checks scripts for bash-isms
- Ensures portability across different shells

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
