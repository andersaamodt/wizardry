# Integration Guide: Adding Banish to Demo-Magic

This guide shows how to integrate the working POC pattern into the actual `spells/spellcraft/demo-magic`.

## Step 1: Add Banish Validation to demo_level Function

Add banish validation at the start of each level's demonstration. Here's the pattern:

```sh
demo_level() {
  level=$1
  
  # Get level name and spell list using spell-levels imp
  level_name=$(spell-levels "$level" name)
  spell_list=$(spell-levels "$level" spells)
  imp_list=$(spell-levels "$level" imps)
  
  printf '\n'
  printf '=== Level %d: %s ===\n' "$level" "$level_name"
  printf '\n'
  
  # ADD THIS: Banish validation before demonstrating
  printf 'Validating prerequisites with banish...\n'
  if ! banish "$level" --only --no-tests 2>&1; then
    printf '\n✗ Banish validation failed for level %d\n' "$level" >&2
    printf 'Skipping level %d demonstration\n' "$level" >&2
    return 1
  fi
  printf '✓ Prerequisites validated\n\n'
  
  # Rest of existing level-specific demonstrations...
  case "$level" in
    0)
      printf 'The wizard examines the foundation of reality itself...\n'
      # ... existing code ...
```

## Step 2: Update demonstrate-wizardry.yml Workflow

Replace the current "Run demo-magic" step with PTY-enabled version:

```yaml
- name: Run demo-magic with PTY
  run: |
    . spells/.imps/sys/invoke-wizardry
    run-with-pty demo-magic all
```

Or for more control:

```yaml
- name: Run demo-magic with PTY
  run: |
    . spells/.imps/sys/invoke-wizardry
    # Run with timeout to prevent hanging
    timeout 300 run-with-pty demo-magic all || {
      exit_code=$?
      if [ $exit_code -eq 124 ]; then
        echo "demo-magic timed out after 300 seconds"
        exit 1
      fi
      exit $exit_code
    }
```

## Step 3: Add Command-Line Flags (Optional)

Add flags similar to the POC for better control:

```sh
# Parse arguments
demo_level=27  # Default to all levels
skip_banish=0  # New flag

while [ "$#" -gt 0 ]; do
  case "$1" in
    --skip-banish)
      skip_banish=1
      shift
      ;;
    # ... other flags ...
  esac
done

# Then in demo_level():
if [ "$skip_banish" -eq 0 ]; then
  printf 'Validating prerequisites with banish...\n'
  if ! banish "$level" --only --no-tests 2>&1; then
    printf '\n✗ Banish validation failed for level %d\n' "$level" >&2
    return 1
  fi
  printf '✓ Prerequisites validated\n\n'
fi
```

## Step 4: Error Handling

Decide how to handle banish failures:

### Option A: Skip Failed Levels (Graceful)
```sh
demo_level() {
  # ... setup ...
  
  if ! banish "$level" --only --no-tests 2>&1; then
    printf '\n⚠ Level %d prerequisites not met - skipping\n' "$level" >&2
    return 0  # Continue with other levels
  fi
  
  # ... demonstrations ...
}
```

### Option B: Abort on Failure (Strict)
```sh
demo_level() {
  # ... setup ...
  
  if ! banish "$level" --only --no-tests 2>&1; then
    printf '\n✗ Level %d prerequisites not met - aborting\n' "$level" >&2
    exit 1  # Fail the entire demo
  fi
  
  # ... demonstrations ...
}
```

### Option C: Log and Continue (Informational)
```sh
demo_level() {
  # ... setup ...
  
  printf 'Checking prerequisites with banish...\n'
  if banish "$level" --only --no-tests 2>&1; then
    printf '✓ Prerequisites OK\n\n'
  else
    printf '⚠ Some prerequisites missing (continuing anyway)\n\n' >&2
  fi
  
  # ... demonstrations always run ...
}
```

## Step 5: Testing the Integration

Test incrementally:

```sh
# 1. Test locally without PTY first
. spells/.imps/sys/invoke-wizardry
demo-magic 2

# 2. Test locally with PTY
run-with-pty demo-magic 2

# 3. Test specific levels
run-with-pty demo-magic 0
run-with-pty demo-magic 1
run-with-pty demo-magic 2

# 4. Test higher levels
run-with-pty demo-magic 4
```

## Minimal Change Approach

For absolute minimal changes to existing demo-magic:

```sh
# Add this single line at the start of demo_level() function,
# right after the level_name/spell_list setup:

banish "$level" --only --no-tests >/dev/null 2>&1 || true
```

This validates silently and always continues. For more visibility:

```sh
printf '(Validating level %d... ' "$level"
if banish "$level" --only --no-tests >/dev/null 2>&1; then
  printf 'OK)\n\n'
else
  printf 'warnings ignored)\n\n'
fi
```

## Recommended Approach

Based on the POC, I recommend:

1. **Add visible banish validation** that shows output (users can see what's being validated)
2. **Use `--only --no-tests` flags** for speed (we just want assumption checks)
3. **Continue on failure** with a warning (graceful degradation)
4. **Use run-with-pty** in the workflow (proven to work)
5. **Add timeout** to prevent hanging (safety net)

This provides maximum value (shows validation happening) with minimal risk (doesn't break existing functionality).
