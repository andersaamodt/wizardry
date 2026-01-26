---
title: "Understanding Content Hashes"
published_at: "2024-01-20T14:30:00Z"
content_hash: "5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9"
tags: ["tech", "tutorial", "content-addressable"]
author: "Blog Author"
summary: "Learn how content-addressable storage works and why it matters for blog posts."
visibility: "public"
license: "CC BY 4.0"
---

# Understanding Content Hashes

One of the unique features of this blog is that every post is identified by its content hash. Let me explain what that means.

## What is a Content Hash?

A content hash is a unique identifier generated from the content itself using a cryptographic hash function (SHA-256 in our case). Think of it as a fingerprint for your content.

```sh
# Example: Generate SHA-256 hash
echo "Hello, world!" | sha256sum
```

## Why Use Content Hashes?

Content-addressable storage has several advantages:

1. **Immutability**: The hash proves content hasn't changed
2. **Deduplication**: Identical content = identical hash
3. **Verification**: Readers can verify content integrity
4. **Distribution**: Content can be fetched from any source
5. **Nostr compatibility**: Aligns with decentralized protocols

## Version Lineage

When you edit a post, we create a new version with:
- A new content hash (since content changed)
- A `previous_hash` field linking to the old version
- The original version preserved

This creates an append-only chain of versions, similar to Git commits or blockchain transactions.

## Example

```yaml
---
title: "My Post (Revised)"
content_hash: "abc123..."  # New hash
previous_hash: "def456..."  # Points to original
---
```

## Benefits for Readers

Content hashes provide:
- **Permanent links**: Hash-based URLs never break
- **Transparency**: See the full revision history
- **Trust**: Verify content hasn't been tampered with

## Future: Nostr Integration

When we add Nostr support (Phase 2), content hashes will map directly to Nostr event IDs, enabling:
- Decentralized comments and reactions
- Cross-platform syndication
- Cryptographic verification
- Social layer integration

## Learn More

- [About this blog](/pages/about.html)
- [Tag: content-addressable](/pages/tags.html)

---

*This post demonstrates how content-addressable storage works in the blog platform.*
