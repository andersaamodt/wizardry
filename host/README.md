# Wizardry Desktop Host

Minimal native WebView host for wizardry desktop apps.

## About

This provides native WebView-based desktop applications using platform-native APIs:
- **macOS**: Objective-C with Cocoa + WebKit
- **Linux**: C with GTK3 + WebKit2GTK

No external language ecosystems (no Rust/Cargo, no Go modules). Just simple native code compiled with platform compilers.

## Building

### macOS

```bash
cd host/macos
clang -O2 -fobjc-arc main.m -o wizardry-host -framework Cocoa -framework WebKit
```

That's it! Single command, ~100-200 KB binary.

### Linux

```bash
cd host/linux
gcc -O2 main.c -o wizardry-host `pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.0`
```

Dependencies: `gtk+-3.0`, `webkit2gtk-4.0` (usually already installed on Linux desktops)

## Usage

```bash
wizardry-host /path/to/app/directory
```

The app directory must contain `index.html`.

## JavaScript API

The host injects a `window.wizardry.exec()` function:

```javascript
// Execute a command
const result = await window.wizardry.exec(['list-apps']);

// Result format:
// {
//   stdout: "...",
//   stderr: "...",
//   exit_code: 0,
//   error: null
// }
```

### Implementation

The JavaScript bridge works via platform-specific message handlers:

**macOS**: `window.webkit.messageHandlers.wizardry.postMessage(...)`
**Linux**: `window.webkit.messageHandlers.wizardry.postMessage(...)`

The native code receives messages, executes commands via `execvp()` (macOS: NSTask, Linux: fork+exec), and returns results.

### Security

- Commands are hardcoded in the GUI JavaScript (not constructed from user input)
- Only string arrays are accepted
- Direct execution via `execvp()` (no shell parsing)
- Commands are resolved via PATH at runtime

## Architecture

```
User clicks app
     ↓
wizardry-host binary launches
     ↓
Creates native WebView window
     ↓
Loads app/index.html
     ↓
JavaScript calls window.wizardry.exec([...])
     ↓
Native code executes command via execvp
     ↓
Returns JSON result to WebView
     ↓
App updates UI
```

## Binary Size

- macOS: ~100-200 KB (stripped)
- Linux: ~50-100 KB (stripped)

Much smaller than Rust/Go alternatives because we use system frameworks.

## Why Not Rust/Go?

**Rust:**
- External ecosystem (Cargo, crates.io)
- Many build steps
- Large dependency tree
- ~5-10 MB binaries
- Against "low to the ground" philosophy

**Go:**
- Made by Google (against project policy)
- Still adds complexity

**Native C/Objective-C:**
- ✅ Simple single-command build
- ✅ Tiny binaries
- ✅ No external dependencies
- ✅ Fast compilation
- ✅ "Lower to the ground"

## License

Same as wizardry project.

