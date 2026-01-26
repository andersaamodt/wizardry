---
title: About Wizardry Web
---

# About Wizardry Web

[← Back to Home](/pages/index.html)

## What is Wizardry Web?

**Wizardry Web** is a radical approach to web development that brings the power of POSIX shell scripts to the browser. Instead of complex JavaScript frameworks and heavyweight backend languages, Wizardry Web uses:

- **Shell scripts** for all server-side logic
- **Pandoc** to convert Markdown to HTML
- **htmx** for seamless interactivity
- **nginx** for serving and CGI execution
- **No databases** - the filesystem IS the database

## Architecture

```
Browser Request
    ↓
nginx (web server)
    ↓
fcgiwrap (CGI adapter)
    ↓
Shell Script in spells/.imps/cgi/
    ↓
Execute POSIX commands
    ↓
Generate HTML response
    ↓
htmx swaps content
```

## Key Features

### 1. **Filesystem as Database**
No SQL, no NoSQL - just files and directories. Simple, auditable, version-controllable.

### 2. **Reproducible Builds**
Delete the `build/` directory and rebuild - you'll get identical HTML every time.

### 3. **Real Shell Scripts**
Every interactive feature is a real POSIX shell script. You can:
- Use standard UNIX tools (`grep`, `awk`, `sed`)
- Pipe commands together
- Write functional, tested code

### 4. **No Hidden Complexity**
What you see is what you get:
- Markdown files → HTML pages
- Shell scripts → Interactive features
- Static files → Served as-is

### 5. **Secure by Default**
- CGI execution restricted to one directory
- File uploads isolated
- HTTPS via Let's Encrypt
- No code injection vulnerabilities from shell scripts (proper escaping)

## Why Shell Scripts?

Shell scripts are:
- **Universal** - Every UNIX system has `sh`
- **Transparent** - Easy to read and audit
- **Powerful** - Access to all system tools
- **Fast** - No runtime overhead
- **Educational** - Learn UNIX while building sites

## This Demo Site

This entire demo site is built with Wizardry Web:

- **15+ interactive demos** - All powered by shell CGI scripts
- **Multiple pages** - Navigation, content organization
- **Custom components** - Reusable card layouts
- **Real-time updates** - No page reloads needed
- **Pure shell backend** - Zero JavaScript on the server
- **Multi-room chat** - MUD-compatible chat system with `.log` files

## Get Started

```bash
# Create a new site
web-wizardry create mysite

# Edit content
vim ~/sites/mysite/site/pages/index.md

# Build
web-wizardry build mysite

# Serve
web-wizardry serve mysite
```

Visit the site at http://localhost:8080

## Technical Details

**CGI Scripts Location:** `$WIZARDRY_DIR/spells/.imps/cgi/`

**Demo Scripts:**
- `echo-text` - Echo user input
- `counter` - Increment counter
- `save-note` - Save text to file
- `random-quote` - Generate random quotes
- `calc` - Arithmetic calculator
- `system-info` - Show system stats
- `poll-vote` - Voting system
- `color-picker` - Color visualization
- `temperature-convert` - Unit conversion
- `reverse-text` - String reversal
- `word-count` - Text analysis
- `file-info` - File upload simulation
- `list-files` - Directory listing
- `chat-list-rooms` - List chat rooms
- `chat-create-room` - Create chat room
- `chat-get-messages` - Get chat messages
- `chat-send-message` - Send chat message (MUD-compatible format)
- `chat-delete-room` - Delete empty chat room

All written in pure POSIX shell!

## Source Code

Every CGI script is open source and readable. Check them out at:
`$WIZARDRY_DIR/spells/.imps/cgi/`

## Learn More

- Read the Wizardry Web documentation
- Explore the CGI scripts
- Create your own interactive features
- Share your creations!

---

<div class="info-box">
  <strong>🎓 Educational Value:</strong> This demo site serves as both a showcase and a learning tool. 
  Every interaction demonstrates practical UNIX shell scripting in a real-world context.
</div>

---

## Navigation
- [Home](/pages/index.html)
- [Advanced Demos](/pages/advanced.html)
- [Poll](/pages/poll.html)
- [Chat](/pages/chat.html)
- [About](/pages/about.html)
- [Advanced Demos](/pages/advanced.html)
- [Poll](/pages/poll.html)
