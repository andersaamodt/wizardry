# Avatar Cleanup Implementation

## Overview

Web chat avatars are automatically cleaned up after 30 minutes of inactivity. This ensures inactive users don't clutter the members list.

## How It Works

### 1. Activity Tracking

Each time a user sends a message, their activity is tracked:

```sh
# In chat-send-message
current_timestamp=$(date +%s)
printf '%s\n' "$current_timestamp" > "$ROOM_DIR/.$user_name/.last_activity"
```

**Why not use `touch`?**
- Using `touch` to update directory mtime triggers filesystem watchers
- Can cause side effects in systems monitoring file changes
- Using a hidden file (`.last_activity`) avoids these issues

### 2. Web Avatar Marking

Web avatars are distinguished from MUD avatars using a marker file:

```sh
# Created when avatar is first created
touch "$avatar_path/.web_avatar"
```

**Why not use extended attributes (xattr)?**
- Xattr not reliably supported across all filesystems
- File-based marker is more portable
- Works on NFS, tmpfs, and other filesystems without xattr support

### 3. Cleanup Process

Cleanup runs **after each message is sent** (not during reads):

```sh
# In chat-send-message, after successful message write
chat-cleanup-inactive-avatars "$ROOM_DIR"
```

The cleanup script:
1. Iterates through all avatar directories
2. Checks for `.web_avatar` marker (MUD avatars skipped)
3. Reads timestamp from `.last_activity` file
4. Falls back to directory mtime if no timestamp file
5. Deletes avatar if inactive for >30 minutes (1800 seconds)

## Avatar Directory Structure

```
.sitedata/default/chatrooms/roomname/
├── .log                    # Message log (file)
├── .alice/                 # Web avatar
│   ├── .web_avatar        # Marker: this is a web avatar
│   ├── .last_activity     # Timestamp: unix epoch seconds
│   └── ...               # Avatar stats/attributes
└── .bob/                   # MUD avatar (no cleanup)
    ├── max_life
    ├── max_mana
    └── ...
```

## Key Design Decisions

### Why cleanup on write (message send) instead of read (list avatars)?

**Previous approach (buggy):**
```sh
# chat-list-avatars (OLD - WRONG)
# 1. Run cleanup (delete old avatars)
# 2. List remaining avatars
```

Problems:
- Cleanup ran every 2 seconds (polling frequency)
- Read operation shouldn't mutate state
- Created timing bug where avatars deleted before being listed

**Current approach (correct):**
```sh
# chat-send-message
# 1. Send message
# 2. Update activity timestamp
# 3. Run cleanup
```

Benefits:
- Cleanup runs less frequently (only on writes)
- Separates read and write concerns
- Activity tracking happens atomically with message send

### Why 30 minutes?

This balances two concerns:
1. **User experience:** Users who step away briefly aren't removed
2. **Accuracy:** Inactive users don't clutter the members list indefinitely

If a user is viewing the chat but not sending messages:
- They'll appear in the list for 30 minutes after their last message
- After 30 minutes, their avatar is removed
- They can rejoin by sending another message

### MUD vs Web Avatars

**MUD avatars:**
- Created through the MUD interface
- Have persistent state (stats, inventory, etc.)
- NOT automatically cleaned up
- Managed through MUD commands (quit, logout, etc.)

**Web avatars:**
- Created through the web chat interface
- Minimal state (just username)
- Automatically cleaned up after 30 min inactivity
- Marked with `.web_avatar` file

## Testing

Comprehensive test suite covers:
1. Recent avatars are preserved
2. Old avatars (>30 min) are deleted
3. MUD avatars are never deleted
4. Boundary case (exactly 30 min) is preserved
5. Mixed avatar types handled correctly
6. Fallback to directory mtime works

Run tests:
```sh
sh .tests/.imps/cgi/test-chat-cleanup-inactive-avatars.sh
```

## Future Enhancements

### Option 1: Separate cron job
Move cleanup to a periodic cron job instead of message-triggered:
- Pro: Completely decouples cleanup from message sending
- Con: Requires external scheduling
- Con: Cleanup happens less predictably

### Option 2: Session-based tracking
Track sessions instead of message timestamps:
- Pro: More accurate activity detection
- Con: Requires session management infrastructure
- Con: More complex implementation

### Option 3: Configurable threshold
Make the 30-minute threshold configurable:
- Add CHAT_INACTIVE_THRESHOLD environment variable
- Default to 1800 seconds
- Allow per-site customization

## Troubleshooting

### Avatars not being deleted

Check:
1. Does avatar have `.web_avatar` marker file?
2. Does avatar have `.last_activity` timestamp file?
3. Is timestamp more than 30 minutes old?
4. Is cleanup being called after message send?

Debug:
```sh
# Check avatar directory contents
ls -la /path/to/chatrooms/roomname/.username/

# Check timestamp
cat /path/to/chatrooms/roomname/.username/.last_activity

# Calculate age
current=$(date +%s)
last=$(cat .last_activity)
echo "Age: $((current - last)) seconds"
```

### Avatars deleted too quickly

- Verify timestamp is being updated on message send
- Check for filesystem time sync issues
- Ensure `.last_activity` file is being written correctly

### MUD avatars being deleted

- Verify MUD avatars don't have `.web_avatar` marker
- Check cleanup script logic for web avatar detection
