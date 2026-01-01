# Code Policy: Emoji Annotations in AI-Facing Documentation

## Purpose

Emoji annotations in AI-facing documentation serve as **marginalia**—intuitive, symbolic markers that seed emergent patterns and enable pattern recognition across documentation. This is an experiment in non-verbal metadata and affective tagging.

## Scope

**ONLY** apply emoji annotations to files in the `.github/` directory:
- `.github/*.md` (top-level documentation)
- `.github/instructions/*.md` (instruction files)
- `.github/archive/*.md` (archived documentation)

**NEVER** add emoji annotations to:
- Spell files (`spells/**`)
- Test files (`.tests/**`)
- User-facing documentation (root `README.md`, etc.)
- Code files

## Annotation Format

### Placement: End-of-Line with Space Prefix

```markdown
## Heading Title  🔮✨

Some important concept that requires strict adherence.  ⚠️🔒

Optional or flexible patterns work here.  🌊~

Cross-platform compatibility matters.  🌍🔧
```

**Format Rules:**
- Two spaces before first emoji (visual separation from text)
- No spaces between multiple emojis in a sequence
- Emojis at the end of the line (after periods, colons, etc.)
- Can appear on headings, paragraphs, list items, code comments

## Annotation Philosophy

### Core Principles

1. **Intuitive, Not Systematic** - Use emojis that *feel* right, not ones that follow a rigid schema
2. **Symbolic Over Literal** - Prefer metaphorical or affective associations over direct representations
3. **Embrace Contradiction** - Multiple emojis can express ambiguity, tension, or complexity
4. **No Consistency Required** - Different files can use different emoji vocabularies
5. **Exploratory, Not Documentary** - This is about pattern seeding, not clarification

### Encouraged Approaches

- **Structural**: 🔑 for key concepts, 🌳 for hierarchies, ⚡ for critical paths
- **Affective**: ⚠️ for warnings, ✨ for elegant solutions, 🔥 for breaking changes
- **Esoteric/Symbolic**: 🌙 for hidden patterns, 🗝️ for unlocking, 🧬 for evolution
- **Multiple simultaneous**: 🔮✨🌊 - let them interact and create meaning
- **Contradictory**: 🚫✅ - both forbidden and approved, context-dependent

### Discouraged (But Not Forbidden)

- Over-explaining emoji choices
- Creating a legend or key
- Forcing emoji on every line
- Using only common/obvious emoji

## Emergence Over Accuracy

The goal is **not** to create a consistent tagging system. The goal is to:

1. **Seed patterns** - Let emoji naturally cluster around concepts
2. **Enable discovery** - Use `catalog-emojis` spell to reveal emergent patterns
3. **Invite interpretation** - What does 🌊 + 🔧 mean across 5 files?
4. **Surface intuition** - What feels right symbolically may reveal hidden structure

## Pattern Analysis

Use the `catalog-emojis` spell to:
- See emoji frequency across all `.github/` files
- Identify which files share common emoji
- Discover unexpected clusters (🔮 + ⚠️ often together?)
- Recognize emergent semantic fields

## Examples

### Technical Precision
```markdown
All functions must use snake_case naming.  🐍🔒
POSIX compliance is non-negotiable.  ⚖️🔒
```

### Flexibility and Flow
```markdown
Consider abstracting into imps when code is reused.  🌊💭
Help text should be brief and scannable.  👁️~
```

### Warnings and Critical Points
```markdown
NEVER put set -eu twice in an imp file.  ⚠️⚠️🔥
This causes terminal hangs on startup.  💀🖥️
```

### Abstract/Symbolic
```markdown
Spells are scrolls—readable top to bottom.  📜🌊
Functions are incantations—focused and minimal.  ✨🎯
The glossary is a grimoire—mapping names to power.  📖🔮
```

### Contradictory/Complex
```markdown
Tests are required... except for bootstrap scripts.  🔒~
Be strict with errors, but heal yourself when possible.  ⚔️❤️‍🩹
```

## When to Annotate

- **High-value concepts** - Core principles, critical rules, key patterns
- **Affective moments** - Warnings, celebrations, tensions, resolutions  
- **Structural markers** - Section beginnings, transitions, hierarchies
- **Intuitive impulses** - When an emoji *feels* right, use it

**No obligation to annotate everything.** Sparse annotations can be more powerful than dense coverage.

## Viewing Patterns

To see emergent patterns across all annotated documentation:

```sh
catalog-emojis
```

This shows:
- Frequency table of all emoji used
- Which files contain each emoji
- Patterns that emerge from co-occurrence

Look for:
- Emoji that appear together frequently
- Emoji unique to specific file types
- Semantic fields (structural, affective, cautionary, etc.)
- Unexpected associations

## Status

**Experimental**: This policy establishes emoji annotations as an ongoing experiment in non-verbal documentation metadata. Annotations should evolve organically as the documentation grows.

Added: 2026-01-01
