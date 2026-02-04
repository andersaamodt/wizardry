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

## SSH + WebAuthn Authentication (Optional)

The blog template includes an optional authentication demo that combines SSH public keys with WebAuthn for passwordless authentication.

### Features

- **SSH Fingerprint as Root Identity**: SSH public key fingerprint serves as the stable identity
- **WebAuthn Delegates**: Browser credentials bound to the SSH fingerprint
- **Phishing-Resistant**: WebAuthn provides strong authentication without passwords
- **Revocable Delegates**: WebAuthn credentials can be revoked without changing SSH identity
- **Multi-Device Support**: Multiple WebAuthn credentials can bind to one SSH identity

### How It Works

1. **Registration**: User supplies SSH public key; server stores fingerprint
2. **Binding**: Server issues challenge naming the SSH fingerprint
3. **Credential Creation**: Browser creates WebAuthn credential bound to fingerprint
4. **Authentication**: Login uses only WebAuthn (SSH key not involved)
5. **Resolution**: Server resolves `WebAuthn credential → SSH fingerprint → account`

### Demo Page

Visit `/ssh-auth.html` on your blog site to see the interactive authentication demo.

### CGI Scripts

The following CGI scripts power the SSH+WebAuthn authentication:

- `ssh-auth-register`: Register SSH public key and get binding challenge
- `ssh-auth-bind-webauthn`: Bind WebAuthn credential to SSH fingerprint
- `ssh-auth-login`: Authenticate using WebAuthn credential
- `ssh-auth-list-delegates`: List all WebAuthn delegates for a user
- `ssh-auth-revoke-delegate`: Revoke a specific WebAuthn delegate

### Data Storage

Authentication data is stored in the site data directory:

```
~/sites/myblog/data/ssh-auth/
├── users/
│   └── username/
│       ├── ssh_public_key        # Original SSH public key
│       ├── ssh_fingerprint       # SHA-256 fingerprint (root identity)
│       ├── challenge             # Current binding challenge
│       └── delegates/            # WebAuthn credentials
│           └── delegate_id       # Each delegate (revocable)
└── sessions/
    └── session_token             # Active login sessions
```

### Security Notes

- This is a demonstration implementation
- Production use would require:
  - Server-side WebAuthn signature verification
  - Proper CBOR decoding of credential data
  - Session management with expiration
  - CSRF protection
  - HTTPS (required for WebAuthn)

## Design Principles

1. **Filesystem as database**: Posts are files, versions are immutable
2. **Content-addressable**: Identity based on content hash
3. **Append-only**: Edits create new versions, old versions preserved
4. **UNIX permissions**: Visibility through filesystem semantics
5. **Nostr-aligned**: Future-proofed for decentralized social layer
6. **Simple & transparent**: No hidden state, all data in files

## License

Part of the wizardry project.
