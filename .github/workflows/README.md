# GitHub Actions Workflows

This directory contains GitHub Actions workflows for testing and building wizardry.

## Workflows

### collect-failures.yml

**Purpose**: Automatically collects test failure outputs and makes them visible to Copilot via job summaries and workflow logs.

**Triggers**:
- Runs after any monitored workflow completes (using `workflow_run` trigger)
- Monitors: Unit tests, POSIX/linting, standalone spells, doppelganger, dual-pattern validation, demonstrate-wizardry, compile

**Note**: This workflow may require approval on each run for AI-created changes. See `pr-test-monitor.yml` for an alternative that avoids this issue.

**How It Works**:

1. **Workflow Logs** 📜 *Sequential output for easy review*
   - Failure details output directly to workflow run logs
   - Extracts only relevant error text:
     - **Unit tests**: Test summary section (from "=== Test Summary ===" marker)
     - **Other workflows**: Error lines with context (##\[error\] or FAIL/ERROR patterns)
   - Easily searchable and copyable

2. **Job Summary** 📊 *Copilot can read this immediately*
   - Uses `$GITHUB_STEP_SUMMARY` to display status
   - Shows which workflow failed
   - Links to detailed logs
   - Visible in workflow run "Summary" tab

**Features**:
- ✅ No artifacts needed (logs are in workflow output)
- ✅ Job summary visible to Copilot immediately
- ✅ Sequential log output easy to search
- ✅ PR comments for failed workflows (optional)
- ✅ No repository commits
- ✅ Extracts only actual error text, not full logs

**For Copilot Users**:
When a workflow fails:
1. Copilot can read the job summary
2. Detailed logs are in the workflow run output
3. Ask Copilot: *"What test failures do I need to fix?"*

**For Humans**:
1. Check job summary for quick overview
2. Read workflow logs for detailed failure output
3. Copy/paste relevant errors for debugging

**Example Log Output**:
```
=== FAILED JOB: macOS unit tests ===

--- Test Summary ---
=== Test Summary ===
Total: 43/50 tests passed (7 failed)
Subtests: 120 passed, 127 total

Failed tests: test-foo.sh, test-bar.sh
Failed levels: 3, 5
```

### pr-test-monitor.yml

**Purpose**: Monitors all test workflows for a PR and reports failures in a single long-running job. This avoids the approval requirement issue with `workflow_run` triggered workflows.

**Triggers**:
- Pull request opened, synchronized, or reopened

**How It Works**:

1. **Long-Running Monitor** 🔍 *Stays alive and polls for completions*
   - Runs once per PR (appears in PR checks immediately)
   - Polls GitHub API every 5 seconds for workflow completions
   - Monitors up to 1 hour (timeout-minutes: 60)
   - Tracks which workflows have been reported

2. **Smart Error Extraction** 📝 *Only relevant error text*
   - **Unit tests**: Extracts "=== Test Summary ===" section only
   - **Other workflows**: Extracts ##\[error\] markers or FAIL/ERROR patterns
   - Shows minimal context (no full logs)

3. **Real-Time Reporting** 📊 *Progress updates every minute*
   - Logs workflow completions as they happen
   - Shows pass/fail status for each workflow
   - Reports completion progress every minute

**Advantages over collect-failures.yml**:
- ✅ No approval required (uses `pull_request` trigger, not `workflow_run`)
- ✅ Appears in PR checks immediately
- ✅ Single job shows all failures in one place
- ✅ Polls for completions instead of being triggered by each workflow

**Features**:
- ✅ Monitors 7 workflows: Unit tests, POSIX/linting, standalone spells, doppelganger, dual-pattern validation, demonstrate-wizardry, compile
- ✅ Extracts only actual error text (test summaries or error messages)
- ✅ File-based tracking of reported runs (avoids duplicates)
- ✅ Automatic timeout after 1 hour
- ✅ Progress logging every minute

**For Copilot Users**:
When tests fail:
1. Check the "Monitor PR workflows" job logs
2. Find the failed workflow section
3. Review the extracted error text
4. Ask Copilot: *"Fix the test failures shown in the PR test monitor"*

**Example Log Output**:
```
========================================================================
 PR TEST MONITOR - Starting
========================================================================
PR Number: 123
Commit SHA: abc123...

----------------------------------------
Workflow: Unit tests
Run ID: 456789
Status: failure
❌ FAILED - extracting error details...

Failed jobs: 1

--- Failed Job: macOS unit tests ---
=== Test Summary ===
Total: 43/50 tests passed (7 failed)
Subtests: 120 passed, 127 total

Failed tests: test-foo.sh, test-bar.sh

[13:45:30] Monitoring... (1/7 workflows completed)
[13:46:30] Monitoring... (3/7 workflows completed)
All workflows completed. Monitoring finished.
```

**Monitoring Details**:
- Poll interval: 5 seconds
- Maximum polls: 720 (1 hour total)
- Progress updates: Every 12 polls (1 minute)

### collect-failures.yml vs pr-test-monitor.yml

Use **pr-test-monitor.yml** (recommended):
- When you want failures to appear in PR checks immediately
- To avoid workflow approval requirements
- For a single consolidated view of all test failures

Use **collect-failures.yml** (legacy):
- As a backup if pr-test-monitor has issues
- When you specifically want workflow_run triggers

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
