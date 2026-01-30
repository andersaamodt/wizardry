# Debugging Avatar Cleanup

If avatars aren't being cleaned up, check these log files on your server:

## 1. Check if cleanup is being called

```bash
tail -f /tmp/chat-cleanup-calls.log
```

This shows when `chat-get-messages` or `chat-send-message` tries to call cleanup.

If you see entries here, cleanup is being invoked.
If you don't see entries, the CGI scripts aren't running or aren't reaching the cleanup call.

## 2. Check what cleanup is doing

```bash
tail -f /tmp/chat-cleanup-debug.log
```

This shows:
- When cleanup script actually runs
- Which avatars it's checking
- Age of each avatar
- Whether avatars are being deleted

## Example output

`/tmp/chat-cleanup-calls.log`:
```
[2026-01-30 05:58:13] chat-get-messages: calling cleanup for /home/user/sites/.sitedata/default/chatrooms/lobby
[2026-01-30 05:58:20] chat-send-message: calling cleanup for /home/user/sites/.sitedata/default/chatrooms/lobby
```

`/tmp/chat-cleanup-debug.log`:
```
[2026-01-30 05:58:13] cleanup called: room_dir=/home/user/sites/.sitedata/default/chatrooms/lobby
[2026-01-30 05:58:13] checking .alice: age=120 threshold=1800
[2026-01-30 05:58:13] checking .bob: age=2400 threshold=1800
[2026-01-30 05:58:13] DELETING .bob (age 2400 > 1800)
```

## What to look for

**If cleanup isn't being called:**
- Check that CGI scripts are executing
- Verify wizardry is in PATH for web server
- Check web server error logs

**If cleanup is called but avatars aren't deleted:**
- Check ages in debug log - are they actually >30 minutes (1800 seconds)?
- Check if avatars are being detected as MUD avatars (they'd say "skipping")
- Verify the delete command is running (should see "DELETING" messages)

**If avatars are too young:**
- Web avatars get their last_activity updated each time user sends message
- If no last_activity attribute, falls back to directory mtime
- Check: `stat -c %Y /path/to/avatar/directory` to see actual mtime

## Testing manually

You can manually run cleanup on a room:

```bash
cd /path/to/wizardry
. spells/.imps/sys/invoke-wizardry

# Run cleanup on specific room
chat-cleanup-inactive-avatars /path/to/sites/.sitedata/default/chatrooms/ROOMNAME

# Check the debug log
cat /tmp/chat-cleanup-debug.log
```

## Disabling debug logging

Once debugging is complete, you can comment out the logging lines in:
- `spells/.imps/cgi/chat-cleanup-inactive-avatars`
- `spells/.imps/cgi/chat-get-messages`
- `spells/.imps/cgi/chat-send-message`

Or just delete the log files to stop accumulating data:
```bash
rm /tmp/chat-cleanup-calls.log /tmp/chat-cleanup-debug.log
```
