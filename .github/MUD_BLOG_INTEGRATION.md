# MUD Integration with SSH + WebAuthn Authentication

## Overview

This implementation connects the wizardry MUD player system with the blog's SSH + WebAuthn authentication system, providing a unified identity and permission system based on UNIX principles.

## Architecture

### Identity Flow

```
MUD Player Account (UNIX user)
    ↓
SSH Public Key (authorized_keys)
    ↓
SSH Fingerprint (SHA-256)
    ↓
WebAuthn Credentials (delegates)
    ↓
Web Session
```

### Permission Flow

```
UNIX Group Membership (blog-admin)
    ↓
Admin Status Check (id -nG)
    ↓
Admin Panel Access
    ↓
Draft Management, Settings, Publishing
```

## Setup Guide

### 1. Create MUD Server and Group

On the server (requires root/sudo):

```sh
# Create the blog-admin group
sudo groupadd blog-admin

# Create the mud group (if not already exists)
sudo groupadd mud
```

### 2. Add a MUD Player

As root/sudo on the server:

```sh
# Interactive player creation
sudo add-player

# Enter player name: alice
# Enter SSH public key: ssh-ed25519 AAAAC3N...
```

This creates:
- System user account for alice
- Home directory at /home/alice
- SSH key in /home/alice/.ssh/authorized_keys
- User added to 'mud' group

### 3. Grant Admin Access (Optional)

To give a user admin access to the blog:

```sh
# Add user to blog-admin group
sudo usermod -aG blog-admin alice
```

### 4. Disable Registration (Optional)

For a single-author blog, disable new user registration:

1. Login to the blog admin panel
2. Go to Settings
3. Uncheck "Enable User Registration"
4. Save Settings

This creates a site.conf file with:
```
registration_enabled=false
```

## User Workflow

### For MUD Players

1. **Connect to MUD**: SSH to server using player SSH key
2. **Access Blog**: Navigate to blog site
3. **Register**: Enter player name on /ssh-auth.html
4. **Bind WebAuthn**: Create WebAuthn credential (fingerprint, etc.)
5. **Login**: Use WebAuthn to login (no SSH key needed)
6. **Admin Panel** (if admin): Access /admin.html for management

### For Blog Admins

1. **Login**: Authenticate via WebAuthn
2. **Compose**: Write posts in Markdown with live preview
3. **Save Draft**: Save work-in-progress
4. **Publish**: Make posts public
5. **Settings**: Configure site (title, registration)
6. **Manage Drafts**: View and manage draft posts

## Technical Details

### CGI Endpoints

#### Authentication

- **ssh-auth-register-mud**: Register using MUD player account
  - Input: username (MUD player name)
  - Checks: System user exists, has SSH key in authorized_keys
  - Output: fingerprint, challenge, is_admin status

- **ssh-auth-check-session**: Validate session and get permissions
  - Input: session_token
  - Checks: Session exists, user still exists, group membership
  - Output: authenticated, username, fingerprint, is_admin

#### Blog Management

- **blog-get-config**: Get site configuration
  - Output: registration_enabled, site_title

- **blog-update-config**: Update site configuration (admin only)
  - Input: session_token, registration_enabled, site_title
  - Checks: Valid session, user is in blog-admin group

- **blog-list-drafts**: List draft posts (admin only)
  - Input: session_token
  - Checks: Admin permission
  - Output: Array of drafts with title, filename

- **blog-save-post**: Save or publish post (admin only)
  - Input: session_token, title, tags, summary, content, visibility
  - Checks: Admin permission
  - Output: filename, message
  - Creates: Markdown file with front matter in site/pages/posts/

### File Structure

```
~/sites/myblog/
├── site.conf                     # Site configuration
├── data/
│   └── ssh-auth/
│       ├── users/
│       │   └── alice/
│       │       ├── ssh_fingerprint
│       │       ├── ssh_public_key
│       │       ├── is_admin       # Admin flag
│       │       ├── challenge
│       │       └── delegates/
│       │           └── delegate_id
│       └── sessions/
│           └── session_token
└── site/
    └── pages/
        ├── posts/
        │   ├── 2024-02-04-my-post.md
        │   └── 2024-02-04-draft.md  # visibility: "draft"
        ├── admin.html                 # Admin panel
        └── ssh-auth.html              # Auth page
```

### Permission Model

**UNIX Groups:**
- `mud`: MUD players (read-only to shared spaces)
- `blog-admin`: Blog administrators (full access)

**Checking Admin Status:**
```sh
id -nG "$username" 2>/dev/null | grep -q "blog-admin"
```

**Admin Capabilities:**
- Compose and publish posts
- Save drafts
- Edit site settings
- Manage user registration
- View all drafts

**Non-Admin Users:**
- Can register (if enabled)
- Can login with WebAuthn
- Cannot access admin panel

### Security Features

1. **Phishing-Resistant**: WebAuthn credentials bound to domain
2. **Group-Based Permissions**: UNIX groups control access
3. **Session Validation**: Every admin action validates session and permissions
4. **Root Identity Protection**: SSH private keys never touch web
5. **Revocable Delegates**: WebAuthn credentials can be revoked independently
6. **File-Based Configuration**: Settings stored in plain text files

## Configuration Options

### Site Config (site.conf)

```ini
registration_enabled=false  # Disable new user registration
site_title=My Personal Blog # Site title
```

### Post Front Matter

```yaml
---
title: "My Post Title"
published_at: "2024-02-04T12:00:00Z"
content_hash: "a1b2c3d4..."
tags: ["tech", "wizardry"]
author: "alice"
summary: "Brief description"
visibility: "public"  # or "draft"
license: "CC BY 4.0"
---
```

## Example Workflow

### Initial Setup

```sh
# On server as root
sudo groupadd blog-admin
sudo add-player  # Create MUD player 'alice'
sudo usermod -aG blog-admin alice

# As alice
ssh alice@server
```

### Blog Administrator Workflow

1. Visit blog site
2. Go to /ssh-auth.html
3. Enter "alice" as player name
4. Click "Register with MUD Account"
5. Create WebAuthn credential (biometric, security key, etc.)
6. Click "Login with WebAuthn"
7. Click "Go to Admin Panel"
8. Compose post in Markdown
9. See live preview
10. Click "Publish" or "Save as Draft"

### Disabling Public Registration

1. Login as admin
2. Go to Admin Panel
3. Settings section
4. Uncheck "Enable User Registration"
5. Click "Save Settings"

Now only existing MUD players can use the blog, and no new users can register without server admin creating a MUD account for them.

## Benefits

1. **Unified Identity**: MUD player = Blog user
2. **UNIX Permissions**: Standard OS groups control access
3. **No Duplicate Accounts**: One account for everything
4. **Server Admin Control**: User creation requires sudo
5. **File-Backed**: All data in files, no databases
6. **Transparent**: Easy to understand and debug
7. **Secure**: Multiple layers of auth and permission checks

## Future Enhancements

Potential additions:

1. **SSH Recovery**: Use SSH challenge-response to re-bind lost WebAuthn
2. **Multi-Author Support**: Multiple admins with different permissions
3. **Role-Based Access**: More granular permissions (editor, reviewer, etc.)
4. **Nostr Integration**: Bridge to decentralized social
5. **Activity Logging**: Track post edits and admin actions
6. **Collaborative Editing**: Multiple authors on same post
7. **Comment System**: File-backed comments linked to MUD accounts

## Troubleshooting

### User Registration Fails

Check:
- Does MUD player account exist? (`id username`)
- Is SSH key in authorized_keys? (`cat /home/username/.ssh/authorized_keys`)
- Is registration enabled? (Check admin panel settings)

### Admin Panel Shows "No Admin Permissions"

Check:
- Is user in blog-admin group? (`id -nG username | grep blog-admin`)
- Was session created after adding to group? (Re-login)

### Can't Save Posts

Check:
- Is user authenticated? (Check session token in localStorage)
- Is user admin? (Check group membership)
- Does posts directory exist? (`mkdir -p site/pages/posts`)
- Are permissions correct? (User should own site directory)

## Implementation Files

**CGI Scripts:**
- `ssh-auth-register-mud` - MUD account registration
- `ssh-auth-check-session` - Session validation
- `blog-get-config` - Get site config
- `blog-update-config` - Update site config (admin)
- `blog-list-drafts` - List drafts (admin)
- `blog-save-post` - Save/publish posts (admin)

**Pages:**
- `admin.md` - Admin panel with composer
- `ssh-auth.md` - Authentication page

**Tests:**
- `test-ssh-auth-register-mud.sh`
- `test-blog-save-post.sh`

All POSIX compliant, following wizardry conventions.
