# Desktop Apps for Wizardry

This directory contains desktop apps - graphical wrappers around wizardry spells.

## Architecture

Desktop apps in wizardry follow a minimal, flat architecture:

- **No Router/Navigation**: Each app is standalone
- **Direct Shell Access**: Apps are graphical consoles for Unix, not sealed containers
- **Hardcoded Commands**: WebView defines which commands it can execute (in the GUI code itself)
- **Direct Execution**: Commands run via `execvp()`, no shell parsing
- **No Daemon**: Fork-per-action model by default
- **CLI Parity**: Removing the GUI must not break functionality

## App Structure

Each app lives in `.apps/<appname>/` with the following files:

```
.apps/my-app/
├── index.html     # Entry point loaded into WebView (required)
└── style.css      # Optional styling
```

### index.html

The single HTML file loaded directly into a WebView. This is your app's UI.

Commands are hardcoded in the JavaScript. Example:

```javascript
const commands = {
  'show-help': ['menu', '--help'],
  'list-spells': ['list-apps'],
  'show-env': ['env']
};

// Execute via native bridge
window.wizardry.exec(commands[action]);
```

**Security**: The WebView can only execute commands that are explicitly hardcoded in the GUI. There's no way for user input to construct arbitrary commands.

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

Commands are hardcoded in the WebView's JavaScript and executed directly via `execvp()`:

- ✅ Commands defined in GUI code (e.g., `['menu', '--help']`)
- ✅ Command name resolved via PATH at execution time
- ✅ Live upgrades allowed (spells can be updated while app is running)
- ✅ Stdout and stderr captured and returned to WebView
- ❌ No shell parsing
- ❌ No `/bin/sh -c`
- ❌ User input cannot construct commands

Example of hardcoded commands in GUI:
```javascript
const commands = {
  'refresh': ['list-apps'],
  'help': ['menu', '--help']
};
```

## Building Apps

Desktop apps can be packaged for distribution using GitHub Actions workflows.

### Automated Builds (CI/CD)

The repository includes a GitHub Actions workflow (`.github/workflows/build-desktop-apps.yml`) that automatically builds all apps when a version tag is pushed:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This will:
1. Build AppImage packages for Linux
2. Build .app bundles for macOS
3. Create a GitHub Release with all artifacts
4. Upload the packages for easy download

You can also trigger builds manually from the GitHub Actions tab.

### Manual Builds

For local development and testing:

#### Linux (AppImage)

```bash
build-appimage my-app
```

Note: The `build-appimage` spell is currently a placeholder. Use the GitHub Actions workflow for production builds.

#### macOS (.app bundle)

```bash
build-macapp my-app
```

Note: The `build-macapp` spell is currently a placeholder. Use the GitHub Actions workflow for production builds.

### Build Output

Built packages are available as:
- **Linux**: `wizardry-APPNAME-x86_64.AppImage`
- **macOS**: `Wizardry-APPNAME.app.zip`

Currently, the built packages open the app's `index.html` in the default web browser. Native WebView integration is planned for future releases.

## Managing Apps

List available apps:
```bash
list-apps
```

Launch an app (currently validation only):
```bash
launch-app menu-app
```

## Examples

### menu-app

See `.apps/menu-app/` for a simple example demonstrating:
- WebView UI with buttons
- Hardcoded commands in JavaScript
- Output display
- Styling

### chatroom

See `.apps/chatroom/` for a real-world example demonstrating:
- Thin wrapper around existing web demo (reuses `.templates/demo/pages/chat.md`)
- Integration with CGI scripts for backend communication
- Server-Sent Events (SSE) for real-time updates
- **Settings page with:**
  - Server status check and start button
  - Connection URL display (IP:port)
  - IP and Tor address display
  - Copy-to-clipboard functionality
- Full compatibility with MUD `say` command format
- Tor hidden service support for anonymous access

The chatroom app shows how desktop apps can be minimal frames around existing web functionality, avoiding code duplication. The settings page helps users start the server and share connection information with others.

## Development Workflow

1. Create app directory: `mkdir -p .apps/my-app`
2. Create `index.html` with UI and hardcoded commands
3. Add styling in `style.css` (optional)
4. Test with `launch-app my-app`
5. Build for distribution

## Design Principles

**Flat and Low-to-the-Ground**
- Apps are thin skins over shell scripts
- No framework bloat
- Minimal layers between UI and shell

**Security Through Simplicity**
- Commands hardcoded in GUI prevent injection attacks
- No way for user input to construct arbitrary commands
- Direct execution via `execvp()` eliminates shell parsing vulnerabilities

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
