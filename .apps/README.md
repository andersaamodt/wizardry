# Desktop Apps for Wizardry

This directory contains desktop apps - graphical wrappers around wizardry spells.

## Current Status: Placeholder Implementation

**Important:** The current `.app` bundles and AppImages are **placeholder implementations** that simply open HTML files in your default web browser. They are not yet true standalone desktop applications.

### What Works Now
- ✅ `.app` bundles can be double-clicked on macOS
- ✅ AppImages can be double-clicked on Linux  
- ✅ Menu-app demonstrates the UI concept
- ✅ Settings pages show the planned architecture

### What's Coming (Native Implementation)
- ⏳ Native host binary with embedded WebView
- ⏳ Direct command execution via `execvp()` (no shell)
- ⏳ True standalone apps that don't require a browser
- ⏳ Integration with running wizardry web server

To use the chatroom functionality now, run:
```bash
web-wizardry serve demo
```
Then open `http://localhost:8080/pages/chat.html` in your browser.

## Architecture (Planned)

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

### For End Users (No Terminal Required!)

**Double-click to launch:**
- On macOS: Double-click the `.app` bundle
- On Linux: Double-click the `.AppImage` file

**First time setup (chatroom app):**
1. Open the app
2. Go to Settings tab
3. Choose "Host Server" mode
4. Click "Start Server" button
5. Share the connection URL with friends!

**Client mode:**
- Choose "Client Only" mode to connect to someone else's chatroom
- No server needed - just enter their URL in the chat tab

### For Developers

List available apps:
```bash
list-apps
```

Launch an app (currently validation only):
```bash
launch-app chatroom
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
- **Standalone operation - no terminal required!**
  - Double-click the app to launch
  - Choose Client-Only or Host Server mode
  - Start/stop server directly from Settings GUI
  - Mode preference saved between sessions
- **Settings page with:**
  - Mode selection (Client vs Host)
  - Server start/stop controls
  - Server status monitoring
  - Connection URL display (IP:port)
  - IP and Tor address display
  - Copy-to-clipboard functionality
- Full compatibility with MUD `say` command format
- Tor hidden service support for anonymous access

The chatroom app shows how desktop apps can be minimal frames around existing web functionality, avoiding code duplication. **It's designed to be completely standalone** - users can double-click the .app bundle on macOS or AppImage on Linux, choose their mode, and start hosting or connecting without ever touching a terminal.

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
