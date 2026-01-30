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
- When cleanup script runs
- Which avatars are found
- Type detection (web vs MUD avatar)
- Timestamp source (attribute vs mtime)
- Age calculation
- Whether avatars are deleted or kept

## Example output

`/tmp/chat-cleanup-calls.log`:
```
[2026-01-30 05:58:13] chat-get-messages: calling cleanup for /home/user/sites/.sitedata/default/chatrooms/lobby
[2026-01-30 05:58:20] chat-send-message: calling cleanup for /home/user/sites/.sitedata/default/chatrooms/lobby
```

`/tmp/chat-cleanup-debug.log`:
```
[2026-01-30 06:05:55] cleanup called: room_dir=/path/to/chatrooms/lobby
[2026-01-30 06:05:55] cleanup: room exists, starting scan
[2026-01-30 06:05:55] found avatar .alice
[2026-01-30 06:05:55] .alice: no is_avatar attribute (web avatar)
[2026-01-30 06:05:55] .alice: using mtime=1769753155
[2026-01-30 06:05:55] checking .alice: age=120 threshold=1800
[2026-01-30 06:05:55] keeping .alice (age 120 <= 1800)
[2026-01-30 06:05:55] found avatar .bob
[2026-01-30 06:05:55] .bob: no is_avatar attribute (web avatar)
[2026-01-30 06:05:55] .bob: using mtime=1769751355
[2026-01-30 06:05:55] checking .bob: age=2400 threshold=1800
[2026-01-30 06:05:55] DELETING .bob (age 2400 > 1800)
[2026-01-30 06:05:55] cleanup complete: processed 2 avatars
```

## What to look for

**If cleanup shows "cleanup called" but no "starting scan":**
- The room directory path is invalid or missing
- Should see "cleanup exit: room_dir empty or missing" message

**If cleanup shows "starting scan" but no avatars found:**
- No avatar directories exist in the room (check `ls -la /path/to/room/`)
- All avatars were skipped (dots, .log, etc.)

**If avatars found but not deleted:**
- Check the age - must be >1800 seconds (30 minutes)
- Check if detected as MUD avatar (has is_avatar attribute)
- Recent avatars shown as "keeping" (age <= threshold)

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
cat /tmp/chat-cleanup-debug.log | tail -20
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
