# Desktop Apps for Wizardry

This directory contains desktop apps - graphical wrappers around wizardry spells.

## Architecture

Desktop apps in wizardry follow a minimal, flat architecture:

- **No Router/Navigation**: Each app is standalone
- **Direct Shell Access**: Apps are graphical consoles for Unix, not sealed containers
- **Symbolic Verbs**: WebView invokes predefined verbs, not arbitrary shell commands
- **Validated Arguments**: All arguments come from hardcoded, validated value sets
- **Direct Execution**: Commands run via `execvp()`, no shell parsing
- **No Daemon**: Fork-per-action model by default
- **CLI Parity**: Removing the GUI must not break functionality

## App Structure

Each app lives in `.apps/<appname>/` with the following required files:

```
.apps/my-app/
├── index.html     # Entry point loaded into WebView
├── verbs.conf     # Verb-to-command mappings
└── style.css      # Optional styling
```

### index.html

The single HTML file loaded directly into a WebView. This is your app's UI.

The WebView invokes backend actions via JavaScript:
```javascript
window.wizardry.invoke('verb-name', [args...])
```

### verbs.conf

Maps symbolic verb names to predefined commands. Format:

```
VERB_NAME command [fixed_args...]
```

Example:
```
show-help menu --help
list-spells list-apps
show-path sh -c echo "$PATH"
```

**Security**: The WebView can ONLY invoke verbs defined in this file. No free-form shell execution is allowed.

### style.css

Optional styling for your app. Keep it simple.

## Environment

At startup, the host binary:

1. Launches a login shell
2. Sources `invoke-wizardry` to set up wizardry environment
3. Captures the resulting environment (especially PATH)
4. Uses this unchanged environment for all command execution

This means your apps have full access to all wizardry spells and the user's shell environment.

## Command Execution

Commands are executed directly via `execvp()`:

- ✅ Command name resolved via PATH at execution time
- ✅ Live upgrades allowed (spells can be updated while app is running)
- ✅ Stdout and stderr captured and returned to WebView
- ❌ No shell parsing
- ❌ No `/bin/sh -c`
- ❌ WebView cannot construct shell syntax

## Building Apps

### Linux (AppImage)

```bash
build-appimage my-app
```

Creates a standalone AppImage that bundles the app with a minimal runtime.

### macOS (.app bundle)

```bash
build-macapp my-app
```

Creates a .app bundle using the same host binary for cross-platform consistency.

## Managing Apps

List available apps:
```bash
list-apps
```

Launch an app (currently validation only):
```bash
launch-app menu-app
```

## Example: menu-app

See `.apps/menu-app/` for a complete example demonstrating:
- WebView UI with buttons
- Verb invocation pattern
- Output display
- Styling

## Development Workflow

1. Create app directory: `mkdir -p .apps/my-app`
2. Create `index.html` with UI
3. Create `verbs.conf` with allowed commands
4. Add styling in `style.css`
5. Test with `launch-app my-app`
6. Build for distribution

## Design Principles

**Flat and Low-to-the-Ground**
- Apps are thin skins over shell scripts
- No framework bloat
- Minimal layers between UI and shell

**Security Through Simplicity**
- Symbolic verbs prevent shell injection
- Validated arguments only
- No arbitrary command construction

**Unix Philosophy**
- Each app does one thing
- Apps compose with shell tools
- GUI is optional, not required

**CLI Parity Invariant**
- Every app action must have a CLI equivalent
- Removing the GUI should not break functionality
- Apps are conveniences, not dependencies

## Future Work

- Native WebView integration (currently planned)
- AppImage and .app bundle builders
- CI automation for building all apps
- Additional example apps
