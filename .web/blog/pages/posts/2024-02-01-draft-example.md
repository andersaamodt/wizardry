---
title: "This is a Draft Post"
published_at: "2024-02-01T12:00:00Z"
content_hash: "draft1234567890abcdef1234567890abcdef1234567890abcdef1234567890ab"
tags: ["draft", "testing"]
author: "Blog Author"
summary: "This post is marked as draft and should not appear in public listings."
visibility: "draft"
license: "CC BY 4.0"
---

# This is a Draft Post

This post demonstrates the draft visibility feature. Posts marked with `visibility: "draft"` will not appear in:
- Blog index (homepage)
- Tag listings
- Search results

This allows you to work on posts locally before publishing them.

## Publishing a Draft

To publish a draft, simply change the `visibility` field from `"draft"` to `"public"`:

```yaml
visibility: "public"
```

Then rebuild your site with `web-wizardry build myblog`.

## Benefits

- Work on posts without making them public
- Preview locally before publishing
- UNIX permissions still apply as a secondary layer

---

*Note: This is a draft post used for testing. It should not appear in public views.*
