# Chat Debug Guide

This document explains how to view the extensive debug logging added to diagnose the chat message sending issue.

## **ISSUE RESOLVED**

The root cause has been identified and fixed:

**Problem**: `.sitedata` directory was owned by `site_user` (e.g., ww_site50) but nginx and fcgiwrap run as `actual_user` (the person who owns the site). CGI scripts executed by fcgiwrap couldn't write to directories they didn't own.

**Solution**: Changed `.sitedata` ownership from `site_user` to `actual_user` in `fix-site-security`.

**To apply the fix**: Run `fix-site-security <sitename>` to update ownership on your existing site.

---

## Debug Logging (Still Available)

Extensive debug logging has been added to:
- `spells/.imps/cgi/chat-send-message` - Main message sending logic
- `spells/.imps/cgi/get-site-data-dir` - Site data directory resolution

All debug output is written to **`~/testlog.txt`** to avoid interfering with daemon operation.

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

### 3. Send a Test Message

Try sending a chat message through the web interface, or try to load the chatrooms page.

### 4. View the Debug Output

```bash
# View the entire log
cat ~/testlog.txt

# Or tail it to see new messages as they arrive
tail -f ~/testlog.txt

# View just the recent entries
tail -50 ~/testlog.txt
```

## What to Look For

The debug output will show:

### Environment Variables
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
