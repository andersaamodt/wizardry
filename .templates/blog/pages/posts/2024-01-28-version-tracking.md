---
title: "Version Tracking Demo (Revised)"
published_at: "2024-01-28T11:00:00Z"
content_hash: "d4735e3a265e16eee03f59718b9b5d03019c07d8b6c51f90da3a666eec13ab35"
previous_hash: "4e07408562bedb8b60ce05c1decfe3ad16b72230967de01f640b7e4729b49fce"
tags: ["demo", "versioning"]
author: "Blog Author"
summary: "This post demonstrates how version tracking works - this is the revised version."
visibility: "public"
license: "CC BY 4.0"
---

# Version Tracking Demo (Revised)

**Note**: This is a revised version of the original post. See the revision history below.

## What Changed?

In this revision, I've:
- Added more details about version tracking
- Included code examples
- Clarified the append-only model
- Fixed some typos

## How Version Tracking Works

Every post has a unique `content_hash`. When you edit a post:

1. **Create new file** with updated content
2. **Generate new hash** from new content
3. **Add `previous_hash`** field linking to old version
4. **Mark old version** as "replaced"

The old version remains accessible, creating an immutable audit trail.

## Example Metadata

```yaml
# Original post
content_hash: "4e0740..."
published_at: "2024-01-28T10:00:00Z"

# Revised post
content_hash: "d4735e..."
previous_hash: "4e0740..."  # Links to original
published_at: "2024-01-28T11:00:00Z"
```

## Benefits

This append-only approach provides:
- **Full history**: See all revisions
- **Transparency**: Changes are visible
- **Accountability**: Authors can't hide edits
- **Nostr-ready**: Maps to event replacement

## Revision History

This post has been edited. Previous versions:

- **Original**: Published 2024-01-28 10:00 UTC
  - Content hash: `4e0740...`
  - [View original version](#) (when CGI implemented)

---

*This post demonstrates version lineage with the `previous_hash` field.*
