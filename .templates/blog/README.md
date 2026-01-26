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

- **Homepage**: Chronological reverse-ordered post listing with pagination
- **Tag index**: Global tag list with post counts
- **Tag pages**: Posts filtered by tag
- **Post navigation**: Previous/next links within posts
- **Revision history**: Shows version lineage for edited posts

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

## Design Principles

1. **Filesystem as database**: Posts are files, versions are immutable
2. **Content-addressable**: Identity based on content hash
3. **Append-only**: Edits create new versions, old versions preserved
4. **UNIX permissions**: Visibility through filesystem semantics
5. **Nostr-aligned**: Future-proofed for decentralized social layer
6. **Simple & transparent**: No hidden state, all data in files

## License

Part of the wizardry project.
