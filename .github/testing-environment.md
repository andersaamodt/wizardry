# Testing Environment Differences

applyTo: ".tests/**"

## CI vs Local: Key Differences

### Sandboxing (CI Only)
- **Bubblewrap isolation**: Restricts `/dev/tty`, filesystem access
- **Impact**: Interactive prompts fail with "cannot open /dev/tty"
- **Fix**: Use `ASK_CANTRIP_INPUT=none` env var in tests, mock `/dev/tty`

### PATH Setup
- **CI**: PATH may be empty on some platforms (macOS), strictly controlled
- **Local**: Inherits user's full PATH
- **Impact**: Tests pass locally (tools available) but fail in CI
- **Fix**: Always `command -v tool` to check, test-bootstrap sets up PATH

### Environment Variables
- **CI**: Minimal set, test variables like `WIZARDRY_TEST_HELPERS_ONLY=1`
- **Local**: Full user environment
- **Impact**: Spells using undeclared vars fail with `set -eu`
- **Fix**: Always use `${VAR:-}` syntax, check existence before use

### Filesystem
- **CI**: Clean slate, `/home/runner/work/wizardry/wizardry`, controlled temp dirs
- **Local**: Anywhere, user's HOME with rc files, state persists
- **Impact**: Path assumptions fail, temp dirs behave differently
- **Fix**: Use `make_tempdir`, normalize paths with `pwd -P | sed 's|//|/|g'`

### Platform-Specific
- **macOS CI**: Empty PATH on start, needs baseline (`/usr/bin:/bin`)
- **Linux CI**: Standard PATH, bubblewrap available
- **Fix**: Bootstrap scripts set baseline PATH before `set -eu`

## Common Test Failure Patterns

| Symptom | Cause | Fix |
|---------|-------|-----|
| Works local, fails CI | Tool not in PATH | Add `command -v` check |
| "/dev/tty" error | Bubblewrap restriction | Mock with env var |
| "unbound variable" | Missing env var with `set -eu` | Use `${VAR:-}` |
| Different paths | Temp dir differences | Normalize: `pwd -P \| sed 's\|//\|/\|g'` |
| Command not found | Empty PATH (macOS CI) | Set baseline PATH |

## Test Best Practices

1. **Never assume tools exist**: Always `command -v tool >/dev/null`
2. **Use variable defaults**: `${VAR:-default}` or `${VAR-}`
3. **Set PATH explicitly**: test-bootstrap handles this
4. **Mock interactive input**: Use env vars, not actual prompts
5. **Normalize paths**: `pwd -P` + sed for cross-platform
6. **Clean slate**: Don't rely on persistent state
