# Wizardry Desktop App Host Binary

This is the native host binary for Wizardry desktop apps. It provides:

- Cross-platform WebView embedding
- Native bridge for executing shell commands from JavaScript
- Environment capture from login shell + invoke-wizardry
- Direct command execution via Go's exec (equivalent to execvp)

## Building

### Prerequisites

**Linux:**
```bash
sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev
```

**macOS:**
No additional prerequisites (uses system WebKit)

**Windows:**
Uses Edge WebView2 (bundled with Windows 10+)

### Compile

```bash
cd host
go build -o wizardry-host
```

### Cross-compile

**For Linux from macOS:**
```bash
GOOS=linux GOARCH=amd64 go build -o wizardry-host-linux
```

**For macOS from Linux:**
```bash
GOOS=darwin GOARCH=amd64 go build -o wizardry-host-macos
```

## Usage

```bash
./wizardry-host /path/to/app/directory
```

The app directory must contain an `index.html` file.

## Native Bridge API

The host exposes `window.wizardry.exec()` to JavaScript:

```javascript
// Execute a command
const result = window.wizardry.exec(['list-apps']);

// Result object:
// {
//   stdout: "menu-app\nchatroom\n",
//   stderr: "",
//   exitCode: 0,
//   error: ""
// }
```

Commands are executed directly (no shell parsing) using Go's `exec.Command()`.
