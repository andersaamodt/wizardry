# web wizardry platform

The wizardry web platform enables creating honest web pages with interactivity backed directly by POSIX shell scripts.

## Demo Pages

This template includes comprehensive browser API demonstrations organized into topic-specific pages:

**State & Persistence:**
- localStorage, sessionStorage, IndexedDB
- Cookies, storage quotas

**Forms & Input:**
- Keyboard events, pointer events (mouse/touch/pen)
- Native form controls, focus management
- Clipboard API

**Graphics & Media:**
- Canvas 2D rendering, SVG graphics
- Audio playback, Web Audio API synthesis
- WebGL (3D graphics), WebGPU (next-gen GPU)

**Time & Performance:**
- setTimeout/setInterval, requestAnimationFrame
- Performance API, Page Visibility API

**Workers & Background:**
- Web Workers (background threads)
- Service Workers (network interception)
- Message passing between threads

**Hardware & Sensors:**
- Camera access (getUserMedia)
- Microphone access with audio visualization
- Screen capture (getDisplayMedia)
- Device motion & orientation sensors

**Security & Permissions:**
- Same-Origin Policy demonstrations
- Permissions API queries
- Secure context detection

**File Upload & Binary I/O:**
- File picker, drag-and-drop upload
- Blobs and binary data manipulation
- File System Access API (read/write local files)

**Additional Browser APIs:**
- Vibration API, Battery Status API
- Network Information API
- Wake Lock API, Page Lifecycle API

**Server-Side Demos:**
- CGI backend processing
- Real-time chat, interactive polls
- System information, custom elements

All navigation is centralized in `includes/nav.md` for easy maintenance.

## Features

- **Markdown to HTML**: Write content in Markdown, build with Pandoc
- **CGI Backend**: Server-side interactivity via shell scripts
- **nginx**: Fast, reliable static file serving
- **Let's Encrypt**: Automatic HTTPS certificate provisioning
- **htmx**: Client-side partial page updates
- **No databases**: All state lives in the filesystem

## Installation

Install web components via the install menu:

```sh
menu  # Select "wizardry web" from install menu
```

Or install individually:

```sh
# In the wizardry web install menu, toggle:
- Pandoc (Markdown renderer)
- nginx (web server)
- fcgiwrap (CGI execution)
- OpenSSL (TLS support)
- htmx (JS library)
- certbot (Let's Encrypt)
```

## Quick Start

### 1. Create a Site

```sh
web-wizardry create mysite
```

This creates:
- `~/sites/mysite/site/` - Source files
- `~/sites/mysite/site/pages/` - Markdown pages
- `~/sites/mysite/site/static/` - CSS, images, etc.
- `~/sites/mysite/site/uploads/` - User uploads
- `~/sites/mysite/build/` - Generated HTML

### 2. Edit Content

Edit `~/sites/mysite/site/pages/index.md`:

```markdown
---
title: My Page
---

# Welcome

This is my website built with wizardry web.
```

### 3. Build

```sh
web-wizardry build mysite
```

Or for continuous rebuild:

```sh
web-wizardry build mysite --watch
```

### 4. Serve

```sh
web-wizardry serve mysite
```

Visit http://localhost:8080

### 5. Configure

```sh
# Change port
configure-nginx mysite --port 3000

# Set domain
configure-nginx mysite --domain example.com

# Enable HTTPS with Let's Encrypt
https mysite --email admin@example.com
```

## Site Structure

```
~/sites/mysite/
├── site/
│   ├── pages/           # Markdown source files
│   │   └── index.md
│   ├── static/          # CSS, images, JS
│   │   └── style.css
│   └── uploads/         # User-uploaded files
├── build/               # Generated HTML (auto-created)
│   ├── pages/
│   │   └── index.html
│   └── static/
├── nginx/               # nginx config (auto-created)
│   └── nginx.conf
└── site.conf            # Site settings
```

## CGI Scripts

All CGI scripts must be in `$WIZARDRY_DIR/spells/.imps/cgi/`.

Example CGI script (`spells/.imps/cgi/hello`):

```sh
#!/bin/sh
set -eu

# Output headers
http-status 200 "OK"
http-header "Content-Type" "text/html"
http-end-headers

# Output body
cat <<'HTML'
<!DOCTYPE html>
<html>
<body>
  <h1>Hello from CGI!</h1>
</body>
</html>
HTML
```

Call from HTML:

```html
<a href="/cgi/hello">Run CGI Script</a>
```

## CGI Imps

Available CGI helper imps:

- `http-status CODE MESSAGE` - Output HTTP status
- `http-header NAME VALUE` - Output HTTP header
- `http-end-headers` - End headers section
- `url-decode STRING` - Decode URL-encoded string
- `parse-query QUERY_STRING` - Parse query parameters

## Commands

### Main Command

```sh
web-wizardry [COMMAND]        # Interactive menu or run command
```

### Site Management

```sh
create-site SITENAME      # Create new site
delete-site SITENAME      # Delete site
site-status SITENAME      # Show site status
site-menu SITENAME        # Open site management menu
```

### Building

```sh
build SITENAME            # Build site (incremental)
build SITENAME --full     # Full rebuild
build SITENAME --watch    # Watch mode
```

### Serving

```sh
serve-site SITENAME       # Start nginx
stop-site SITENAME        # Stop nginx
configure-nginx SITENAME  # Configure nginx
```

### HTTPS

```sh
https SITENAME --email EMAIL  # Set up Let's Encrypt
```

## Environment Variables

- `WEB_WIZARDRY_ROOT` - Root directory (default: `~/sites`)
- `WIZARDRY_DIR` - Wizardry installation directory

## Architecture

### Build Process

1. Read Markdown files from `site/pages/`
2. Parse YAML front matter
3. Convert to HTML with Pandoc
4. Write to `build/pages/`
5. Copy static files to `build/static/`

### Serving

1. nginx serves static files from `build/`
2. CGI requests proxied to fcgiwrap
3. fcgiwrap executes shell scripts from `spells/.imps/cgi/`
4. CGI scripts output HTTP headers and body

### Security

- CGI execution restricted to `spells/.imps/cgi/` only
- File uploads go to `site/uploads/` (outside build directory)
- HTTPS enforced via Let's Encrypt
- No server-side JavaScript execution

## Design Principles

1. **Filesystem as database**: No hidden state, everything in files
2. **Reproducible builds**: Delete `build/` and rebuild = identical result
3. **UNIX philosophy**: Small, composable shell scripts
4. **Transparent**: No magic, just shell scripts and nginx
5. **Secure by default**: HTTPS required, restricted CGI execution

## Troubleshooting

### Port already in use

```sh
# Change port
configure-nginx mysite --port 8081
```

### Build not updating

```sh
# Force full rebuild
web-wizardry build mysite --full
```

### nginx won't start

```sh
# Check nginx config
nginx -t -c ~/sites/mysite/nginx/nginx.conf

# Check logs
cat ~/sites/mysite/nginx/error.log
```

### Let's Encrypt fails

Ensure:
1. Domain points to your server
2. Port 80 is accessible from internet
3. nginx is running
4. Build directory exists

## Examples

See `spells/.imps/cgi/example-cgi` for a working CGI example.

## License

Part of the wizardry project.
