# GitHub Actions Workflows

This directory contains GitHub Actions workflows for testing and building wizardry.

## Workflows

### collect-failures.yml

**Purpose**: Automatically collects test failure outputs and makes them immediately visible to Copilot.

**Triggers**:
- Runs after any monitored workflow completes (using `workflow_run` trigger)
- Monitors: Unit tests, POSIX/linting, standalone spells, doppelganger, dual-pattern validation, demonstrate-wizardry, compile

**How Copilot Sees Failures** (3 mechanisms):

1. **PR Comments** ⚡ *Immediate visibility in conversation*
   - Posts/updates a single comment on the PR with current failure status
   - Copilot can read these comments directly in the conversation thread
   - Includes collapsible details for each failing workflow
   - Updates as each workflow completes

2. **Job Summaries** 📊 *Visible in workflow run UI*
   - Appears in the "Summary" tab of each workflow run
   - Shows cumulative failure status across all workflows
   - Markdown formatted with rich formatting
   - Immediately visible without downloading anything

3. **Artifact** 💾 *Detailed logs for deep debugging*
   - Single artifact: `workflow-failures-latest` (always same name)
   - Downloads previous state and merges new failures
   - Contains detailed markdown reports per workflow
   - Backup mechanism for full context

**Features**:
- ✅ Single cumulative state (not one artifact per run)
- ✅ Updates incrementally as workflows complete
- ✅ Successful workflows remove their failure reports
- ✅ Failed workflows add filtered failure output
- ✅ No repository commits (all in workflow outputs)
- ✅ Works for both PR and main branch workflows

**For Copilot Users**:
When a workflow fails on your PR:
1. Check the PR comment for a quick summary
2. Ask Copilot: *"What test failures do I need to fix?"*
3. Copilot can read the comment and help debug
4. For detailed logs, download the `workflow-failures-latest` artifact

**For Humans**:
1. Check PR comment for overview
2. View workflow run summary for cumulative status
3. Download artifact if you need full logs

**File Structure in Artifact**:
- `README.md` - Index of all current failures
- `<Workflow_Name>.md` - Individual failure reports with:
  - Filtered failure output (grep for FAIL/ERROR)
  - Log context (last 50 lines)
  - Links to workflow runs

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
