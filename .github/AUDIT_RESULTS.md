# Wizardry Project Audit Results

**Audit Framework:** See [AUDIT.md](AUDIT.md)  
**Audit Type:** AI-Driven Intelligent Review  
**Last Updated:** 2026-02-06

## About This Audit

This audit is conducted by an AI agent **carefully reading and evaluating each file** against the project's ethos and standards. This is NOT an automated code analysis—each file receives intelligent human-level review with documented thoroughness levels.

### Thoroughness Levels

Each file is marked with how carefully it was reviewed:

- **❌ Not Read** - File not yet reviewed
- **👁️ Skimmed** - Brief scan (< 10 seconds)
- **📖 Read** - Read through with understanding (~30-60 seconds)
- **🔍 Perused** - Careful reading with attention to details (~2-5 minutes)
- **🎯 Exhaustive** - Thorough analysis with cross-referencing (5+ minutes)

Higher thoroughness isn't always necessary—simple files may only need "Read" level, while complex or critical files deserve "Exhaustive" review.

### Result Categories

- 🟢 **Pass** - Meets all applicable standards
- 🟡 **Warning** - Minor issues that should be addressed
- 🔴 **Fail** - Significant issues requiring fixes
- ⚪ **N/A** - Not applicable or not yet reviewed

### Column Meanings

1. **File Path** - Location in repository
2. **Last Audit** - When file was last reviewed (YYYY-MM-DD)
3. **Thoroughness** - Review depth (see levels above)
4. **Result** - Overall assessment (worst of all categories)
5. **Code** - POSIX compliance, engineering standards, quality metrics
6. **Docs** - Comments, documentation, help text quality
7. **Theme** - MUD-themed vocabulary usage (where applicable)
8. **Policy** - Adherence to project values and policies
9. **Ethos** - Holistic/intuitive alignment with project spirit (see AUDIT.md)
10. **Issues** - Specific problems found
11. **Fixes** - Changes made (🔧 = fixed in this iteration)

---

## Critical Issues (🔴 Failures)

**Note:** Previous audit claimed failures in tutorial files, but those were based on 📖 Read level reviews (insufficient depth). These need 🔍 Perused review to confirm.

**Pending Re-Review:**
- tutorials/04_comparison.sh
- tutorials/06_loops.sh  
- tutorials/11_debugging.sh
- tutorials/12_aliases.sh
- tutorials/13_eval.sh
- tutorials/14_bg.sh
- tutorials/21_env.sh
- tutorials/22_history.sh
- tutorials/24_distribution.sh
- tutorials/25_ssh.sh

These files are marked with grey dots pending careful review.

---

## Warnings (🟡)

**Confirmed Warning (from 🔍 Perused review):**
- `README.md` - Line 30 uses `bash` in example (should be `sh`)

**Pending Re-Review (from 📖 Read level - need careful review):**
All tutorial files previously marked as warnings need 🔍 Perused review to confirm assessment.

---

## Complete Audit Table


This table shows all files in the repository with their audit results. Files are listed in a flat structure for easy reference.

**Note:** This table consolidates all audit findings. When updating, modify the relevant row with new audit date, thoroughness, and findings.

**Legend:**
- **Last Audit:** Date of most recent review (YYYY-MM-DD)
- **Result:** 🟢 Pass | 🟡 Warning | 🔴 Fail | ⚪ N/A
- **Ethos:** Holistic alignment with project values (intuitive, ephemeral, spiritual fit)

| File Path | Last Audit | Thoroughness | Result | Code | Docs | Theme | Policy | Ethos | Issues | Fixes |
|-----------|------------|--------------|--------|------|------|-------|--------|-------|--------|-------|
| spells/arcane/copy | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/arcane/file-list | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/arcane/file-to-folder | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/arcane/forall | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/arcane/jump-trash | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/arcane/read-magic | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/arcane/trash | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/ask | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/ask-number | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/ask-text | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/ask-yn | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/await-keypress | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/browse | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/clear | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/colors | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/list-files | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/max-length | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/memorize | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/move | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/validate-ssh-key | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/wizard-cast | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/cantrips/wizard-eyes | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/crypto/evoke-hash | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/crypto/hash | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/crypto/hashchant | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/divination/detect-distro | 2026-02-06 | 🔍 Perused | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | None | - |
| spells/divination/detect-magic | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/divination/detect-posix | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/divination/detect-rc-file | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/divination/identify-room | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/enchant/disenchant | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/enchant/enchant | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/enchant/enchantment-to-yaml | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/enchant/yaml-to-enchantment | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/cast | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/install-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/main-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/mud | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/mud-admin-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/mud-admin/add-player | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/mud-admin/new-player | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/mud-admin/set-player | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/mud-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/mud-settings | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/network-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/priorities | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/priority-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/services-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/shutdown-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/spell-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/spellbook | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/synonym-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/system-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/thesaurus | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/menu/users-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/boot-player | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/check-cd-hook | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/choose-player | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/decorate | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/demo-multiplayer | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/greater-heal | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/heal | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/lesser-heal | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/listen | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/look | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/magic-missile | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/resurrect | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/say | 2026-02-06 | 🔍 Perused | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | None - exemplary | - |
| spells/mud/shocking-grasp | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/stats | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/mud/think | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/priorities/deprioritize | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/priorities/get-card | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/priorities/get-new-priority | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/priorities/get-priority | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/priorities/prioritize | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/priorities/upvote | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/psi/list-contacts | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/psi/read-contact | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/add-synonym | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/bind-tome | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/compile-spell | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/delete-synonym | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/demo-magic | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/doppelganger | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/edit-synonym | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/erase-spell | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/forget | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/learn | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/lint-magic | 2026-02-06 | 🎯 Exhaustive | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | None - superb | - |
| spells/spellcraft/merge-yaml-text | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/reset-default-synonyms | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/scribe-spell | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/spellcraft/unbind-tome | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/config | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/disable-service | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/enable-service | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/install-service-template | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/is-service-installed | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/kill-process | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/learn-spellbook | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/logs | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/package-managers | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/pocket-dimension | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/reload-ssh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/remove-service | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/restart-service | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/restart-ssh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/service-status | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/start-service | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/stop-service | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/system/update-all | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/tasks/check | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/tasks/get-checked | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/tasks/rename-interactive | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/tasks/uncheck | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/translocation/blink | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/translocation/close-portal | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/translocation/enchant-portkey | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/translocation/follow-portkey | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/translocation/go-up | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/translocation/jump-to-marker | 2026-02-06 | 🎯 Exhaustive | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | None - outstanding | - |
| spells/translocation/mark-location | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/translocation/open-portal | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/translocation/open-teletype | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/wards/banish | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/wards/defcon | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/wards/ssh-barrier | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/wards/ward-system | 2026-02-06 | 🎯 Exhaustive | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | None - exceptional | - |
| spells/web/build | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/change-site-port | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/check-https-status | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/configure-nginx | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/create-from-template | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/create-site | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/create-site-prompt | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/delete-site | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/diagnose-sse | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/disable-https | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/disable-site-daemon | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/enable-site-daemon | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/fix-site-security | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/https | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/is-site-daemon-enabled | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/manage-allowed-dirs | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/renew-https | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/repair-site-daemon | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/run-site-daemon | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/serve-site | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/setup-https | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/site-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/site-status | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/stop-site | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/template-menu | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/toggle-site-tor-hosting | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/update-from-template | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| spells/web/web-wizardry | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| install | 2026-02-06 | 🎯 Exhaustive | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 | None - exceptional quality | - |
| .tests/.arcana/bitcoin/test-bitcoin-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/bitcoin/test-bitcoin-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/bitcoin/test-bitcoin.service.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/bitcoin/test-change-bitcoin-directory.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/bitcoin/test-configure-bitcoin.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/bitcoin/test-install-bitcoin.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/bitcoin/test-is-bitcoin-installed.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/bitcoin/test-is-bitcoin-running.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/bitcoin/test-repair-bitcoin-permissions.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/bitcoin/test-uninstall-bitcoin.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/bitcoin/test-wallet-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-core-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-core-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-attr.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-awk.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-bwrap.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-checkbashisms.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-clipboard-helper.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-core.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-dd.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-find.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-git.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-grep.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-pkgin.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-ps.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-sed.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-socat.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-stty.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-tput.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-wl-clipboard.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-xclip.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-install-xsel.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-manage-system-command.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-awk.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-bwrap.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-checkbashisms.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-clipboard-helper.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-core.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-dd.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-find.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-git.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-grep.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-pkgin.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-ps.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-sed.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-socat.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-stty.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-tput.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-wl-clipboard.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-xclip.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/core/test-uninstall-xsel.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/lightning/test-configure-lightning.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/lightning/test-install-lightning.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/lightning/test-is-lightning-installed.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/lightning/test-is-lightning-running.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/lightning/test-lightning-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/lightning/test-lightning-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/lightning/test-lightning-wallet-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/lightning/test-lightning.service.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/lightning/test-repair-lightning-permissions.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/lightning/test-uninstall-lightning.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-install-cd.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-install-mud.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-install-sshfs.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-load-cd-hook.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-load-touch-hook.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-mud-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-sshfs-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-toggle-all-mud.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-toggle-avatar.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-toggle-cd.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-toggle-listen.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-toggle-mud-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-toggle-parse.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-toggle-sshfs.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-toggle-touch-hook.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/mud/test-uninstall-sshfs.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/simplex-chat/test-install-simplex-chat.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/simplex-chat/test-simplex-chat-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/simplex-chat/test-simplex-chat-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/simplex-chat/test-uninstall-simplex-chat.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-disable-syncthing-autostart.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-enable-syncthing-autostart.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-install-syncthing.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-is-syncthing-autostart-enabled.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-is-syncthing-installed.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-is-syncthing-running.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-open-syncthing.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-restart-syncthing.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-start-syncthing.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-stop-syncthing.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-syncthing-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-syncthing-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/syncthing/test-uninstall-syncthing.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/test-import-arcanum.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-configure-tor-bridge.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-configure-tor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-create-tor-launchd-service.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-disable-tor-daemon.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-enable-tor-daemon.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-ensure-torrc-exists.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-install-libevent.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-install-openssl.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-install-tor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-is-libevent-installed.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-is-openssl-installed.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-is-tor-daemon-enabled.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-is-tor-hidden-service-configured.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-is-tor-installed.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-is-tor-launchd-service-configured.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-is-tor-running.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-remove-tor-hidden-service.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-repair-tor-permissions.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-restart-tor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-setup-tor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-show-tor-log.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-show-tor-onion-address.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-start-tor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-stop-tor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-tor-bridge-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-tor-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-tor-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-torrc-path.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-uninstall-libevent.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-uninstall-openssl.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/tor/test-uninstall-tor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-install-acme.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-install-fcgiwrap.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-install-htmx.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-install-nginx.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-install-openssl.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-install-pandoc.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-is-web-component-installed.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-manage-https.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-nginx-admin.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-toggle-all-web-wizardry.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-uninstall-acme.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-uninstall-fcgiwrap.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-uninstall-htmx.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-uninstall-nginx.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-uninstall-openssl.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-uninstall-pandoc.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-update-htmx.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-web-wizardry-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.arcana/web-wizardry/test-web-wizardry-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/app/test-app-validate.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-blog-get-config.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-blog-index.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-blog-list-drafts.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-blog-save-post.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-blog-search.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-blog-set-theme.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-blog-tags.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-blog-theme.css.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-blog-update-config.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-calc.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-cgi-env.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-cleanup-inactive-avatars.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-count-avatars.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-create-avatar.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-create-room.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-delete-avatar.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-delete-room.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-get-messages.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-list-avatars.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-list-rooms.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-log-if-unique.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-move-avatar.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-rename-avatar.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-room-list-stream.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-send-message.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-stream.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-chat-unread-counts.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-color-picker.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-counter-reset.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-counter.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-debug-test.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-drag-drop-upload.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-echo-text.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-example-cgi.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-file-info.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-get-query-param.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-get-site-data-dir.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-http-cors.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-http-end-headers.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-http-error.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-http-header.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-http-ok-html.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-http-ok-json.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-http-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-list-system-files.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-parse-query.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-poll-vote.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-random-quote.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-reverse-text.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-save-note.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-sse-error.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-sse-event-id.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-sse-event.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-sse-padding.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-sse-retry.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-sse-start.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-ssh-auth-bind-webauthn.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-ssh-auth-check-session.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-ssh-auth-list-delegates.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-ssh-auth-login.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-ssh-auth-register-mud.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-ssh-auth-register.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-ssh-auth-revoke-delegate.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-system-info.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-temperature-convert.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-upload-image.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-url-decode.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-validate-room-name.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-validate-username.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cgi/test-word-count.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-empty.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-full.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-given.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-gone.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-has-ancestor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-has.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-is-path.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-is-posint.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-is.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-lacks.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-newer.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-no.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-nonempty.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-older.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-there.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-validate-mud-handle.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-within-range.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/cond/test-yes.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fmt/test-format-duration.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fmt/test-format-timestamp.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-backup-nix-config.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-backup.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-check-attribute-tool.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-cleanup-dir.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-cleanup-file.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-clip-copy.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-clip-paste.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-config-del.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-config-get.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-config-has.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-config-set.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-ensure-parent-dir.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-find-executable.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-get-attribute-batch.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-get-attribute.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-list-attributes.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-sed-inplace.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-set-attribute.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-temp-dir.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/fs/test-temp-file.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/hook/test-touch-hook.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-choose-input.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-prompt-with-fallback.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-read-line.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-require-command.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-tty-raw.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-tty-restore.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-tty-save.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-validate-command.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-validate-name.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-validate-number.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-validate-path.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/input/test-validate-player-name.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/lang/test-possessive.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/lex/test-and-then.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/lex/test-and.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/lex/test-disambiguate.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/lex/test-from.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/lex/test-into.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/lex/test-or.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/lex/test-parse.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/lex/test-to.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/menu/test-category-title.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/menu/test-cursor-blink.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/menu/test-divine-trash.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/menu/test-exit-label.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/menu/test-fathom-cursor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/menu/test-fathom-terminal.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/menu/test-is-installable.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/menu/test-is-integer.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/menu/test-is-submenu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/menu/test-move-cursor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/mud/test-colorize-player-name.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/mud/test-create-avatar.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/mud/test-damage-file.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/mud/test-deal-damage.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/mud/test-get-life.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/mud/test-incarnate.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/mud/test-move-avatar.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/mud/test-mud-defaults.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/mud/test-trigger-on-touch.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-debug.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-die.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-disable-palette.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-fail.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-first-of.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-heading-section.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-heading-separator.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-heading-simple.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-info.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-log-timestamp.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-ok.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-or-else.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-print-fail.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-print-pass.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-quiet.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-step.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-success.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-usage-error.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/out/test-warn.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/paths/test-abs-path.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/paths/test-ensure-dir.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/paths/test-file-name.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/paths/test-here.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/paths/test-norm-path.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/paths/test-parent.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/paths/test-path.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/paths/test-script-dir.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/paths/test-strip-trailing-slashes.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/paths/test-temp.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/paths/test-tilde-path.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/pkg/test-pkg-has.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/pkg/test-pkg-install.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/pkg/test-pkg-manager.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/pkg/test-pkg-remove.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/pkg/test-pkg-update.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/pkg/test-pkg-upgrade.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/str/test-contains.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/str/test-differs.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/str/test-ends.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/str/test-equals.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/str/test-lower.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/str/test-matches.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/str/test-seeks.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/str/test-starts.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/str/test-trim.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/str/test-upper.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-add-pkgin-to-path.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-any.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-ask-install-wizardry.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-clear-traps.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-clipboard-available.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-env-clear.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-env-or.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-invoke-thesaurus.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-invoke-wizardry.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-must.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-need.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-nix-rebuild.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-nix-shell-add.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-nix-shell-remove.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-nix-shell-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-now.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-on-exit.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-on.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-os.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-rc-add-line.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-rc-has-line.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-rc-remove-line.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-require-wizardry.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-require.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-spell-levels.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-term.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/sys/test-where.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/term/test-clear-line.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/term/test-redraw-prompt.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test-declare-globals.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-assert-equals.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-assert-error-contains.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-assert-failure.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-assert-file-contains.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-assert-output-contains.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-assert-path-exists.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-assert-path-missing.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-assert-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-assert-success.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-find-repo-root.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-finish-tests.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-init-test-counters.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-link-tools.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-make-fixture.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-make-tempdir.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-provide-basic-tools.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-record-failure-detail.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-report-result.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-run-bwrap.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-run-cmd.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-run-macos-sandbox.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-run-spell-in-dir.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-run-spell.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-run-test-case.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-skip-if-compiled.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-skip-if-uncompiled.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-ask-text-simple.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-ask-text.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-bin-dir.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-boolean.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-cleanup-file.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-colors.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-exit-label.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-failing-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-failing-require.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-forget-command.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-memorize-command.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-nix-env.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-pacman.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-require-command-simple.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-require-command.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-sudo.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-systemctl-simple.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-systemctl.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-temp-file.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-stub-xattr.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-test-fail.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-test-heading.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-test-lack.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-test-pass.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-test-skip.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-test-summary.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-write-apt-stub.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-write-command-stub.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-write-pkgin-stub.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/boot/test-write-sudo-stub.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-detect-test-environment.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-run-with-pty.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-socat-normalize-output.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-socat-pty.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-socat-send-keys.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-socat-test.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-stub-await-keypress-sequence.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-stub-await-keypress.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-stub-cursor-blink.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-stub-fathom-cursor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-stub-fathom-terminal.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-stub-move-cursor.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-stub-stty.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/test/test-test-bootstrap.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-append.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-count-chars.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-count-words.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-divine-indent-char.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-divine-indent-width.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-drop.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-each.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-field.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-first.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-last.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-lines.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-make-indent.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-pick.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-pluralize.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-read-file.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-skip.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-take.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.imps/text/test-write-file.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/desktop/test-app-launcher.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/desktop/test-build-appimage.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/desktop/test-build-apps.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/desktop/test-build-macapp.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/desktop/test-launch-app.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/desktop/test-list-apps.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/test-generate-glosses.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/test-profile-tests.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/test-spellbook-store.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/test-test-magic.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/test-test-spell.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/test-update-wizardry.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/test-validate-spells.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/.wizardry/test-verify-posix.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/arcane/test-copy.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/arcane/test-file-list.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/arcane/test-file-to-folder.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/arcane/test-forall.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/arcane/test-jump-trash.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/arcane/test-read-magic.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/arcane/test-trash.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-ask-number.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-ask-text.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-ask-yn.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-ask.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-await-keypress.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-browse.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-clear.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-colors.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-list-files.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-max-length.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-memorize.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-move.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-validate-ssh-key.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-wizard-cast.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/cantrips/test-wizard-eyes.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/common-tests.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/crypto/test-evoke-hash.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/crypto/test-hash.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/crypto/test-hashchant.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/divination/test-detect-distro.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/divination/test-detect-magic.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/divination/test-detect-posix.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/divination/test-detect-rc-file.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/divination/test-identify-room.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/enchant/test-disenchant.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/enchant/test-enchant.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/enchant/test-enchantment-to-yaml.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/enchant/test-yaml-to-enchantment.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/mud-admin/test-add-player.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/mud-admin/test-new-player.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/mud-admin/test-set-player.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-cast.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-install-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-main-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-mud-admin-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-mud-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-mud-settings.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-mud.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-network-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-priorities.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-priority-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-services-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-shutdown-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-spell-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-spellbook.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-synonym-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-system-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-thesaurus.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/menu/test-users-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-boot-player.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-check-cd-hook.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-choose-player.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-decorate.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-demo-multiplayer.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-greater-heal.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-heal.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-lesser-heal.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-listen.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-look.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-magic-missile.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-resurrect.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-say.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-shocking-grasp.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-stats.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/mud/test-think.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/priorities/test-deprioritize.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/priorities/test-get-card.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/priorities/test-get-new-priority.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/priorities/test-get-priority.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/priorities/test-prioritize.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/priorities/test-upvote.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/psi/test-list-contacts.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/psi/test-read-contact.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-add-synonym.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-bind-tome.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-compile-spell.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-delete-synonym.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-demo-magic.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-doppelganger.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-edit-synonym.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-erase-spell.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-forget.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-learn.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-lint-magic.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-merge-yaml-text.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-reset-default-synonyms.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-scribe-spell.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/spellcraft/test-unbind-tome.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-config.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-disable-service.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-enable-service.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-install-service-template.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-is-service-installed.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-kill-process.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-learn-spellbook.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-logs.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-package-managers.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-pocket-dimension.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-reload-ssh.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-remove-service.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-restart-service.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-restart-ssh.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-service-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-spell-level-coverage.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-start-service.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-stop-service.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/system/test-update-all.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/tasks/test-check.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/tasks/test-get-checked.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/tasks/test-rename-interactive.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/tasks/test-uncheck.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/test-install.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/test-tutorials.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/translocation/test-blink.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/translocation/test-close-portal.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/translocation/test-enchant-portkey.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/translocation/test-follow-portkey.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/translocation/test-go-up.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/translocation/test-jump-to-marker.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/translocation/test-mark-location.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/translocation/test-open-portal.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/translocation/test-open-teletype.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/wards/test-banish.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/wards/test-defcon.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/wards/test-ssh-barrier.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/wards/test-ward-system.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-build.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-change-site-port.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-check-https-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-configure-nginx.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-create-from-template.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-create-site-prompt.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-create-site.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-delete-site.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-diagnose-sse.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-disable-https.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-disable-site-daemon.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-enable-site-daemon.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-fix-site-security.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-https.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-is-site-daemon-enabled.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-manage-allowed-dirs.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-renew-https.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-repair-site-daemon.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-run-site-daemon.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-serve-site.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-setup-https.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-site-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-site-status.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-stop-site.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-template-menu.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-toggle-site-tor-hosting.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-update-from-template.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .tests/web/test-web-wizardry.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .AGENTS.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| README.md | 2026-02-06 | 🔍 Perused | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | 🟢 | Line 30 uses bash example | - |
| .github/.CONTRIBUTING.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/AUDIT.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/AUDIT_RESULTS.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/CODEX.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/CROSS_PLATFORM_PATTERNS.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/EMOJI_ANNOTATIONS.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/EXEMPTIONS.md | 2026-02-06 | 🔍 Perused | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 | 🟢 | None - thorough | - |
| .github/FULL_SPEC.md | 2026-02-06 | 🎯 Exhaustive | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 | 🟢 | None - comprehensive | - |
| .github/LESSONS.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/SHELL_CODE_PATTERNS.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/bootstrapping.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/compiled-testing.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/copilot-instructions.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/glossary-and-function-architecture.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/imps.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/interactive-spells.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/logging.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/spells.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/test-performance.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/testing-environment.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/tests.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .github/troubleshooting.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/README.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/includes/head.html | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/includes/nav.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/pages/about.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/pages/admin.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/pages/index.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/pages/posts/2024-01-15-welcome.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/pages/posts/2024-01-20-content-hashes.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/pages/posts/2024-01-25-shell-web.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/pages/posts/2024-01-28-version-tracking.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/pages/posts/2024-02-01-draft-example.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/pages/ssh-auth.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/pages/tags.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/style.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/adept.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/alchemist.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/archmage.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/chronomancer.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/conjurer.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/druid.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/empath.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/enchanter.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/geomancer.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/hermeticist.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/hierophant.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/illusionist.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/lich.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/necromancer.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/pyromancer.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/seer.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/shaman.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/sorcerer.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/sorceress.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/technomancer.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/thaumaturge.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/thelemite.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/theurgist.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/wadjet.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/warlock.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/blog/static/themes/wizard.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/README.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/includes/nav.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/about.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/chat.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/diagnostics.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/file-upload.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/forms-input.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/graphics-media.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/hardware.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/index.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/misc-apis.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/poll.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/security.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/storage.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/time-performance.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/ui-apis.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/pages/workers.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/demo/static/style.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/README.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/cgi/unix-action | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/cgi/unix-man | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/cgi/unix-roster | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/includes/nav.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/pages/configuration.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/pages/display-sessions.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/pages/index.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/pages/network.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/pages/services.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/pages/software.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/pages/storage.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/pages/system.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/pages/users.md | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/static/icons/configuration.svg | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/static/icons/display.svg | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/static/icons/network.svg | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/static/icons/services.svg | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/static/icons/software.svg | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/static/icons/storage.svg | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/static/icons/system.svg | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/static/icons/users.svg | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .templates/unix-settings/static/style.css | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/00_terminal.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/01_navigating.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/02_variables.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/03_quoting.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/04_comparison.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/05_conditionals.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/06_loops.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/07_functions.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/08_pipe.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/09_permissions.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/10_regex.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/11_debugging.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/12_aliases.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/13_eval.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/14_bg.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/15_advanced_terminal.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/16_parentheses.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/17_shebang.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/18_shell_options_basic.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/19_shell_options_advanced.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/20_backticks.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/21_env.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/22_history.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/23_best_practices.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/24_distribution.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/25_ssh.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/26_git.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/27_usability.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/28_posix_vs_bash.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/29_antipatterns.sh | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| tutorials/rosetta-stone | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
| .gitignore | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |


---

## Updating This Document

**For future audits:**

1. **Update the relevant table row** with:
   - New audit date in "Last Audit" column
   - Updated thoroughness level
   - New results in Code, Docs, Theme, Policy, Ethos columns
   - New issues or fixes if applicable
2. **Update executive summary** with new statistics
3. **Update critical issues and warnings sections** as needed

**Example update for a file:**

Before:
```
| spells/arcane/copy | 2026-02-06 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
```

After 2026-02-10 audit:
```
| spells/arcane/copy | 2026-02-10 | 📖 Read | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Not thoroughly reviewed (Read level) | - |
```

See [AUDIT.md](AUDIT.md) for complete audit framework and column descriptions.
