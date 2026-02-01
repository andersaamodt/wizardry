# Wizardry Desktop Host

Minimal Rust-based WebView host for wizardry desktop apps.

## About

This is a lightweight native host binary that provides a WebView-based desktop app experience for wizardry applications. It uses the `wry` crate for cross-platform WebView support.

### Why Rust?

Per project policy:
- Go is made by Google (against non-commercial policy)
- Rust is the preferred alternative for compiled binaries
- We keep it minimal - just `wry` for WebView, not the full Tauri framework

## Dependencies

- `wry` - Cross-platform WebView library
- `tao` - Window management (dependency of wry)
- `serde` + `serde_json` - JSON serialization for IPC

## Building

### Prerequisites

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add target platforms
rustup target add x86_64-unknown-linux-gnu
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin
```

### Build for Linux

```bash
cargo build --release --target x86_64-unknown-linux-gnu
```

The binary will be at `target/x86_64-unknown-linux-gnu/release/wizardry-host`

### Build for macOS

```bash
# Intel
cargo build --release --target x86_64-apple-darwin

# Apple Silicon
cargo build --release --target aarch64-apple-darwin

# Create universal binary
lipo -create \
  -output wizardry-host \
  target/x86_64-apple-darwin/release/wizardry-host \
  target/aarch64-apple-darwin/release/wizardry-host
```

## Usage

```bash
wizardry-host /path/to/app/directory
```

The app directory must contain `index.html`.

## Native Bridge API

The host exposes a `window.wizardry.exec()` function to JavaScript:

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

### Security

- Commands must be hardcoded in the GUI JavaScript
- Only string arrays are accepted (no shell parsing)
- Execution via Rust's `Command::new()` (equivalent to `execvp()`)
- No way for user input to construct arbitrary commands

## Architecture

```
User clicks app
     ↓
wizardry-host binary launches
     ↓
Creates WebView window
     ↓
Loads app/index.html
     ↓
JavaScript calls window.wizardry.exec([...])
     ↓
Rust executes command via std::process::Command
     ↓
Returns JSON result to WebView
     ↓
App updates UI
```

## Size

The compiled binary is approximately:
- Linux: ~5-7 MB (stripped)
- macOS: ~8-10 MB (universal, stripped)

Size is kept minimal by:
- Using `wry` instead of full Tauri
- Stripping debug symbols
- LTO (Link-Time Optimization)
- Single codegen unit

## License

Same as wizardry project.
