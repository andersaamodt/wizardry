# How to Debug Chat Members List Issue

## 1. Check the Actual JSON Response

### In Chrome/Edge DevTools:
1. Open DevTools (F12)
2. Go to **Network** tab
3. Filter by "XHR" or "Fetch"
4. Join a chatroom or refresh the page
5. Look for request to `/cgi/chat-list-avatars?room=ROOMNAME`
6. Click on that request
7. Go to **Response** tab to see the actual JSON

### In Firefox DevTools:
1. Open DevTools (F12)
2. Go to **Network** tab
3. Filter by "XHR"
4. Join a chatroom or refresh the page
5. Look for request to `/cgi/chat-list-avatars?room=ROOMNAME`
6. Click on that request
7. Go to **Response** tab

### What to Look For:

**If working correctly, you should see:**
```json
{
  "avatars": [
    {"username": "alice", "is_web": true},
    {"username": "bob", "is_web": false}
  ]
}
```

**If broken, you might see:**
```json
{
  "avatars": []
}
```
or
```json
{
  "error": "Room not found"
}
```

## 2. Use the Debug Script

Temporarily replace `chat-list-avatars` with `chat-list-avatars-debug`:

In your chat.md file, change line 414:
```javascript
// OLD:
fetch('/cgi/chat-list-avatars?room=' + encodeURIComponent(window.currentRoom))

// NEW (temporary):
fetch('/cgi/chat-list-avatars-debug?room=' + encodeURIComponent(window.currentRoom))
```

The debug version includes extra information:
```json
{
  "avatars": [...],
  "debug": {
    "room_dir": "/path/to/room",
    "files_in_room": {".alice": "dir", ".bob": "dir", ".log": "file"},
    "avatar_count": 2,
    "skipped_count": 3,
    "skipped_items": [".", "..", ".log"]
  }
}
```

## 3. Check Avatar Folders on Server

SSH to the server and run:

```bash
# Find where chatrooms are stored
cd ~/sites/.sitedata/default/chatrooms

# Or if using WIZARDRY_SITES_DIR:
cd $WIZARDRY_SITES_DIR/.sitedata/default/chatrooms

# List rooms
ls -la

# Check a specific room
ls -la ROOMNAME/

# You should see directories like:
# drwxr-xr-x .alice
# drwxr-xr-x .bob
# -rw-r--r-- .log
```

## 4. Common Issues and Solutions

### Issue: `avatars` array is empty but folders exist

**Possible causes:**
1. Avatar folders are NOT named with leading dot (`.username`)
2. Folders are not actually directories (check with `ls -la`)
3. The glob pattern `"$ROOM_DIR"/.*` is not matching
4. All avatars are being filtered by the case statement

**Solution:**
- Check folder names start with `.` (dot)
- Check they are directories, not files
- Use the debug script to see what's being detected

### Issue: "Room not found" error

**Possible causes:**
1. Wrong room name in URL
2. Room directory doesn't exist
3. Path construction is wrong (SITES_DIR or CHAT_DIR)

**Solution:**
- Check the `room_dir` in debug output
- Verify the directory exists at that path
- Check WIZARDRY_SITES_DIR environment variable

### Issue: Member count shows correctly but list is empty

**This is the current bug!** The button logic uses `chat-count-avatars` which works, but `chat-list-avatars` returns empty or errors.

**Solution:**
- Check the actual JSON response body (step 1 above)
- Compare with `chat-count-avatars` response
- Use debug script to see what's different

## 5. Quick Test Command

Run this on the server to test the CGI script directly:

```bash
cd /path/to/wizardry
. spells/.imps/sys/invoke-wizardry

# Test chat-list-avatars
export QUERY_STRING="room=ROOMNAME"
spells/.imps/cgi/chat-list-avatars

# Test debug version
spells/.imps/cgi/chat-list-avatars-debug

# Test chat-count-avatars
spells/.imps/cgi/chat-count-avatars
```

Expected output should include JSON after the HTTP headers.
