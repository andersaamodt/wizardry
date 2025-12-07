# Compiled Spell Categorization

This document categorizes all wizardry spells and imps for standalone compilation testing.

**Goal: 100% success rate for all supported spells** (based on end-user utility and whether it's logically part of wizardry's core, not feasibility).

## Categories

- **💎 Gem**: Highly useful standalone. These MUST work perfectly in compiled form.
- **✓ Included**: May have some standalone use. Get working - no exemptions.
- **✗ Excluded**: Core wizardry infrastructure only. Not meaningful standalone by definition.

## Category Definitions

| Category | Criteria | Testing |
|----------|----------|---------|
| 💎 Gem | Immediately useful without wizardry. Standalone utility value. | 100% must pass |
| ✓ Included | Building blocks or utilities with potential standalone use. | 100% must pass |
| ✗ Excluded | Wizardry-only: installation, environment setup, infrastructure. | Not tested |

## Spell Categories with Justification

### Gems (💎) - Highest Priority

| Spell/Imp | Justification |
|-----------|---------------|
| **Crypto** |
| hash | File checksum utility - universally useful |
| hashchant | Hash verification - security tool |
| evoke-hash | Hash computation - standalone utility |
| **File Operations** |
| copy | Copy to clipboard - common need |
| bind-tome | Merge files - text processing utility |
| unbind-tome | Split files - text processing utility |
| **Text Processing** |
| merge-yaml-text | YAML manipulation - config management |
| yaml-to-enchantment | Format conversion - data processing |
| enchantment-to-yaml | Format conversion - data processing |
| **Utilities** |
| list-files | Directory listing - file discovery |
| file-list | File operations - system utility |
| priorities | Priority management - task organization |
| **Compilation** |
| compile-spell | Self-compilation - meta utility |

### Included (✓) - Standard Testing

| Component | Justification |
|-----------|---------------|
| **All Imps** | Building blocks - should work standalone |
| cond/* | Conditional logic - universally needed |
| out/* | Output helpers - basic functionality |
| str/* | String operations - text processing |
| fs/* | Filesystem - file operations |
| paths/* | Path manipulation - system utilities |
| sys/* (except excluded) | System utilities - general use |
| input/* | User input - interaction |
| lex/* | Parsing - text processing |
| **Spellcraft** |
| lint-magic | Code quality - development tool |
| scribe-spell | Spell creation - development |
| learn-spell | Spell management - organization |
| forget | Cleanup - maintenance |
| erase-spell | Removal - maintenance |
| **Translocation** |
| jump-to-marker | Navigation - productivity |
| mark-location | Bookmarking - organization |
| enchant-portkey | Quick access - efficiency |
| follow-portkey | Navigation - workflow |
| open-portal | Directory access - file management |
| open-teletype | Terminal access - development |
| **Arcane** |
| read-magic | File reading - basic utility |
| forall | Batch operations - automation |
| trash | Safe delete - file management |
| jump-trash | Navigate to trash - cleanup |
| **Contacts** |
| read-contact | Contact reading - information |
| list-contacts | Contact listing - organization |
| **Divination** |
| identify-room | Directory info - navigation |
| look | Environment inspection - awareness |
| **Enchant** |
| enchant | Metadata - configuration |
| disenchant | Metadata removal - cleanup |
| **Wards** |
| ssh-barrier | SSH helper - security |
| **PSI** |
| prioritize | Task prioritization - productivity |
| upvote | Priority adjustment - organization |
| get-priority | Priority query - information |
| get-new-priority | Priority calculation - logic |
| **Menu Spells** |
| cast | Spell launcher - now has fallback functions |
| spell-menu | Spell interface - now has fallback functions |
| **Arcana (.arcana/*)** |
| All .arcana scripts | Advanced/specialized utilities - include all |

### Excluded (✗) - Infrastructure Only

| Spell/Imp | Justification |
|-----------|---------------|
| invoke-wizardry | Sets up wizardry environment - infrastructure |
| require-wizardry | Checks wizardry installation - infrastructure |
| declare-globals | Wizardry globals setup - infrastructure |
| learn-spellbook | Manages entire spellbook - wizardry-specific |
| learn | Interactive learning system - wizardry-specific |
| mud | Game infrastructure - wizardry-specific |
| decorate | MUD decoration - wizardry-specific |
| select-player | Player selection - wizardry-specific |

## Testing Strategy

1. **Gems (💎)**: Zero tolerance - must achieve 100%
2. **Included (✓)**: Zero tolerance - must achieve 100%
3. **Excluded (✗)**: Not tested - explicitly skipped

**No failure threshold. Goal is 100% for all supported spells.**

## Implementation Notes

- cast and spell-menu now have function-based fallback implementations
- All imps are function-based and should inline properly
- .arcana scripts are now included (advanced utilities)
- Total scripts: ~326 (256 base + 70 .arcana)
- Expected to compile and work: ~318 (326 - 8 excluded)

## Current Results

- **Total scripts**: 326
- **Compiled**: Testing in progress
- **Standalone successful**: Working towards 100%
- **Excluded**: 8 (infrastructure only)
