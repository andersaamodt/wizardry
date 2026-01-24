# MUD Multiplayer Proof-of-Concept

This directory contains spells and documentation for the Wizardry MUD multiplayer system.

## Overview

Wizardry multiplayer is a shared-filesystem MUD where all game state lives in files and extended attributes (xattrs). There is no central server or daemon - multiplayer emerges from shared filesystem access via sshfs.

## Core Concepts

- **Rooms**: Directories that players can `cd` into
- **Items**: Files in directories
- **Attributes**: Extended attributes (xattrs) on files and directories
- **Communication**: `.room.log` files that players append to
- **Presence**: Explicit filesystem state (avatar location, etc.)
- **Actions**: Direct filesystem mutations by players

## Getting Started

### 1. Opening a Portal

Connect to a remote shared directory using the `portal` spell:

```sh
# Basic syntax
portal user@server.com:~/shared-world

# With custom mount point
portal player@example.com:/game/world ~/my-portal

# Alternative syntax
portal server.com /remote/path
```

The portal spell:
- Creates a local mount point (default: `~/portals/<server>`)
- Uses sshfs with xattr support enabled
- Uses your MUD_PLAYER SSH key if available
- Preserves extended attributes for game state

### 2. Exploring the World

Navigate to the portal and look around:

```sh
cd ~/portals/server
look
```

The `look` spell shows:
- Room title (from `title` xattr or directory name)
- Room description (from `description` xattr or default)
- Recent activity (last 5 entries from `.room.log`)

### 3. Communicating

Say something in the current room:

```sh
say "Hello, adventurers!"
```

This appends to `.room.log` with timestamp and player name. Other players can:
- Use `look` to see recent messages
- Use `listen` to watch messages in real-time

Listen to room activity:

```sh
listen          # Current room
listen ~/portals/server/dungeon  # Specific room
```

### 4. Combat and Magic

Cast spells that affect the shared world:

```sh
magic-missile treasure-chest
```

This:
- Deals damage (stored in `damage` xattr)
- Logs the attack to `.room.log`
- Other players see the combat when they `look`

### 5. Closing Portals

When done, unmount the portal:

```sh
close-portal ~/portals/server
```

Or list all active portals:

```sh
close-portal
```

## Menu Integration

All multiplayer functions are accessible from the MUD menu (`mud` command):

- **Look Around**: View current room and recent activity
- **Say Something**: Send a message to the room
- **Open Portal**: Connect to a remote world
- **Close Portal**: Disconnect from a portal
- **Teleport to Portal Chamber**: Navigate to `/Volumes` (Mac) or `/mnt` (Linux)

## How It Works

### Room Logs (`.room.log`)

Every action that should be visible to other players appends a timestamped entry:

```
[2026-01-24 06:30:15] Alice says: Hello!
[2026-01-24 06:30:22] Bob casts magic missile at goblin, dealing 4 damage!
[2026-01-24 06:30:30] Carol says: Nice shot!
```

### Extended Attributes (xattrs)

Game state is stored as xattrs with the `user.` namespace:

```sh
# Set attributes
enchant room "title=The Dragon's Lair"
enchant chest "life=100"
enchant chest "damage=25"

# Read attributes
read-magic room title
read-magic chest damage
```

sshfs with `-o xattr` preserves these across the network.

### Validation and Consistency

Wizardry uses **social and eventual consistency**:
- No locks or transactions
- Players trust each other to follow the rules
- Spells check local state before making changes
- Divergence is visible in the filesystem
- Community handles disputes through narration

## Testing Multiplayer

### Local Testing (Single Machine)

1. Create a shared directory:
```sh
mkdir -p /tmp/shared-world/dungeon
cd /tmp/shared-world/dungeon
```

2. Terminal 1 (Player 1):
```sh
export MUD_PLAYER=Alice
say "I'm exploring the dungeon"
```

3. Terminal 2 (Player 2):
```sh
export MUD_PLAYER=Bob
look  # See Alice's message
say "I'll join you!"
```

### Network Testing (Two Machines)

1. Server: Set up SSH and a shared directory
2. Server: Ensure sshfs/FUSE and xattr support are enabled
3. Client: Open portal to server
4. Both: Navigate to shared location and interact

## Extended Attribute Compatibility

### Linux ↔ Mac

- **Linux**: Uses `attr`, `getfattr`, `setfattr`
- **Mac**: Uses `xattr`
- **Compatibility**: sshfs with `-o xattr` should preserve xattrs

Testing notes:
- Basic xattrs (strings, numbers) work well
- Complex binary data may need encoding
- Namespace handling differs (Linux: `user.`, Mac: none)
- Wizardry's `enchant` and `read-magic` handle these differences

### Filesystem Support

Not all filesystems support xattrs:
- ✅ ext4, XFS, Btrfs (Linux)
- ✅ APFS, HFS+ (Mac)
- ❌ FAT32, exFAT
- ⚠️  NFS, SMB (limited xattr support)

## Security Notes

The portal system uses SSH for authentication and encryption:
- SSH keys are stored in `~/.ssh/$MUD_PLAYER`
- Set `MUD_PLAYER` environment variable to your key name
- Server must have your public key in `~/.ssh/authorized_keys`
- sshfs runs in user mode (no sudo required)

For anonymous/Tor access, use `open-portal-tor` instead.

## Future Enhancements

Potential additions:
- Avatar directories with inventory
- Trigger system (spells that react to state changes)
- Movement tracking (avatar location files)
- Health/mana regeneration daemons (optional)
- Conflict resolution tools
- Room/item templates and spawning
- Event broadcasting (beyond logs)

## Architecture Philosophy

Wizardry multiplayer follows these principles:

1. **Filesystem is the world**: All state is in files/xattrs
2. **No hidden authority**: Everything is visible and inspectable
3. **Player agency**: Players run spells that mutate state directly
4. **Social validation**: Community handles edge cases
5. **Eventual consistency**: Changes propagate naturally via filesystem
6. **Latent triggers**: Spells check state when run, no background processes
7. **Transparent tools**: All actions are regular shell commands

## Spell Reference

### Translocation
- `portal` - Open a portal (mount remote directory via sshfs)
- `close-portal` - Close a portal (unmount)
- `open-portal-tor` - Open portal via Tor (anonymous)

### Communication
- `say` - Speak in current room (append to `.room.log`)
- `listen` - Watch room activity in real-time (tail -f `.room.log`)

### Observation
- `look` - View room with recent activity

### Combat
- `magic-missile` - Attack with logging to room

### Attributes
- `enchant` - Set extended attributes
- `read-magic` - Read extended attributes

## Troubleshooting

**Portal won't open:**
- Check sshfs is installed: `command -v sshfs`
- Verify SSH connectivity: `ssh user@server`
- Check SSH key: `ls ~/.ssh/$MUD_PLAYER`

**Can't see other players' messages:**
- Ensure you're in the same directory
- Check `.room.log` exists: `ls -la`
- Verify file permissions

**Xattrs not syncing:**
- Confirm sshfs mounted with `-o xattr`
- Test: `mount | grep portals`
- Check filesystem supports xattrs on both sides

**Permission errors:**
- Ensure directory is writable
- Check file ownership: `ls -l`
- Verify SSH user has access

## Examples

### Setting Up a Shared Dungeon

Server side:
```sh
mkdir -p ~/worlds/dragon-keep
cd ~/worlds/dragon-keep
enchant . "title=Dragon Keep"
enchant . "description=An ancient fortress shrouded in mystery."
```

Client side:
```sh
portal user@server:~/worlds/dragon-keep
cd ~/portals/server/dragon-keep
look
say "I've arrived at the keep!"
```

### Combat Example

```sh
# Create an enemy
echo "A fierce goblin" > goblin
enchant goblin "life=20"

# Player 1 attacks
magic-missile goblin

# Player 2 sees the combat
look  # Shows "Player1 casts magic missile at goblin"
```

### Multi-Room Adventure

```sh
cd ~/portals/server/world
mkdir -p throne-room library armory
enchant throne-room "title=The Throne Room"
enchant library "title=The Ancient Library"
enchant armory "title=The Weapon Armory"

cd throne-room
say "The king's throne sits empty..."
```
