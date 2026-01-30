# Avatar Cleanup Implementation

## Overview

Web chat avatars are automatically cleaned up after 30 minutes of inactivity. This ensures inactive users don't clutter the members list.

## How It Works

### 1. Activity Tracking (using enchant)

Each time a user sends a message, their activity is tracked using extended attributes:

```sh
# In chat-send-message
current_timestamp=$(date +%s)
enchant "$ROOM_DIR/.$user_name" "last_activity=$current_timestamp"
```

**Why enchant (xattr)?**
- Native wizardry spell for extended attributes
- No extra files created
- Attributes stored in filesystem metadata
- Fallback to directory mtime when xattr not available

### 2. Web Avatar Marking (using enchant)

Web avatars are distinguished from MUD avatars using extended attributes:

```sh
# Created when avatar is first created
enchant "$avatar_path" "web_avatar=1"
```

**Distinction:**
- Web avatars: Have `web_avatar=1` attribute
- MUD avatars: Have `is_avatar=1` attribute (set by create-avatar)
- Detection fallback: If no attributes, treat as web avatar (cleanup eligible)

### 3. Cleanup Process

Cleanup runs on:
- **Page view** (chat-get-messages) - ensures cleanup when visiting room
- **Message send** (chat-send-message) - cleanup on activity

The cleanup script (`chat-cleanup-inactive-avatars`):
1. Iterates through all avatar directories
2. Checks for web avatar markers using `read-magic`
3. Falls back to checking for MUD avatar markers
4. Reads timestamp from `last_activity` attribute using `read-magic`
5. Falls back to directory mtime if no timestamp attribute
6. Deletes avatar if inactive for >30 minutes (1800 seconds)

## Avatar Directory Structure

```
.sitedata/default/chatrooms/roomname/
├── .log                    # Message log (file)
├── .alice/                 # Web avatar
│   └── (xattr: web_avatar=1, last_activity=1738127400)
└── .bob/                   # MUD avatar (no cleanup)
    └── (xattr: is_avatar=1, max_life=100, max_mana=100, ...)
```

**No extra files!** All tracking is done via extended attributes.

## Extended Attributes Used

- `web_avatar=1` - Marks avatar as web avatar (eligible for cleanup)
- `last_activity=<timestamp>` - Unix epoch timestamp of last activity
- `is_avatar=1` - Marks avatar as MUD avatar (NOT eligible for cleanup)

## Key Design Decisions

### Why cleanup on both read and write?

**Page view (chat-get-messages):**
- Ensures cleanup happens even when user just views (doesn't send messages)
- User's concern: "avatars still exist from earlier today even after visiting"
- Solution: Run cleanup when room is viewed

**Message send (chat-send-message):**
- Also update activity timestamp and run cleanup
- Ensures cleanup happens during active use

### Why enchant/read-magic instead of files?

**Previous approach (files):**
```sh
# Created .last_activity and .web_avatar files
echo "$timestamp" > "$avatar_dir/.last_activity"
touch "$avatar_dir/.web_avatar"
```

Problems:
- Clutters avatar directories with metadata files
- User complaint: "Too many files"

**Current approach (xattr):**
```sh
# Use native wizardry spells
enchant "$avatar_dir" "last_activity=$timestamp"
enchant "$avatar_dir" "web_avatar=1"
```

Benefits:
- No extra files
- Native wizardry integration
- Filesystem metadata (cleaner)
- Fallback to mtime when xattr not supported

### Fallback Strategy

When extended attributes aren't available (no xattr tools):
1. `enchant` fails silently (|| true)
2. Cleanup uses directory mtime instead of `last_activity` attribute
3. Web avatar detection falls back to checking for absence of `is_avatar`

This ensures the system works even on filesystems without xattr support.

### 30-Minute Threshold

Balances two concerns:
1. **User experience:** Users who step away briefly aren't removed
2. **Accuracy:** Inactive users don't clutter the members list indefinitely

## Testing

Comprehensive test suite covers:
1. Recent avatars are preserved
2. Old avatars (>30 min) are deleted  
3. MUD avatars are never deleted
4. Boundary case (exactly 30 min) is preserved
5. Mixed avatar types handled correctly
6. Fallback to directory mtime works (when xattr unavailable)

Run tests:
```sh
sh .tests/.imps/cgi/test-chat-cleanup-inactive-avatars.sh
```

All 6 tests pass, including in environments without xattr support.

## Troubleshooting

### Avatars not being deleted after visiting page

Check:
1. Is chat-get-messages being called when viewing room?
2. Does avatar have old directory mtime (>30 min)?
3. Is cleanup script being called?

Debug:
```sh
# Check avatar attributes
read-magic /path/to/avatar web_avatar
read-magic /path/to/avatar last_activity
read-magic /path/to/avatar is_avatar

# Check directory mtime
stat -c %Y /path/to/avatar

# Manually run cleanup
chat-cleanup-inactive-avatars /path/to/chatrooms/roomname
```

### Avatars deleted too quickly

- Verify timestamp is being updated on message send
- Check for filesystem time sync issues
- Ensure enchant is working (check for xattr tools)

### MUD avatars being deleted

- Verify MUD avatars have `is_avatar=1` attribute
- Check cleanup detection logic
- MUD avatars created via create-avatar should be safe
