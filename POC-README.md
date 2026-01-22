# Demo-Magic POC: Quick Start

This proof-of-concept demonstrates successful integration of banish validation into demo-magic using socat/PTY. **Unlike PR #981, this does not hang.**

## Files in This POC

- **`demo-magic-poc`** - Working POC script (executable)
- **`POC-NOTES.md`** - Technical analysis and findings
- **`INTEGRATION-GUIDE.md`** - Step-by-step guide to apply this to real demo-magic
- **`.github/workflows/demo-magic-poc.yml`** - CI workflow that tests the POC
- **`POC-README.md`** - This file

## Quick Test

```sh
# Install socat if needed
sudo apt-get install -y socat

# Source wizardry environment
. spells/.imps/sys/invoke-wizardry

# Run POC directly (no PTY)
./demo-magic-poc 2

# Run POC with PTY (the key innovation)
run-with-pty ./demo-magic-poc 2

# Test higher levels
run-with-pty ./demo-magic-poc 4
```

## Expected Output

You should see:
- Banish validation running for each level
- All output captured correctly
- No hanging at level 2 or any other level
- "DEMO_POC_COMPLETE" at the end

## What This Proves

✅ Banish works with socat/PTY when using `run-with-pty`  
✅ Levels 0-4 all validate successfully  
✅ Output is captured properly  
✅ No hanging issues  

## Next Steps

1. **Review `POC-NOTES.md`** - Understand why this works
2. **Review `INTEGRATION-GUIDE.md`** - Learn how to apply this pattern
3. **Test the POC** - Verify it works in your environment
4. **Apply to demo-magic** - Follow the integration guide

## Key Insight

The issue in PR #981 was using a complex custom socat wrapper. This POC uses the existing, tested `run-with-pty` helper which provides clean PTY integration without the complexity.

## Testing in CI

Push this branch and check the "Demo-Magic POC" workflow. It should pass all tests, proving the approach works in CI environments.
