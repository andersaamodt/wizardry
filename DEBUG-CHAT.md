# Chat Debug Guide

This document explains how to view the extensive debug logging added to diagnose chat issues, including the **reconnecting spinner issue**.

## **CURRENT ISSUE: Secondary SSE Stream Failures**

The secondary SSE streams (chat-room-list-stream and chat-unread-counts) are failing to connect, while the main message stream works fine.

**Symptoms:**
- Firefox shows "can't establish a connection to the server" for these endpoints
- Error messages in F12 console but no detailed diagnostics

**The fix:**
- Added comprehensive debug logging to both server scripts (chat-room-list-stream and chat-unread-counts)
- Enhanced client error handlers with detailed state logging
- All logging follows the same pattern as the main message stream

**What to check:**
- Look for `[ROOM-LIST-STREAM DEBUG]` and `[UNREAD-COUNTS DEBUG]` in ~/testlog.txt
- Look for `[ROOM LIST DEBUG]` and `[UNREAD COUNTS DEBUG]` in F12 console
- Check if WIZARDRY_SITE_NAME and WIZARDRY_SITES_DIR are set correctly
- Verify get-site-data-dir is working properly

---

## **PREVIOUS ISSUE: Reconnecting Spinner (RESOLVED)**

The reconnecting spinner stopped appearing when the server connection is lost. This PR adds extensive debug logging to both client and server to diagnose and fix the issue.

**What was wrong:**
- EventSource error handler only showed "reconnecting" status when `readyState === CLOSED` or under specific CONNECTING conditions
- This meant errors weren't giving immediate visual feedback to users

**The fix:**
- EventSource error handler now shows "reconnecting" status **immediately on ANY error** (before checking readyState)
- Only skips showing reconnecting if we've already exceeded max reconnection attempts

---

## **PREVIOUS ISSUE: Message Sending (RESOLVED)**

The root cause has been identified and fixed:

**Problem**: `.sitedata` directory was owned by `site_user` (e.g., ww_site50) but nginx and fcgiwrap run as `actual_user` (the person who owns the site). CGI scripts executed by fcgiwrap couldn't write to directories they didn't own.

**Solution**: Changed `.sitedata` ownership from `site_user` to `actual_user` in `fix-site-security`.

**To apply the fix**: Run `fix-site-security <sitename>` to update ownership on your existing site.

---

## Debug Logging (Client and Server)

Extensive debug logging has been added to:

### Server-side (writes to ~/testlog.txt):
- `spells/.imps/cgi/chat-stream` - SSE connection setup, room validation, path resolution, cleanup
- `spells/.imps/cgi/chat-room-list-stream` - Room list monitoring, environment vars, path resolution
- `spells/.imps/cgi/chat-unread-counts` - Unread count monitoring, username validation, path resolution
- `spells/.imps/cgi/chat-send-message` - Main message sending logic
- `spells/.imps/cgi/get-site-data-dir` - Site data directory resolution

### Client-side (writes to F12 browser console):
- `.templates/demo/pages/chat.md` - All connection state transitions, error events, reconnection attempts

All debug output:
- **Server**: Written to **`~/testlog.txt`** (safe logging with `|| true` to avoid breaking under set -eu)
- **Client**: Written to browser F12 console with `[DEBUG]` prefix for easy filtering

## How to View Debug Output

### 1. Restart the Site

After pulling the latest changes with debug logging, restart your site daemon:

```bash
# Stop the site
stop-site <sitename>

# Start it again
serve-site <sitename>
```

Or use the site menu to restart.

### 2. Clear the Log (Optional)

To make it easier to see only the new debug output:

```bash
# Clear the log before testing
> ~/testlog.txt
```

### 3. Test Reconnection Behavior

**To test the reconnecting spinner fix:**

1. Open the chat page and join a room
2. Open the browser's F12 Developer Tools (Console tab)
3. Stop the site server (to simulate connection loss):
   ```bash
   stop-site <sitename>
   ```
4. Watch the browser console - you should see:
   ```
   [SSE DEBUG] ========== ERROR EVENT ==========
   [SSE DEBUG] Error occurred: ...
   [CONNECTION DEBUG] updateConnectionStatus called
   [CONNECTION DEBUG] - status: reconnecting
   ```
5. Watch the UI - the "Reconnecting" spinner should appear **immediately**
6. The spinner will try to reconnect up to max attempts (default 5)
7. After max attempts, it will show "Disconnected" (hover to see "Retry")
8. Click "Retry" to manually reconnect
9. Start the server again:
   ```bash
   serve-site <sitename>
   ```
10. The connection should re-establish and show "Connected" (then fade away)

### 4. Test Secondary SSE Streams

**To test the room-list and unread-counts streams:**

1. Open the chat page
2. Open the browser's F12 Developer Tools (Console tab)
3. Look for these startup messages:
   ```
   [ROOM LIST DEBUG] ========== SETUP STREAM ==========
   [ROOM LIST DEBUG] Creating EventSource
   [ROOM LIST DEBUG] EventSource created
   [UNREAD COUNTS DEBUG] ========== SETUP STREAM ==========
   [UNREAD COUNTS DEBUG] Creating EventSource
   [UNREAD COUNTS DEBUG] EventSource created
   ```
4. Check for successful connection:
   ```
   [ROOM LIST DEBUG] ========== CONNECTION OPEN ==========
   [ROOM LIST DEBUG] Connected successfully
   [UNREAD COUNTS DEBUG] ========== CONNECTION OPEN ==========
   [UNREAD COUNTS DEBUG] Connected successfully
   ```
5. If you see errors instead, check ~/testlog.txt for server-side issues:
   ```bash
   grep "ROOM-LIST-STREAM DEBUG\|UNREAD-COUNTS DEBUG" ~/testlog.txt
   ```
6. Common issues to check in server logs:
   - WIZARDRY_SITE_NAME or WIZARDRY_SITES_DIR showing as "UNSET"
   - CHAT_DIR failing to resolve
   - Permission errors on chatrooms directory

### 5. Send a Test Message

Try sending a chat message through the web interface, or try to load the chatrooms page.

### 4. View the Debug Output

#### Client-side (F12 Console):

Open the browser's Developer Tools (F12) and go to the Console tab. You can filter messages:

```
Filter by: DEBUG      (shows all debug messages)
Filter by: SSE DEBUG  (shows SSE connection messages)
Filter by: CONNECTION DEBUG (shows connection status changes)
Filter by: RECONNECT DEBUG (shows reconnection attempts)
Filter by: HEARTBEAT DEBUG (shows heartbeat timeouts)
```

The console will show real-time logging of all connection events.

#### Server-side (~/testlog.txt):

```bash
# View the entire log
cat ~/testlog.txt

# Or tail it to see new messages as they arrive
tail -f ~/testlog.txt

# View just the recent entries
tail -50 ~/testlog.txt

# Filter for specific debug categories
grep "CHAT-STREAM DEBUG" ~/testlog.txt
grep "CONNECTION" ~/testlog.txt
```

## What to Look For

### Reconnection Debug Output (Client-side, F12 Console)

When testing the reconnecting spinner, look for these patterns:

#### On Connection Loss:
```
[SSE DEBUG] ========== ERROR EVENT ==========
[SSE DEBUG] Error occurred: Event {...}
[SSE DEBUG] - ReadyState: 2 (CLOSED) or 0 (CONNECTING)
[SSE DEBUG] Showing reconnecting status immediately (before checking readyState)
[CONNECTION DEBUG] updateConnectionStatus called
[CONNECTION DEBUG] - status: reconnecting
[CONNECTION DEBUG] Showing "reconnecting" status
```

#### On Reconnection Attempts:
```
[SSE DEBUG] Reconnect attempt X of 5
[SSE DEBUG] Scheduling reconnection in 2 seconds
[RECONNECT DEBUG] ========== MANUAL RECONNECTION ==========
[SETUP DEBUG] ========== SETUP MESSAGE STREAM ==========
[SETUP DEBUG] Creating EventSource with URL: /cgi/chat-stream?room=...
```

#### On Successful Reconnection:
```
[SSE DEBUG] Connection OPEN event fired
[CONNECTION DEBUG] - status: connected
```

#### On Max Attempts Reached:
```
[SSE DEBUG] Max reconnection attempts reached - showing lost status
[CONNECTION DEBUG] - status: lost
[CONNECTION DEBUG] Showing "lost" (Disconnected/Retry) status
```

### Server Debug Output (~/testlog.txt)

The debug output will show:

#### SSE Connection Establishment (Main Message Stream)
```
[CHAT-STREAM DEBUG] ========== NEW CONNECTION ==========
[CHAT-STREAM DEBUG] Timestamp: 2026-02-07 02:30:00
[CHAT-STREAM DEBUG] QUERY_STRING: room=General&since=2026-02-07+02:30:00
[CHAT-STREAM DEBUG] WIZARDRY_SITE_NAME=demo-site
[CHAT-STREAM DEBUG] WIZARDRY_SITES_DIR=/path/to/sites
[CHAT-STREAM DEBUG] Parsed parameters:
[CHAT-STREAM DEBUG] - room: General
[CHAT-STREAM DEBUG] - since_timestamp: 2026-02-07 02:30:00
[CHAT-STREAM DEBUG] Paths resolved:
[CHAT-STREAM DEBUG] - CHAT_DIR: /path/to/.sitedata/chatrooms
[CHAT-STREAM DEBUG] - ROOM_DIR: /path/to/.sitedata/chatrooms/General
[CHAT-STREAM DEBUG] - LOG_FILE: /path/to/.sitedata/chatrooms/General/.log
[CHAT-STREAM DEBUG] tail process started with PID: 12345
[CHAT-STREAM DEBUG] Entering event loop
```

#### Room List Stream Establishment
```
[ROOM-LIST-STREAM DEBUG] ========== NEW CONNECTION ==========
[ROOM-LIST-STREAM DEBUG] Timestamp: 2026-02-07 02:30:01
[ROOM-LIST-STREAM DEBUG] QUERY_STRING: 
[ROOM-LIST-STREAM DEBUG] WIZARDRY_SITE_NAME=demo-site
[ROOM-LIST-STREAM DEBUG] WIZARDRY_SITES_DIR=/path/to/sites
[ROOM-LIST-STREAM DEBUG] Headers and padding sent
[ROOM-LIST-STREAM DEBUG] CHAT_DIR resolved to: /path/to/.sitedata/chatrooms
[ROOM-LIST-STREAM DEBUG] Directory created/verified
[ROOM-LIST-STREAM DEBUG] Getting initial room list
[ROOM-LIST-STREAM DEBUG] Initial rooms: ["General","Esoterica","Marginalia"]
[ROOM-LIST-STREAM DEBUG] Initial event sent, entering monitoring loop
```

#### Unread Counts Stream Establishment
```
[UNREAD-COUNTS DEBUG] ========== NEW CONNECTION ==========
[UNREAD-COUNTS DEBUG] Timestamp: 2026-02-07 02:30:01
[UNREAD-COUNTS DEBUG] QUERY_STRING: username=Guest903
[UNREAD-COUNTS DEBUG] WIZARDRY_SITE_NAME=demo-site
[UNREAD-COUNTS DEBUG] WIZARDRY_SITES_DIR=/path/to/sites
[UNREAD-COUNTS DEBUG] Headers and padding sent
[UNREAD-COUNTS DEBUG] CHAT_DIR resolved to: /path/to/.sitedata/chatrooms
[UNREAD-COUNTS DEBUG] Directory created/verified
[UNREAD-COUNTS DEBUG] Username: Guest903
[UNREAD-COUNTS DEBUG] Username validated
[UNREAD-COUNTS DEBUG] Getting initial counts
[UNREAD-COUNTS DEBUG] Initial counts: {"General":5,"Marginalia":21}
[UNREAD-COUNTS DEBUG] Initial event sent, entering monitoring loop
```

### SSE Connection Establishment
```

### SSE Connection Cleanup
```
[CHAT-STREAM DEBUG] Cleanup called
[CHAT-STREAM DEBUG] - Reason: connection closed or error
[CHAT-STREAM DEBUG] ========== CONNECTION CLOSED ==========
```

### Environment Variables (for message sending)
```
[DEBUG] WIZARDRY_SITE_NAME=<sitename>
[DEBUG] WIZARDRY_SITES_DIR=<path>
[DEBUG] WIZARDRY_DIR=<path>
```

**If these are "UNSET"**, that's the problem! fcgiwrap isn't receiving the environment variables.

### Directory Path Resolution
```
[DEBUG get-site-data-dir] Returning path: <full-path>
[DEBUG] CHAT_DIR=<path>
[DEBUG] ROOM_DIR=<path>
[DEBUG] LOG_FILE=<path>
```

Shows the exact paths being used. If the path is wrong, you'll see it here.

### POST Data
```
[DEBUG] POST data received (length: 42)
[DEBUG] room_name=<room>
[DEBUG] user_name=<user>
[DEBUG] message=<message>
```

Shows what data was received from the client.

### Write Attempt
```
[DEBUG] Attempting write...
[DEBUG] Write succeeded
```

Shows whether the write operation completed.

## Common Issues to Diagnose

1. **Environment variables not set**: fcgiwrap isn't receiving WIZARDRY_SITE_NAME/WIZARDRY_SITES_DIR
2. **Wrong path**: get-site-data-dir is using defaults instead of actual site config
3. **Directory missing**: Room directory doesn't exist
4. **Write fails**: Permission or ownership issue (should be fixed now)

## Example Complete Debug Session

```bash
# 1. Clear log
> ~/testlog.txt

# 2. Try to load chatrooms or send a test message via web UI

# 3. View output
cat ~/testlog.txt
```

This will show all debug output, making it easy to trace the execution flow and identify exactly where the problem occurs.

## After Debugging

Once we identify the issue from the debug output, we can:
1. Fix the root cause
2. Remove the debug logging (or make it conditional)
3. Verify the fix works

The debug output should make it immediately obvious what's wrong!
