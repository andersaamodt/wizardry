# Chat Debug Guide

This document explains how to view the extensive debug logging added to diagnose the chat message sending issue.

## Debug Logging Added

Extensive debug logging has been added to:
- `spells/.imps/cgi/chat-send-message` - Main message sending logic
- `spells/.imps/cgi/get-site-data-dir` - Site data directory resolution

All debug output is sent to **stderr** which nginx captures in the error log.

## How to View Debug Output

### 1. Find Your Site's Error Log

The nginx error log is located at:
```
$HOME/sites/<sitename>/nginx/error.log
```

For example, if your site is called "mysite":
```
$HOME/sites/mysite/nginx/error.log
```

### 2. Restart the Site

After pulling the latest changes with debug logging, restart your site daemon:

```bash
# Stop the site
stop-site <sitename>

# Start it again
serve-site <sitename>
```

Or use the site menu to restart.

### 3. Clear the Error Log (Optional)

To make it easier to see only the new debug output:

```bash
# Clear the log before testing
> $HOME/sites/<sitename>/nginx/error.log
```

### 4. Send a Test Message

Try sending a chat message through the web interface.

### 5. View the Debug Output

```bash
# View the entire log
cat $HOME/sites/<sitename>/nginx/error.log

# Or tail it to see new messages as they arrive
tail -f $HOME/sites/<sitename>/nginx/error.log
```

## What to Look For

The debug output will show:

### Environment Variables
```
[DEBUG chat-send-message] WIZARDRY_SITE_NAME=<sitename>
[DEBUG chat-send-message] WIZARDRY_SITES_DIR=<path>
[DEBUG chat-send-message] WIZARDRY_DIR=<path>
```

**If these are "UNSET"**, that's the problem! fcgiwrap isn't receiving the environment variables.

### POST Data
```
[DEBUG chat-send-message] POST data received: room=<room>&user=<user>&msg=<message>
```

Shows what data was received from the client.

### Path Resolution
```
[DEBUG get-site-data-dir] Returning path: <full-path>
[DEBUG chat-send-message] CHAT_DIR=<path>
[DEBUG chat-send-message] ROOM_DIR=<path>
[DEBUG chat-send-message] LOG_FILE=<path>
```

Shows the exact paths being used. If the path is wrong, you'll see it here.

### File Permissions
```
[DEBUG chat-send-message] LOG_FILE permissions: -rw-rw-r-- ...
[DEBUG chat-send-message] LOG_FILE write check passed
```

Shows if the log file has the correct permissions (should be 664).

### Write Attempt
```
[DEBUG chat-send-message] Attempting to write to log file...
[DEBUG chat-send-message] Write command exit status: 0
[DEBUG chat-send-message] SUCCESS: Message found in log file
```

Shows whether the write succeeded and if the message actually appeared in the file.

## Common Issues to Diagnose

1. **Environment variables not set**: fcgiwrap isn't receiving WIZARDRY_SITE_NAME/WIZARDRY_SITES_DIR
2. **Wrong path**: get-site-data-dir is using defaults instead of actual site config
3. **Permissions**: Log file exists but isn't writable (should be 664, not 644)
4. **Directory missing**: Room directory doesn't exist
5. **Write succeeds but message not in file**: Buffering or filesystem issue

## Example Complete Debug Session

```bash
# 1. Clear log
> ~/sites/mysite/nginx/error.log

# 2. Send a test message via web UI

# 3. View output
cat ~/sites/mysite/nginx/error.log | grep DEBUG
```

This will show all debug lines in order, making it easy to trace the execution flow and identify exactly where the problem occurs.

## After Debugging

Once we identify the issue from the debug output, we can:
1. Fix the root cause
2. Remove the debug logging (or make it conditional)
3. Verify the fix works

The debug output should make it immediately obvious what's wrong!
