# Personal Blog Template

A single-author blog template for wizardry web, architected for future multi-author and Nostr integration.

## Features

- **Content-addressable posts**: Each post identified by content hash
- **Version lineage**: Edits create new versions linked to prior versions
- **Tag-based navigation**: Tags function as categories
- **Chronological index**: Blog homepage with reverse-ordered post listing
- **Lifecycle states**: Draft, published, replaced, deleted
- **UNIX permissions**: Visibility enforced via filesystem permissions
- **Nostr-ready**: Architecture aligned for future Nostr integration (Phase 2)

## Post Model

Posts are stored as `.md` files in `site/pages/posts/` with YAML front-matter:

```markdown
---
title: "My First Post"
published_at: "2024-01-15T10:30:00Z"
content_hash: "a1b2c3d4e5f6..."
tags: ["tech", "tutorial"]
author: "Your Name"
summary: "A brief introduction to my blog"
visibility: "public"
license: "CC BY 4.0"
---

# My First Post

Your post content here...
```

## Metadata Fields

### Required
- **title**: Post title
- **published_at**: ISO 8601 timestamp
- **content_hash**: Immutable post identifier (SHA-256 of content)
- **tags**: Array of tags (Nostr-compatible)
- **author**: Author name (extensible to multi-author)

### Optional
- **previous_hash**: Links to prior version (for edits)
- **summary**: Brief description for index/feeds
- **visibility**: Mapped to UNIX permissions (default: public)
- **license**: Content license (e.g., CC BY 4.0)

## Lifecycle States

Posts have system-understood states:
- **draft**: Local only, not published
- **published**: Canonical public state
- **replaced**: Superseded by newer version
- **deleted**: Tombstoned (marked for deletion)

States are inferred from metadata and filesystem visibility.

## Blog Structure

```
blog/
├── site/
│   └── pages/
│       ├── index.md         # Blog homepage
│       ├── about.md         # About page
│       ├── tags.md          # Tag index
│       └── posts/           # Blog posts
│           ├── 2024-01-15-welcome.md
│           └── 2024-01-20-second-post.md
└── static/
    └── style.css            # Blog styling
```

## Navigation

- **Homepage**: Chronological reverse-ordered post listing with pagination (10 posts per page)
- **Tag index**: Global tag list with post counts
- **Tag pages**: Posts filtered by tag
- **Search**: Full-text search across titles, tags, summaries, and content
- **Post navigation**: Previous/next links within posts
- **Revision history**: Shows version lineage for edited posts

## Search

Full-text search via CGI:
- Search across post titles, tags, summaries, and content
- Case-insensitive matching
- Excludes draft posts from results
- Accessible via `/cgi/blog-search?q=query`

## Pagination

Blog index automatically paginates:
- 10 posts per page
- Previous/Next navigation
- Page counter (e.g., "Page 2 of 5")
- URL parameter: `?page=N`

## Draft Visibility

Posts with `visibility: "draft"` are hidden from:
- Blog homepage (index)
- Tag listings
- Search results

Drafts are only visible when accessed directly by URL, allowing you to work on posts locally before publishing.

To publish a draft:
```yaml
visibility: "public"  # Change from "draft"
```

## Static Pages

- **About**: Required static page (linked from navigation)
- Additional static pages can be added as `.md` files

## Interaction Model

- Blog is **read-only**
- No native comments, reactions, or annotations
- All interaction deferred to Nostr (Phase 2)

## Future: Nostr Integration (Phase 2)

Architecture is designed for seamless Nostr integration:
- Content hashes align with Nostr event IDs
- Tags compatible with Nostr event tagging
- Post model extensible to multi-author
- Metadata prepared for Nostr event format
- Revision lineage maps to Nostr event replacement

## Quick Start

```sh
# Create a blog site
web-wizardry create myblog blog

# Edit content
vim ~/sites/myblog/site/pages/posts/2024-01-15-welcome.md

# Build
web-wizardry build myblog

# Serve
web-wizardry serve myblog
```

Visit http://localhost:8080

## MUD Integration & Authentication

The blog template integrates with the wizardry MUD player system to provide unified authentication and admin access control.

### Key Features

- **MUD Player Accounts**: Blog uses existing MUD player SSH keys
- **WebAuthn Authentication**: Passwordless login with biometrics/security keys
- **UNIX Group Permissions**: Admin access via `blog-admin` group
- **Admin Panel**: Compose, publish, and manage posts
- **Markdown Editor**: Live preview for easy writing
- **Draft Management**: Save work-in-progress, publish when ready
- **Configurable Registration**: Enable/disable new user registration

### Quick Start for Admins

1. **Create MUD Player** (on server as root):
   ```sh
   sudo add-player
   # Enter player name and SSH public key
   ```

2. **Grant Admin Access**:
   ```sh
   sudo groupadd blog-admin  # Create group if needed
   sudo usermod -aG blog-admin <username>
   ```

3. **Register on Blog**: Visit `/ssh-auth.html`, enter player name

4. **Access Admin Panel**: Visit `/admin.html` to compose and publish

### For Single-Author Blogs

After creating your account and giving yourself admin access:

1. Login to admin panel
2. Go to Settings
3. Uncheck "Enable User Registration"
4. Save Settings

This prevents new users from registering while keeping your access.

### Admin Capabilities

- **Compose Posts**: Markdown editor with live preview
- **Publish**: Make posts public instantly
- **Save Drafts**: Work on posts before publishing
- **Manage Settings**: Site title, registration toggle
- **View Drafts**: See all unpublished posts

### Authentication Flow

```
MUD Player (UNIX user with SSH key)
    ↓
Register on blog (uses SSH fingerprint)
    ↓
Create WebAuthn credential (biometric, security key)
    ↓
Login with WebAuthn (no SSH needed)
    ↓
Access admin panel (if in blog-admin group)
```

### Demo Pages

- `/ssh-auth.html` - Authentication and registration
- `/admin.html` - Admin panel (requires admin permissions)

### CGI Scripts

**Authentication:**
- `ssh-auth-register-mud` - Register using MUD player account
- `ssh-auth-register` - Manual SSH key registration (demo/testing)
- `ssh-auth-bind-webauthn` - Bind WebAuthn credential to SSH fingerprint
- `ssh-auth-login` - Authenticate using WebAuthn credential
- `ssh-auth-check-session` - Validate session and permissions
- `ssh-auth-list-delegates` - List all WebAuthn delegates
- `ssh-auth-revoke-delegate` - Revoke a WebAuthn delegate

**Blog Management (Admin Only):**
- `blog-get-config` - Get site configuration
- `blog-update-config` - Update site settings
- `blog-list-drafts` - List draft posts
- `blog-save-post` - Save or publish posts

### Data Storage

```
~/sites/myblog/
├── site.conf                  # Site configuration
├── data/
│   └── ssh-auth/
│       ├── users/
│       │   └── alice/
│       │       ├── ssh_fingerprint
│       │       ├── is_admin
│       │       └── delegates/
│       └── sessions/
└── site/
    └── pages/
        └── posts/
            ├── 2024-02-04-my-post.md  # Published
            └── 2024-02-04-draft.md    # Draft
```

### Security Model

- **Root Identity**: SSH public key fingerprint (never changes)
- **Delegates**: WebAuthn credentials (revocable, multi-device)
- **Permissions**: UNIX group membership (`blog-admin`)
- **Session Validation**: Every admin action checks permissions
- **Phishing-Resistant**: WebAuthn bound to domain

See `.github/MUD_BLOG_INTEGRATION.md` for complete documentation.

## Design Principles

1. **Filesystem as database**: Posts are files, versions are immutable
2. **Content-addressable**: Identity based on content hash
3. **Append-only**: Edits create new versions, old versions preserved
4. **UNIX permissions**: Visibility through filesystem semantics
5. **Nostr-aligned**: Future-proofed for decentralized social layer
6. **Simple & transparent**: No hidden state, all data in files

## License

Part of the wizardry project.
