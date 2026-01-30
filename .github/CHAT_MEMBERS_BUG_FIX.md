# Chat Members List Bug - Root Cause and Fix

## The Bug

Members list showed empty (and count showed "0") even though:
- Avatar folders existed on the server
- Delete/Members button toggled correctly (indicating count was working)
- The bug appeared in old commits that previously worked

## Root Cause

The bug was in `chat-list-avatars` lines 37-65 - an auto-cleanup feature that:
1. Ran **every time** the member list was loaded (every 2 seconds!)
2. Checked avatar directory modification time
3. Deleted any avatar directory older than 30 minutes

### Why This Caused the Bug

```javascript
// Browser calls this every 2 seconds:
function loadMembers() {
  fetch('/cgi/chat-list-avatars?room=' + room)  // ← Cleanup runs HERE
    .then(data => {
      // data.avatars is empty because cleanup deleted them!
      memberCount.textContent = data.avatars.length;  // Shows "0"
    })
}
```

**Timeline:**
1. User joins chatroom, sends first message
2. Avatar directory created at timestamp T
3. User stays in room but doesn't send more messages
4. 30+ minutes pass (directory timestamp is now old)
5. Browser calls `loadMembers()` → `chat-list-avatars` runs
6. Cleanup checks: "directory is >30 min old" → **DELETES avatar**
7. Listing code finds no avatars → returns empty array
8. Member count shows "0", list is empty

**But why did delete button work?**
- `updateDeleteButton()` calls `chat-count-avatars` (different script)
- `chat-count-avatars` has NO cleanup code
- It counts avatars BEFORE they're deleted
- So button visibility was correct, but list was wrong!

### Why Old Commits Showed Same Bug

This was the KEY insight - even commits from when the feature worked showed the bug now!

**Explanation:** It's a **time-based bug**, not a code bug:
- Old commits worked when tested immediately after commit (avatars were fresh)
- Testing old commits NOW means avatars are >30 minutes old
- Cleanup deletes them regardless of what commit is checked out
- Bug appears in all commits once enough time passes!

## The Fix

### 1. Removed Cleanup from chat-list-avatars

Listing avatars is a **read operation** and should NOT mutate state.

**Before:**
```sh
# Auto-cleanup: Remove inactive web avatars (30 minutes)
for avatar_dir in "$ROOM_DIR"/.*; do
  # ... check timestamp ...
  if [ "$time_diff" -gt "$inactive_threshold" ]; then
    rm -rf "$avatar_dir"  # ← Deletes during read!
  fi
done

# Then list remaining avatars
printf '{"avatars": ['
```

**After:**
```sh
# List all avatars (no cleanup)
printf '{"avatars": ['
```

### 2. Updated chat-send-message

Now touches avatar directory on each message to keep it fresh:

```sh
if [ ! -d "$ROOM_DIR/.$user_name" ]; then
  # Create avatar
  avatar_path=$(create-avatar "$user_name" "$ROOM_DIR")
else
  # Update timestamp to prevent future cleanup (if we add it back)
  touch "$ROOM_DIR/.$user_name"
fi
```

## Alternative Solutions Considered

### Option 1: Fix the cleanup logic
- Update timestamp when messages sent ✓ (implemented)
- Update timestamp when room is viewed (complex)
- Use message log to track activity (expensive)
**Rejected:** Still doing cleanup during read operation

### Option 2: Move cleanup to separate cron job
- Run cleanup once per hour/day via cron
- Separate maintenance from read operations
**Rejected:** Adds complexity, cleanup may not be needed at all

### Option 3: Remove cleanup entirely ✓ (chosen)
- Avatars are small (just directories)
- Disk space not a concern
- Let admins clean up manually if needed
**Chosen:** Simplest, most reliable solution

## Testing

Created comprehensive test that verifies old avatars are still listed:

```sh
test_list_avatars_old_avatar_still_shown() {
  # Create avatar with timestamp from year 2020
  touch -t 202001010000 "$avatar_dir"
  
  # Should still be listed
  output=$(chat-list-avatars)
  # ✓ Avatar appears in list
}
```

All 7 tests pass, including the new test for old avatars.

## Impact

**Before fix:**
- Members list empty after 30 minutes
- Count shows "0"
- Delete button works (confusing!)
- Bug appears in old commits (time-based)

**After fix:**
- Members list always shows all avatars
- Count is correct
- All buttons work correctly
- Bug gone from all commits (past and present)

## Future Considerations

If cleanup is needed in the future:
1. Create a separate maintenance script (not called during reads)
2. Run via cron (e.g., once per day)
3. Track last activity time properly (not just directory mtime)
4. Consider using session-based tracking instead of filesystem timestamps
