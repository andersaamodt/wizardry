# Wizardry Project Audit Results

**Audit Date:** 2026-02-06  
**Total Files Audited:** 1395  
**Audit Framework:** See [AUDIT.md](AUDIT.md)

## Executive Summary

This document contains the comprehensive audit results for all files in the Wizardry repository, systematically evaluated against the 21-section audit rubric defined in AUDIT.md.

### Statistics

| Metric | Count | Percentage |
|--------|-------|------------|
| **Overall Results** | | |
| 🟢 Pass | 526 | 37.7% |
| 🟡 Warning | 764 | 54.8% |
| 🔴 Fail | 49 | 3.5% |
| ⚪ N/A | 56 | 4.0% |
| **Code Quality** | | |
| 🟢 Pass | 796 | 57.1% |
| 🟡 Warning | 410 | 29.4% |
| 🔴 Fail | 49 | 3.5% |

### Legend

- 🟢 **Pass** - Meets all applicable audit standards
- 🟡 **Warning** - Minor issues that should be addressed
- 🔴 **Fail** - Significant issues requiring fixes
- ⚪ **N/A** - Not applicable to this file type
- 🔧 **Fixed** - Issue was resolved in this audit iteration

### Column Mapping

The audit rubric's 21 sections (184 checklist items) are compressed into these columns:

1. **Result** - Overall audit result (worst of all categories)
2. **Code** - Code Quality: Sections 7 (POSIX), 12-13 (Eng. Standards), 19 (Quality Metrics), 4 (Functions)
3. **Docs** - Comment Quality: Section 6 (Didacticism), opening comments, help text
4. **Theme** - Theming: Section 15 (Theming & Flavor), appropriate MUD vocabulary
5. **Policy** - No Policy Violations: Sections 3 (No Globals), 9-11 (Values/Policies/Tenets), 17 (Security)
6. **Issues** - Specific problems found during audit
7. **Fixes** - Changes made (🔧 indicates fixes applied)

---

## Critical Failures (🔴)

Files requiring immediate attention (49 total):


### `./.tests/.imps/cgi/test-chat-log-if-unique.sh`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Missing set -eu; Uses [[; No opening comment

### `./.tests/.wizardry/test-test-magic.sh`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Missing set -eu; Uses [[; No opening comment

### `./.tests/.wizardry/test-verify-posix.sh`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[; No opening comment

### `./.tests/cantrips/test-colors.sh`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Missing set -eu; Uses [[

### `./.tests/common-tests.sh`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[; Uses ==

### `./.tests/mud/test-listen.sh`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[

### `./.tests/spellcraft/test-lint-magic.sh`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[

### `./.tests/test-tutorials.sh`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[; Uses ==; No opening comment

### `./install`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses ==; No opening comment

### `./spells/.arcana/core/install-core`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Missing set -eu; Too many functions (5); No opening comment

### `./spells/.arcana/mud/toggle-all-mud`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses [[; No opening comment

### `./spells/.arcana/syncthing/install-syncthing`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses [[; No opening comment

### `./spells/.arcana/tor/configure-tor`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟡 | **Policy:** 🟢
- **Issues:** Uses ==; No opening comment

### `./spells/.arcana/tor/configure-tor-bridge`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses ==; No opening comment

### `./spells/.arcana/tor/install-tor`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses [[; No opening comment

### `./spells/.imps/cgi/chat-count-avatars`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[

### `./spells/.imps/cgi/chat-create-room`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[

### `./spells/.imps/cgi/chat-delete-room`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[

### `./spells/.imps/cgi/chat-get-messages`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[; Uses ==

### `./spells/.imps/cgi/chat-list-avatars`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[

### `./spells/.imps/cgi/chat-log-if-unique`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[

### `./spells/.imps/cgi/chat-room-list-stream`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Imp has functions

### `./spells/.imps/cgi/chat-stream`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Imp has functions

### `./spells/.imps/cgi/chat-unread-counts`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[; Imp has functions

### `./spells/.imps/cgi/drag-drop-upload`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Missing set -eu; Uses ==

### `./spells/.imps/cgi/url-decode`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses ==

### `./spells/.imps/fs/config-get`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses ==

### `./spells/.imps/fs/config-has`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses ==

### `./spells/.imps/menu/is-installable`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[

### `./spells/.imps/str/trim`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[

### `./spells/.imps/sys/nix-shell-add`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[

### `./spells/.imps/test/socat-normalize-output`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses [[

### `./spells/.imps/test/test-bootstrap`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Imp has functions

### `./spells/.imps/text/divine-indent-width`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** ⚪ | **Policy:** 🟢
- **Issues:** Uses ==

### `./spells/.wizardry/generate-glosses`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Too many functions (5)

### `./spells/.wizardry/profile-tests`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses ==

### `./spells/.wizardry/verify-posix`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses [[; Uses ==; No opening comment

### `./spells/cantrips/menu`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses [[; Too many functions (8); No opening comment

### `./spells/divination/detect-distro`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses ==; No opening comment

### `./spells/divination/detect-magic`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses ==; No opening comment

### `./spells/menu/mud-menu`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Missing set -eu; Uses [[; No opening comment

### `./spells/menu/spell-menu`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses [[

### `./spells/menu/spellbook`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses [[

### `./spells/mud/listen`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟢 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Missing set -eu; Uses [[

### `./spells/psi/list-contacts`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses [[; No opening comment

### `./spells/spellcraft/compile-spell`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses [[; Uses ==; No opening comment

### `./spells/spellcraft/lint-magic`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses [[; Uses ==; No opening comment

### `./spells/translocation/jump-to-marker`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Missing set -eu; Uses ==; No opening comment

### `./spells/wards/ward-system`

- **Result:** 🔴 | **Code:** 🔴 | **Docs:** 🟡 | **Theme:** 🟢 | **Policy:** 🟢
- **Issues:** Uses ==; Too many functions (6); No opening comment

---

## Warnings (🟡)

Files with minor issues needing attention (764 total, showing first 100):


- **`./.tests/.arcana/bitcoin/test-bitcoin-menu.sh`**: 🟡 | Code: 🟡 | Docs: 🟢 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu
- **`./.tests/.arcana/bitcoin/test-bitcoin-status.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/bitcoin/test-bitcoin.service.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/bitcoin/test-change-bitcoin-directory.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/bitcoin/test-configure-bitcoin.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/bitcoin/test-install-bitcoin.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/bitcoin/test-is-bitcoin-installed.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/bitcoin/test-is-bitcoin-running.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/bitcoin/test-repair-bitcoin-permissions.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/bitcoin/test-uninstall-bitcoin.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/bitcoin/test-wallet-menu.sh`**: 🟡 | Code: 🟡 | Docs: 🟢 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu
- **`./.tests/.arcana/core/test-core-menu.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-core-status.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-attr.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-awk.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-clipboard-helper.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-core.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-dd.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-find.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-git.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-grep.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-pkgin.sh`**: 🟡 | Code: 🟡 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu; No opening comment
- **`./.tests/.arcana/core/test-install-ps.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-sed.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-socat.sh`**: 🟡 | Code: 🟡 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu; No opening comment
- **`./.tests/.arcana/core/test-install-stty.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-tput.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-wl-clipboard.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-xclip.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-install-xsel.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-manage-system-command.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-uninstall-awk.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-uninstall-core.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-uninstall-find.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-uninstall-grep.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-uninstall-pkgin.sh`**: 🟡 | Code: 🟡 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu; No opening comment
- **`./.tests/.arcana/core/test-uninstall-ps.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-uninstall-sed.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/core/test-uninstall-socat.sh`**: 🟡 | Code: 🟡 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu; No opening comment
- **`./.tests/.arcana/lightning/test-configure-lightning.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/lightning/test-install-lightning.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/lightning/test-is-lightning-installed.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/lightning/test-is-lightning-running.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/lightning/test-lightning-menu.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/lightning/test-lightning-status.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/lightning/test-lightning-wallet-menu.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/lightning/test-lightning.service.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/lightning/test-repair-lightning-permissions.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/lightning/test-uninstall-lightning.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/mud/test-install-cd.sh`**: 🟡 | Code: 🟡 | Docs: 🟢 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu
- **`./.tests/.arcana/mud/test-install-mud.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/mud/test-install-sshfs.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/mud/test-load-cd-hook.sh`**: 🟡 | Code: 🟡 | Docs: 🟢 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu
- **`./.tests/.arcana/mud/test-load-touch-hook.sh`**: 🟡 | Code: 🟡 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu; No opening comment
- **`./.tests/.arcana/mud/test-mud-status.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/mud/test-sshfs-status.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/mud/test-toggle-all-mud.sh`**: 🟡 | Code: 🟡 | Docs: 🟢 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu
- **`./.tests/.arcana/mud/test-toggle-avatar.sh`**: 🟡 | Code: 🟡 | Docs: 🟢 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu
- **`./.tests/.arcana/mud/test-toggle-cd.sh`**: 🟡 | Code: 🟡 | Docs: 🟢 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu
- **`./.tests/.arcana/mud/test-toggle-listen.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/mud/test-toggle-mud-menu.sh`**: 🟡 | Code: 🟡 | Docs: 🟢 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu
- **`./.tests/.arcana/mud/test-toggle-parse.sh`**: 🟡 | Code: 🟡 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu; No opening comment
- **`./.tests/.arcana/mud/test-toggle-sshfs.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/mud/test-toggle-touch-hook.sh`**: 🟡 | Code: 🟡 | Docs: 🟢 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu
- **`./.tests/.arcana/mud/test-uninstall-sshfs.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/simplex-chat/test-install-simplex-chat.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/simplex-chat/test-simplex-chat-menu.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/simplex-chat/test-simplex-chat-status.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/simplex-chat/test-uninstall-simplex-chat.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-disable-syncthing-autostart.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-enable-syncthing-autostart.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-install-syncthing.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-is-syncthing-autostart-enabled.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-is-syncthing-installed.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-is-syncthing-running.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-open-syncthing.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-restart-syncthing.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-start-syncthing.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-stop-syncthing.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-syncthing-menu.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-syncthing-status.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/syncthing/test-uninstall-syncthing.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/test-import-arcanum.sh`**: 🟡 | Code: 🟡 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: Missing set -eu; No opening comment
- **`./.tests/.arcana/tor/test-configure-tor-bridge.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-configure-tor.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-create-tor-launchd-service.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-disable-tor-daemon.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-enable-tor-daemon.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-ensure-torrc-exists.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-install-libevent.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-install-openssl.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-install-tor.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-is-libevent-installed.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-is-openssl-installed.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-is-tor-daemon-enabled.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-is-tor-hidden-service-configured.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-is-tor-installed.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-is-tor-launchd-service-configured.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-is-tor-running.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment
- **`./.tests/.arcana/tor/test-remove-tor-hidden-service.sh`**: 🟡 | Code: 🟢 | Docs: 🟡 | Theme: ⚪ | Policy: 🟢 | Issues: No opening comment

---

## Complete Audit Table

This table contains all files in the repository with their audit results.

**Quick scan guidance:**
- Look for 🔴 (red) in any column - requires immediate fix
- Look for 🟡 (yellow) - should be addressed
- 🟢 (green) is good, ⚪ (white circle) is N/A
- 🔧 (wrench) in Fixes column means issue was resolved

| File | Date | Result | Code | Docs | Theme | Policy | Issues | Fixes |
|------|------|--------|------|------|-------|--------|--------|-------|

| `./.AGENTS.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.apps/.host/README.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.apps/.host/linux/main.c` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.apps/.host/macos/main.m` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.apps/README.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.apps/chatroom/index.html` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.apps/chatroom/settings.html` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.apps/menu-app/index.html` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.apps/menu-app/style.css` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.gitattributes` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.github/.CONTRIBUTING.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/AUDIT.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/CODEX.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/CROSS_PLATFORM_PATTERNS.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/EMOJI_ANNOTATIONS.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/EXEMPTIONS.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/FULL_SPEC.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/LESSONS.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/SHELL_CODE_PATTERNS.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/bootstrapping.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/catalog-emojis` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.github/compiled-testing.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/copilot-instructions.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/glossary-and-function-architecture.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/imps.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/interactive-spells.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/logging.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/read-test-failures` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.github/spells.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/test-performance.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/testing-environment.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/tests.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/troubleshooting.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/workflows/README.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.github/workflows/build-desktop-apps.yml` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.github/workflows/collect-failures.yml` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.github/workflows/compile.yml` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.github/workflows/demonstrate-wizardry.yml` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.github/workflows/emoji-observatory.yml` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.github/workflows/lint-posix.yml` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.github/workflows/test-doppelganger.yml` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.github/workflows/test-standalone-spells.yml` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.github/workflows/tests.yml` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.gitignore` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./.templates/blog/README.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/includes/head.html` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/includes/nav.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/pages/about.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/pages/admin.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/pages/index.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/pages/posts/2024-01-15-welcome.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/pages/posts/2024-01-20-content-hashes.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/pages/posts/2024-01-25-shell-web.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/pages/posts/2024-01-28-version-tracking.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/pages/posts/2024-02-01-draft-example.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/pages/ssh-auth.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/pages/tags.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/style.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/adept.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/alchemist.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/archmage.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/chronomancer.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/conjurer.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/druid.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/empath.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/enchanter.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/geomancer.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/hermeticist.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/hierophant.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/illusionist.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/lich.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/necromancer.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/pyromancer.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/seer.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/shaman.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/sorcerer.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/sorceress.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/technomancer.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/thaumaturge.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/thelemite.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/theurgist.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/wadjet.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/warlock.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/blog/static/themes/wizard.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/README.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/includes/nav.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/about.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/chat.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/diagnostics.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/file-upload.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/forms-input.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/graphics-media.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/hardware.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/index.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/misc-apis.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/poll.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/security.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/storage.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/time-performance.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/ui-apis.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/pages/workers.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.templates/demo/static/style.css` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./.tests/.arcana/bitcoin/test-bitcoin-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.arcana/bitcoin/test-bitcoin-status.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/bitcoin/test-bitcoin.service.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/bitcoin/test-change-bitcoin-directory.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/bitcoin/test-configure-bitcoin.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/bitcoin/test-install-bitcoin.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/bitcoin/test-is-bitcoin-installed.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/bitcoin/test-is-bitcoin-running.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/bitcoin/test-repair-bitcoin-permissions.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/bitcoin/test-uninstall-bitcoin.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/bitcoin/test-wallet-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.arcana/core/test-core-menu.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-core-status.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-attr.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-awk.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-bwrap.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/core/test-install-checkbashisms.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/core/test-install-clipboard-helper.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-core.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-dd.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-find.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-git.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-grep.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-pkgin.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/core/test-install-ps.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-sed.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-socat.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/core/test-install-stty.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-tput.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-wl-clipboard.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-xclip.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-install-xsel.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-manage-system-command.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-uninstall-awk.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-uninstall-bwrap.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/core/test-uninstall-checkbashisms.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/core/test-uninstall-clipboard-helper.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/core/test-uninstall-core.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-uninstall-dd.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/core/test-uninstall-find.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-uninstall-git.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/core/test-uninstall-grep.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-uninstall-pkgin.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/core/test-uninstall-ps.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-uninstall-sed.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/core/test-uninstall-socat.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/core/test-uninstall-stty.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/core/test-uninstall-tput.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/core/test-uninstall-wl-clipboard.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/core/test-uninstall-xclip.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/core/test-uninstall-xsel.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.arcana/lightning/test-configure-lightning.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/lightning/test-install-lightning.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/lightning/test-is-lightning-installed.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/lightning/test-is-lightning-running.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/lightning/test-lightning-menu.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/lightning/test-lightning-status.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/lightning/test-lightning-wallet-menu.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/lightning/test-lightning.service.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/lightning/test-repair-lightning-permissions.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/lightning/test-uninstall-lightning.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/mud/test-install-cd.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.arcana/mud/test-install-mud.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/mud/test-install-sshfs.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/mud/test-load-cd-hook.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.arcana/mud/test-load-touch-hook.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/mud/test-mud-status.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/mud/test-sshfs-status.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/mud/test-toggle-all-mud.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.arcana/mud/test-toggle-avatar.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.arcana/mud/test-toggle-cd.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.arcana/mud/test-toggle-listen.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/mud/test-toggle-mud-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.arcana/mud/test-toggle-parse.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/mud/test-toggle-sshfs.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/mud/test-toggle-touch-hook.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.arcana/mud/test-uninstall-sshfs.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/simplex-chat/test-install-simplex-chat.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/simplex-chat/test-simplex-chat-menu.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/simplex-chat/test-simplex-chat-status.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/simplex-chat/test-uninstall-simplex-chat.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-disable-syncthing-autostart.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-enable-syncthing-autostart.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-install-syncthing.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-is-syncthing-autostart-enabled.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-is-syncthing-installed.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-is-syncthing-running.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-open-syncthing.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-restart-syncthing.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-start-syncthing.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-stop-syncthing.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-syncthing-menu.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-syncthing-status.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/syncthing/test-uninstall-syncthing.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/test-import-arcanum.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/tor/test-configure-tor-bridge.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-configure-tor.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-create-tor-launchd-service.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-disable-tor-daemon.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-enable-tor-daemon.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-ensure-torrc-exists.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-install-libevent.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-install-openssl.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-install-tor.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-is-libevent-installed.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-is-openssl-installed.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-is-tor-daemon-enabled.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-is-tor-hidden-service-configured.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-is-tor-installed.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-is-tor-launchd-service-configured.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-is-tor-running.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-remove-tor-hidden-service.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-repair-tor-permissions.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-restart-tor.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-setup-tor.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-show-tor-log.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-show-tor-onion-address.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-start-tor.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-stop-tor.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-tor-bridge-status.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-tor-menu.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-tor-status.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-torrc-path.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-uninstall-libevent.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-uninstall-openssl.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/tor/test-uninstall-tor.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-install-acme.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-install-fcgiwrap.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-install-htmx.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-install-nginx.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-install-openssl.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-install-pandoc.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-is-web-component-installed.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-manage-https.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-nginx-admin.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-toggle-all-web-wizardry.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-uninstall-acme.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-uninstall-fcgiwrap.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-uninstall-htmx.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-uninstall-nginx.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-uninstall-openssl.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-uninstall-pandoc.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-update-htmx.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-web-wizardry-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.arcana/web-wizardry/test-web-wizardry-status.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.gitignore` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Non-shell |  |
| `./.tests/.imps/app/test-app-validate.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cgi/test-blog-get-config.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-blog-index.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-blog-list-drafts.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-blog-save-post.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-blog-search.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-blog-set-theme.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-blog-tags.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-blog-theme.css.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-blog-update-config.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-calc.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-cgi-env.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-cleanup-inactive-avatars.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/cgi/test-chat-count-avatars.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-create-avatar.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-create-room.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-delete-avatar.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-delete-room.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-get-messages.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-list-avatars.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/cgi/test-chat-list-rooms.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-log-if-unique.sh` | 2026-02-06 | 🔴 | 🔴 | 🟡 | ⚪ | 🟢 | Missing set -eu; Uses [[; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-move-avatar.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-rename-avatar.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-room-list-stream.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-send-message.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-stream.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-chat-unread-counts.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-color-picker.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-counter-reset.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-counter.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-debug-test.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-drag-drop-upload.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-echo-text.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-example-cgi.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-file-info.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-get-query-param.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-get-site-data-dir.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-http-cors.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-http-end-headers.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-http-error.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-http-header.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-http-ok-html.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-http-ok-json.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-http-status.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-list-system-files.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-parse-query.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-poll-vote.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-random-quote.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-reverse-text.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-save-note.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-sse-error.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-sse-event-id.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-sse-event.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-sse-padding.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-sse-retry.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-sse-start.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-ssh-auth-bind-webauthn.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-ssh-auth-check-session.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-ssh-auth-list-delegates.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-ssh-auth-login.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-ssh-auth-register-mud.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-ssh-auth-register.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-ssh-auth-revoke-delegate.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-system-info.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-temperature-convert.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-upload-image.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-url-decode.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-validate-room-name.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-validate-username.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cgi/test-word-count.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/cond/test-empty.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-full.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-given.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-gone.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-has-ancestor.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.imps/cond/test-has.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-is-path.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-is-posint.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-is.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-lacks.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-newer.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-no.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-nonempty.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-older.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-there.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-validate-mud-handle.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.imps/cond/test-within-range.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/cond/test-yes.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/fmt/test-format-duration.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/fmt/test-format-timestamp.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/fs/test-backup-nix-config.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-backup.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-check-attribute-tool.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-cleanup-dir.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-cleanup-file.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-clip-copy.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-clip-paste.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-config-del.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-config-get.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-config-has.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-config-set.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-ensure-parent-dir.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/fs/test-find-executable.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-get-attribute-batch.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/fs/test-get-attribute.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-list-attributes.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-sed-inplace.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-set-attribute.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-temp-dir.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/fs/test-temp-file.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/hook/test-touch-hook.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/input/test-choose-input.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/input/test-read-line.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/input/test-require-command.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/input/test-tty-raw.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/input/test-tty-restore.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/input/test-tty-save.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/input/test-validate-command.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/input/test-validate-name.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/input/test-validate-number.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/input/test-validate-path.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/input/test-validate-player-name.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/lang/test-possessive.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/lex/test-and-then.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/lex/test-and.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/lex/test-disambiguate.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/lex/test-from.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/lex/test-into.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/lex/test-or.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/lex/test-parse.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/lex/test-to.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/menu/test-category-title.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/menu/test-cursor-blink.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/menu/test-divine-trash.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/menu/test-exit-label.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/menu/test-fathom-cursor.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/menu/test-fathom-terminal.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/menu/test-is-installable.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/menu/test-is-integer.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/menu/test-is-submenu.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/menu/test-move-cursor.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/mud/test-colorize-player-name.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/mud/test-create-avatar.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/mud/test-damage-file.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/mud/test-deal-damage.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/mud/test-get-life.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/mud/test-incarnate.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/mud/test-move-avatar.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/mud/test-mud-defaults.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/mud/test-trigger-on-touch.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/out/test-debug.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-die.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-disable-palette.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-fail.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-first-of.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-heading-section.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/out/test-heading-separator.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/out/test-heading-simple.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/out/test-info.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-log-timestamp.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/out/test-ok.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-or-else.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-print-fail.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/out/test-print-pass.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/out/test-quiet.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-step.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-success.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-usage-error.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/out/test-warn.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/paths/test-abs-path.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/paths/test-ensure-dir.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/paths/test-file-name.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/paths/test-here.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/paths/test-norm-path.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/paths/test-parent.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/paths/test-path.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/paths/test-script-dir.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/paths/test-strip-trailing-slashes.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/paths/test-temp.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/paths/test-tilde-path.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/pkg/test-pkg-has.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/pkg/test-pkg-install.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/pkg/test-pkg-manager.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/pkg/test-pkg-remove.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/pkg/test-pkg-update.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/pkg/test-pkg-upgrade.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/str/test-contains.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/str/test-differs.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/str/test-ends.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/str/test-equals.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/str/test-lower.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/str/test-matches.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/str/test-seeks.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/str/test-starts.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/str/test-trim.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/str/test-upper.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-add-pkgin-to-path.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/sys/test-any.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-ask-install-wizardry.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-clear-traps.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-clipboard-available.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-env-clear.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-env-or.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-invoke-thesaurus.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-invoke-wizardry.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-must.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-need.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-nix-rebuild.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-nix-shell-add.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-nix-shell-remove.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-nix-shell-status.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-now.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-on-exit.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-on.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-os.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-rc-add-line.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-rc-has-line.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-rc-remove-line.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-require-wizardry.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-require.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-spell-levels.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-term.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/sys/test-where.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/term/test-clear-line.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/term/test-redraw-prompt.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.imps/test-declare-globals.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-assert-equals.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-assert-error-contains.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-assert-failure.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-assert-file-contains.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-assert-output-contains.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-assert-path-exists.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-assert-path-missing.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-assert-status.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-assert-success.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-find-repo-root.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-finish-tests.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-init-test-counters.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/test/boot/test-link-tools.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-make-fixture.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-make-tempdir.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-provide-basic-tools.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-record-failure-detail.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-report-result.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-run-bwrap.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-run-cmd.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-run-macos-sandbox.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-run-spell-in-dir.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-run-spell.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-run-test-case.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-skip-if-compiled.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/test/boot/test-skip-if-uncompiled.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/test/boot/test-stub-ask-text-simple.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-ask-text.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-bin-dir.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-boolean.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-cleanup-file.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-colors.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-exit-label.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-failing-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-failing-require.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-forget-command.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/test/boot/test-stub-memorize-command.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-nix-env.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-pacman.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-require-command-simple.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-require-command.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-status.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-sudo.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-systemctl-simple.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-systemctl.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-temp-file.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-stub-xattr.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-test-fail.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-test-heading.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-test-lack.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-test-pass.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-test-skip.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-test-summary.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-write-apt-stub.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-write-command-stub.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-write-pkgin-stub.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/boot/test-write-sudo-stub.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/test-detect-test-environment.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/test/test-run-with-pty.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/test/test-socat-normalize-output.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/test/test-socat-pty.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/test/test-socat-send-keys.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/test/test-socat-test.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.imps/test/test-stub-await-keypress-sequence.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/test-stub-await-keypress.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/test-stub-cursor-blink.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/test-stub-fathom-cursor.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/test-stub-fathom-terminal.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/test-stub-move-cursor.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/test-stub-stty.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/test/test-test-bootstrap.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-append.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-count-chars.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-count-words.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-divine-indent-char.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-divine-indent-width.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-drop.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-each.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-field.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-first.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-last.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-lines.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-make-indent.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-pick.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-pluralize.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-read-file.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-skip.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-take.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.imps/text/test-write-file.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.wizardry/desktop/test-app-launcher.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.wizardry/desktop/test-build-appimage.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.wizardry/desktop/test-build-apps.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.wizardry/desktop/test-build-macapp.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.wizardry/desktop/test-launch-app.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.wizardry/desktop/test-list-apps.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.wizardry/test-generate-glosses.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/.wizardry/test-profile-tests.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.wizardry/test-spellbook-store.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/.wizardry/test-test-magic.sh` | 2026-02-06 | 🔴 | 🔴 | 🟡 | ⚪ | 🟢 | Missing set -eu; Uses [[; No opening comment |  |
| `./.tests/.wizardry/test-test-spell.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.wizardry/test-update-wizardry.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/.wizardry/test-validate-spells.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/.wizardry/test-verify-posix.sh` | 2026-02-06 | 🔴 | 🔴 | 🟡 | ⚪ | 🟢 | Uses [[; No opening comment |  |
| `./.tests/arcane/test-copy.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/arcane/test-file-list.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/arcane/test-file-to-folder.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/arcane/test-forall.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/arcane/test-jump-trash.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/arcane/test-read-magic.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/arcane/test-trash.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/cantrips/test-ask-number.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/cantrips/test-ask-text.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/cantrips/test-ask-yn.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/cantrips/test-ask.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/cantrips/test-await-keypress.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/cantrips/test-browse.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/cantrips/test-clear.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/cantrips/test-colors.sh` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Missing set -eu; Uses [[ |  |
| `./.tests/cantrips/test-list-files.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/cantrips/test-max-length.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/cantrips/test-memorize.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/cantrips/test-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/cantrips/test-move.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/cantrips/test-validate-ssh-key.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/cantrips/test-wizard-cast.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/cantrips/test-wizard-eyes.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/common-tests.sh` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[; Uses == |  |
| `./.tests/crypto/test-evoke-hash.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/crypto/test-hash.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/crypto/test-hashchant.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/divination/test-detect-distro.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/divination/test-detect-magic.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/divination/test-detect-posix.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/divination/test-detect-rc-file.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/divination/test-identify-room.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/enchant/test-disenchant.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/enchant/test-enchant.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/enchant/test-enchantment-to-yaml.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/enchant/test-yaml-to-enchantment.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/menu/mud-admin/test-add-player.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/menu/mud-admin/test-new-player.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/menu/mud-admin/test-set-player.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/menu/test-cast.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/menu/test-install-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/menu/test-main-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/menu/test-mud-admin-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/menu/test-mud-menu.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/menu/test-mud-settings.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/menu/test-mud.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/menu/test-network-menu.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/menu/test-priorities.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/menu/test-priority-menu.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/menu/test-services-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/menu/test-shutdown-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/menu/test-spell-menu.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/menu/test-spellbook.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/menu/test-synonym-menu.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/menu/test-system-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/menu/test-thesaurus.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/menu/test-users-menu.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/mud/test-boot-player.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/mud/test-check-cd-hook.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/mud/test-choose-player.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/mud/test-decorate.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/mud/test-demo-multiplayer.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/mud/test-greater-heal.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/mud/test-heal.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/mud/test-lesser-heal.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/mud/test-listen.sh` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[ |  |
| `./.tests/mud/test-look.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/mud/test-magic-missile.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/mud/test-resurrect.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/mud/test-say.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/mud/test-shocking-grasp.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/mud/test-stats.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/mud/test-think.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/priorities/test-deprioritize.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/priorities/test-get-card.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/priorities/test-get-new-priority.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/priorities/test-get-priority.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/priorities/test-prioritize.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/priorities/test-upvote.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/psi/test-list-contacts.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/psi/test-read-contact.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/spellcraft/test-add-synonym.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/spellcraft/test-bind-tome.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/spellcraft/test-compile-spell.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/spellcraft/test-delete-synonym.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/spellcraft/test-demo-magic.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/spellcraft/test-doppelganger.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/spellcraft/test-edit-synonym.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/spellcraft/test-erase-spell.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/spellcraft/test-forget.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/spellcraft/test-learn.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/spellcraft/test-lint-magic.sh` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[ |  |
| `./.tests/spellcraft/test-merge-yaml-text.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/spellcraft/test-reset-default-synonyms.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/spellcraft/test-scribe-spell.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/spellcraft/test-unbind-tome.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-config.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/system/test-disable-service.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-enable-service.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-install-service-template.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/system/test-is-service-installed.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/system/test-kill-process.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-learn-spellbook.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/system/test-logs.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-package-managers.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-pocket-dimension.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/system/test-reload-ssh.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-remove-service.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/system/test-restart-service.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-restart-ssh.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-service-status.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-spell-level-coverage.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/system/test-start-service.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-stop-service.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/system/test-update-all.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/tasks/test-check.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/tasks/test-get-checked.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/tasks/test-rename-interactive.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/tasks/test-uncheck.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/test-install.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/test-tutorials.sh` | 2026-02-06 | 🔴 | 🔴 | 🟡 | ⚪ | 🟢 | Uses [[; Uses ==; No opening comment |  |
| `./.tests/translocation/test-blink.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/translocation/test-close-portal.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/translocation/test-enchant-portkey.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/translocation/test-follow-portkey.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/translocation/test-go-up.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/translocation/test-jump-to-marker.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/translocation/test-mark-location.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/translocation/test-open-portal.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/translocation/test-open-teletype.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/wards/test-banish.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/wards/test-ssh-barrier.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/wards/test-ward-system.sh` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./.tests/web/test-build.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-change-site-port.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-check-https-status.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-configure-nginx.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-create-from-template.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/web/test-create-site-prompt.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-create-site.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-delete-site.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-diagnose-sse.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-disable-https.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-https.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-renew-https.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-serve-site.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-setup-https.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-site-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-site-status.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/web/test-stop-site.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./.tests/web/test-template-menu.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/web/test-toggle-site-tor-hosting.sh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | ⚪ | 🟢 | No opening comment |  |
| `./.tests/web/test-update-from-template.sh` | 2026-02-06 | 🟡 | 🟡 | 🟡 | ⚪ | 🟢 | Missing set -eu; No opening comment |  |
| `./.tests/web/test-web-wizardry.sh` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./LICENSE` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./OATH` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./README.md` | 2026-02-06 | 🟢 | ⚪ | ⚪ | 🟢 | 🟢 |  |  |
| `./install` | 2026-02-06 | 🔴 | 🔴 | 🟡 | ⚪ | 🟢 | Uses ==; No opening comment |  |
| `./spells/.arcana/bitcoin/bitcoin-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/bitcoin/bitcoin-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/bitcoin/bitcoin.service` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Non-shell |  |
| `./spells/.arcana/bitcoin/change-bitcoin-directory` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/bitcoin/configure-bitcoin` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/bitcoin/install-bitcoin` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/bitcoin/is-bitcoin-installed` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/bitcoin/is-bitcoin-running` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/bitcoin/repair-bitcoin-permissions` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/bitcoin/uninstall-bitcoin` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/bitcoin/wallet-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/core-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/core-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-attr` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-awk` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-bwrap` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-checkbashisms` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-clipboard-helper` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-core` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Missing set -eu; Too many functions (5); No opening comment |  |
| `./spells/.arcana/core/install-dd` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-find` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-git` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-grep` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-pkgin` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-ps` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-sed` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-socat` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-stty` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-tput` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-wl-clipboard` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-xclip` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/install-xsel` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/manage-system-command` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-awk` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-bwrap` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-checkbashisms` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-clipboard-helper` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-core` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟢 | 🟢 | Missing set -eu; No opening comment |  |
| `./spells/.arcana/core/uninstall-dd` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-find` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-git` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-grep` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-pkgin` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-ps` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-sed` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-socat` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-stty` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-tput` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-wl-clipboard` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-xclip` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/core/uninstall-xsel` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/import-arcanum` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/lightning/configure-lightning` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/lightning/install-lightning` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/lightning/is-lightning-installed` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/lightning/is-lightning-running` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/lightning/lightning-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/lightning/lightning-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/lightning/lightning-wallet-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/lightning/lightning.service` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Non-shell |  |
| `./spells/.arcana/lightning/repair-lightning-permissions` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/lightning/uninstall-lightning` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/mud/install-cd` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/mud/install-mud` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/mud/install-sshfs` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 |  |  |
| `./spells/.arcana/mud/load-cd-hook` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟢 | 🟢 | Missing set -eu; No opening comment |  |
| `./spells/.arcana/mud/load-touch-hook` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟢 | 🟢 | Missing set -eu; No opening comment |  |
| `./spells/.arcana/mud/mud-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/mud/sshfs-status` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 |  |  |
| `./spells/.arcana/mud/toggle-all-mud` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses [[; No opening comment |  |
| `./spells/.arcana/mud/toggle-avatar` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/mud/toggle-cd` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟢 | 🟢 | Missing set -eu; No opening comment |  |
| `./spells/.arcana/mud/toggle-listen` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟢 | 🟢 | Missing set -eu; No opening comment |  |
| `./spells/.arcana/mud/toggle-mud-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/mud/toggle-parse` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/mud/toggle-sshfs` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 |  |  |
| `./spells/.arcana/mud/toggle-touch-hook` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/mud/uninstall-sshfs` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 |  |  |
| `./spells/.arcana/simplex-chat/install-simplex-chat` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/simplex-chat/simplex-chat-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/simplex-chat/simplex-chat-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/simplex-chat/uninstall-simplex-chat` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/syncthing/disable-syncthing-autostart` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/syncthing/enable-syncthing-autostart` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/syncthing/install-syncthing` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses [[; No opening comment |  |
| `./spells/.arcana/syncthing/is-syncthing-autostart-enabled` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟡 | 🟢 | Missing set -eu; No opening comment |  |
| `./spells/.arcana/syncthing/is-syncthing-installed` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟡 | 🟢 | Missing set -eu; No opening comment |  |
| `./spells/.arcana/syncthing/is-syncthing-running` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟡 | 🟢 | Missing set -eu; No opening comment |  |
| `./spells/.arcana/syncthing/open-syncthing` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/syncthing/restart-syncthing` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/syncthing/start-syncthing` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/syncthing/stop-syncthing` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/syncthing/syncthing-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/syncthing/syncthing-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/syncthing/uninstall-syncthing` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/configure-tor` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟡 | 🟢 | Uses ==; No opening comment |  |
| `./spells/.arcana/tor/configure-tor-bridge` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses ==; No opening comment |  |
| `./spells/.arcana/tor/create-tor-launchd-service` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/disable-tor-daemon` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/enable-tor-daemon` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/ensure-torrc-exists` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/install-libevent` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/install-openssl` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/install-tor` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses [[; No opening comment |  |
| `./spells/.arcana/tor/is-libevent-installed` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/is-openssl-installed` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/is-tor-daemon-enabled` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/is-tor-hidden-service-configured` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/is-tor-installed` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/is-tor-launchd-service-configured` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/is-tor-running` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/remove-tor-hidden-service` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/repair-tor-permissions` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/restart-tor` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 |  |  |
| `./spells/.arcana/tor/setup-tor` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/show-tor-log` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/show-tor-onion-address` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 |  |  |
| `./spells/.arcana/tor/start-tor` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 |  |  |
| `./spells/.arcana/tor/stop-tor` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 |  |  |
| `./spells/.arcana/tor/tor-bridge-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/tor-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/tor-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/torrc-path` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/uninstall-libevent` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/uninstall-openssl` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/tor/uninstall-tor` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/install-acme` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/install-fcgiwrap` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/install-htmx` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/install-nginx` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/install-openssl` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/install-pandoc` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/is-web-component-installed` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟡 | 🟢 | Missing set -eu; No opening comment |  |
| `./spells/.arcana/web-wizardry/manage-https` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/nginx-admin` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/toggle-all-web-wizardry` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/uninstall-acme` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/uninstall-fcgiwrap` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/uninstall-htmx` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/uninstall-nginx` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/uninstall-openssl` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/uninstall-pandoc` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/update-htmx` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/web-wizardry-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.arcana/web-wizardry/web-wizardry-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.imps/.gitkeep` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Non-shell |  |
| `./spells/.imps/app/app-validate` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/blog-get-config` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/blog-index` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/blog-list-drafts` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/blog-save-post` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/blog-search` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/blog-set-theme` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/blog-tags` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/blog-theme.css` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/blog-update-config` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/calc` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/cgi-env` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/chat-cleanup-inactive-avatars` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/cgi/chat-count-avatars` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[ |  |
| `./spells/.imps/cgi/chat-create-avatar` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/chat-create-room` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[ |  |
| `./spells/.imps/cgi/chat-delete-avatar` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/chat-delete-room` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[ |  |
| `./spells/.imps/cgi/chat-get-messages` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[; Uses == |  |
| `./spells/.imps/cgi/chat-list-avatars` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[ |  |
| `./spells/.imps/cgi/chat-list-rooms` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/chat-log-if-unique` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[ |  |
| `./spells/.imps/cgi/chat-move-avatar` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/chat-rename-avatar` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/chat-room-list-stream` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Imp has functions |  |
| `./spells/.imps/cgi/chat-send-message` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/chat-stream` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Imp has functions |  |
| `./spells/.imps/cgi/chat-unread-counts` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[; Imp has functions |  |
| `./spells/.imps/cgi/color-picker` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/counter` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/counter-reset` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/debug-test` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/drag-drop-upload` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Missing set -eu; Uses == |  |
| `./spells/.imps/cgi/echo-text` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/example-cgi` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/file-info` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/get-query-param` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/get-site-data-dir` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/http-cors` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/http-end-headers` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/http-error` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/http-header` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/http-ok-html` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/http-ok-json` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/http-status` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/list-system-files` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/parse-query` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/poll-vote` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/random-quote` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/reverse-text` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/save-note` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/sse-error` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/sse-event` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/sse-event-id` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/sse-padding` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/sse-retry` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/sse-start` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/ssh-auth-bind-webauthn` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/ssh-auth-check-session` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/ssh-auth-list-delegates` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/ssh-auth-login` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/ssh-auth-register` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/ssh-auth-register-mud` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/ssh-auth-revoke-delegate` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/system-info` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/temperature-convert` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/upload-image` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cgi/url-decode` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses == |  |
| `./spells/.imps/cgi/validate-room-name` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/cgi/validate-username` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/cgi/word-count` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/empty` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/full` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/given` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/gone` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/has` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/has-ancestor` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/is` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/is-path` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/is-posint` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/lacks` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/newer` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/no` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/nonempty` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/older` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/there` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/validate-mud-handle` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/within-range` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/cond/yes` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/declare-globals` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/fmt/format-duration` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fmt/format-timestamp` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/backup` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/backup-nix-config` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/check-attribute-tool` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/cleanup-dir` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/cleanup-file` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/clip-copy` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/clip-paste` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/config-del` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/config-get` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses == |  |
| `./spells/.imps/fs/config-has` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses == |  |
| `./spells/.imps/fs/config-set` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/ensure-parent-dir` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/find-executable` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/get-attribute` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/get-attribute-batch` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/list-attributes` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/sed-inplace` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/set-attribute` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/temp-dir` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/fs/temp-file` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/hook/touch-hook` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/input/choose-input` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/input/read-line` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/input/require-command` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/input/tty-raw` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/input/tty-restore` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/input/tty-save` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/input/validate-command` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/input/validate-name` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/input/validate-number` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/input/validate-path` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/input/validate-player-name` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/lang/possessive` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/lex/and` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/lex/and-then` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/lex/disambiguate` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/lex/from` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/lex/into` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/lex/or` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/lex/parse` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/lex/to` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/menu/category-title` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/menu/cursor-blink` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/menu/divine-trash` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/menu/exit-label` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/menu/fathom-cursor` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/menu/fathom-terminal` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/menu/is-installable` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[ |  |
| `./spells/.imps/menu/is-integer` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/menu/is-submenu` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/menu/move-cursor` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/mud/colorize-player-name` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/mud/create-avatar` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/mud/damage-file` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/mud/deal-damage` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/mud/get-life` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/mud/incarnate` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/mud/move-avatar` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/mud/mud-defaults` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/mud/trigger-on-touch` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/debug` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/die` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/disable-palette` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/fail` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/first-of` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/heading-section` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/heading-separator` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/heading-simple` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/info` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/log-timestamp` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/ok` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/or-else` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/print-fail` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/print-pass` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/quiet` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/step` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/success` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/usage-error` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/out/warn` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/paths/abs-path` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/paths/ensure-dir` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/paths/file-name` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/paths/here` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/paths/norm-path` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/paths/parent` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/paths/path` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/paths/script-dir` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/paths/strip-trailing-slashes` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/paths/temp` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/paths/tilde-path` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/pkg/pkg-has` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/pkg/pkg-install` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/pkg/pkg-manager` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/pkg/pkg-remove` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/pkg/pkg-update` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/pkg/pkg-upgrade` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/str/contains` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/str/differs` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/str/ends` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/str/equals` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/str/lower` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/str/matches` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/str/seeks` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/str/starts` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/str/trim` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[ |  |
| `./spells/.imps/str/upper` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/add-pkgin-to-path` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/any` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/ask-install-wizardry` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/clear-traps` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/clipboard-available` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/sys/env-clear` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/sys/env-or` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/invoke-thesaurus` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/sys/invoke-wizardry` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/sys/must` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/need` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/nix-rebuild` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/nix-shell-add` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[ |  |
| `./spells/.imps/sys/nix-shell-remove` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/nix-shell-status` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/now` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/on` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/sys/on-exit` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/os` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/rc-add-line` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/rc-has-line` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/sys/rc-remove-line` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/require` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/require-wizardry` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/spell-levels` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/sys/term` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/sys/where` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/term/clear-line` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/term/redraw-prompt` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/assert-equals` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/assert-error-contains` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/assert-failure` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/assert-file-contains` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/assert-output-contains` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/assert-path-exists` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/assert-path-missing` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/assert-status` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/assert-success` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/find-repo-root` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/finish-tests` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/init-test-counters` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/link-tools` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/make-fixture` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/make-tempdir` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/provide-basic-tools` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/record-failure-detail` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/report-result` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/run-bwrap` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/run-cmd` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/run-macos-sandbox` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/run-spell` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/run-spell-in-dir` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/run-test-case` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/skip-if-compiled` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/test/boot/skip-if-uncompiled` | 2026-02-06 | 🟡 | 🟡 | 🟢 | ⚪ | 🟢 | Missing set -eu |  |
| `./spells/.imps/test/boot/stub-ask-text` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-ask-text-simple` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-bin-dir` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-boolean` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-cleanup-file` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-colors` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-exit-label` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-failing-menu` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-failing-require` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-forget-command` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-memorize-command` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-menu` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-nix-env` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-pacman` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-require-command` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-require-command-simple` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-status` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-sudo` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-systemctl` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-systemctl-simple` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-temp-file` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/stub-xattr` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/test-fail` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/test-heading` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/test-lack` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/test-pass` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/test-skip` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/test-summary` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/write-apt-stub` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/write-command-stub` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/write-pkgin-stub` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/boot/write-sudo-stub` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/detect-test-environment` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/run-with-pty` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/socat-normalize-output` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses [[ |  |
| `./spells/.imps/test/socat-pty` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/socat-send-keys` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/socat-test` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/stub-await-keypress` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/stub-await-keypress-sequence` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/stub-cursor-blink` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/stub-fathom-cursor` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/stub-fathom-terminal` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/stub-move-cursor` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/stub-stty` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/test/test-bootstrap` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Imp has functions |  |
| `./spells/.imps/text/append` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/count-chars` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/count-words` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/divine-indent-char` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/divine-indent-width` | 2026-02-06 | 🔴 | 🔴 | 🟢 | ⚪ | 🟢 | Uses == |  |
| `./spells/.imps/text/drop` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/each` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/field` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/first` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/last` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/lines` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/make-indent` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/pick` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/pluralize` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/read-file` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/skip` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/take` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.imps/text/write-file` | 2026-02-06 | 🟢 | 🟢 | 🟢 | ⚪ | 🟢 |  |  |
| `./spells/.wizardry/desktop/app-launcher` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/.wizardry/desktop/build-appimage` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.wizardry/desktop/build-apps` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.wizardry/desktop/build-macapp` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.wizardry/desktop/launch-app` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.wizardry/desktop/list-apps` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/.wizardry/generate-glosses` | 2026-02-06 | 🔴 | 🔴 | 🟢 | 🟢 | 🟢 | Too many functions (5) |  |
| `./spells/.wizardry/profile-tests` | 2026-02-06 | 🔴 | 🔴 | 🟢 | 🟢 | 🟢 | Uses == |  |
| `./spells/.wizardry/spellbook-store` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.wizardry/test-magic` | 2026-02-06 | 🟡 | 🟡 | 🟢 | 🟢 | 🟢 | Uses [[; Many functions (3) |  |
| `./spells/.wizardry/test-spell` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/.wizardry/update-wizardry` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.wizardry/validate-spells` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/.wizardry/verify-posix` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses [[; Uses ==; No opening comment |  |
| `./spells/arcane/copy` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/arcane/file-list` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/arcane/file-to-folder` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/arcane/forall` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/arcane/jump-trash` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/arcane/read-magic` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/arcane/trash` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/cantrips/ask` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/cantrips/ask-number` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/cantrips/ask-text` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/cantrips/ask-yn` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/cantrips/await-keypress` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟢 | 🟢 | Many functions (3); No opening comment |  |
| `./spells/cantrips/browse` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/cantrips/clear` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/cantrips/colors` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/cantrips/list-files` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/cantrips/max-length` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/cantrips/memorize` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/cantrips/menu` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses [[; Too many functions (8); No opening comment |  |
| `./spells/cantrips/move` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/cantrips/validate-ssh-key` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/cantrips/wizard-cast` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/cantrips/wizard-eyes` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/crypto/evoke-hash` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/crypto/hash` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/crypto/hashchant` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/divination/detect-distro` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses ==; No opening comment |  |
| `./spells/divination/detect-magic` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses ==; No opening comment |  |
| `./spells/divination/detect-posix` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/divination/detect-rc-file` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/divination/identify-room` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟢 | 🟢 | Many functions (3); No opening comment |  |
| `./spells/enchant/disenchant` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/enchant/enchant` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/enchant/enchantment-to-yaml` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/enchant/yaml-to-enchantment` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/menu/cast` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/menu/install-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/menu/main-menu` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟢 | 🟢 | Missing set -eu; No opening comment |  |
| `./spells/menu/mud` | 2026-02-06 | 🟡 | 🟡 | 🟢 | 🟢 | 🟢 | Missing set -eu |  |
| `./spells/menu/mud-admin-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/menu/mud-admin/add-player` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/menu/mud-admin/new-player` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/menu/mud-admin/set-player` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/menu/mud-menu` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Missing set -eu; Uses [[; No opening comment |  |
| `./spells/menu/mud-settings` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟢 | 🟢 | Missing set -eu; No opening comment |  |
| `./spells/menu/network-menu` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟡 | 🟢 |  |  |
| `./spells/menu/priorities` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/menu/priority-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/menu/services-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/menu/shutdown-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/menu/spell-menu` | 2026-02-06 | 🔴 | 🔴 | 🟢 | 🟢 | 🟢 | Uses [[ |  |
| `./spells/menu/spellbook` | 2026-02-06 | 🔴 | 🔴 | 🟢 | 🟢 | 🟢 | Uses [[ |  |
| `./spells/menu/synonym-menu` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/menu/system-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/menu/thesaurus` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/menu/users-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/boot-player` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/check-cd-hook` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/choose-player` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/decorate` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/demo-multiplayer` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/mud/greater-heal` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/heal` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/lesser-heal` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/listen` | 2026-02-06 | 🔴 | 🔴 | 🟢 | 🟢 | 🟢 | Missing set -eu; Uses [[ |  |
| `./spells/mud/look` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/magic-missile` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/resurrect` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/say` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/shocking-grasp` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/stats` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/mud/think` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/priorities/deprioritize` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/priorities/get-card` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/priorities/get-new-priority` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/priorities/get-priority` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/priorities/prioritize` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/priorities/upvote` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/psi/list-contacts` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses [[; No opening comment |  |
| `./spells/psi/read-contact` | 2026-02-06 | 🟡 | 🟡 | 🟡 | 🟡 | 🟢 | Many functions (3); No opening comment |  |
| `./spells/spellcraft/add-synonym` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/spellcraft/bind-tome` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/spellcraft/compile-spell` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses [[; Uses ==; No opening comment |  |
| `./spells/spellcraft/delete-synonym` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/spellcraft/demo-magic` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/spellcraft/doppelganger` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/spellcraft/edit-synonym` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/spellcraft/erase-spell` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/spellcraft/forget` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/spellcraft/learn` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/spellcraft/lint-magic` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses [[; Uses ==; No opening comment |  |
| `./spells/spellcraft/merge-yaml-text` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/spellcraft/reset-default-synonyms` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/spellcraft/scribe-spell` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/spellcraft/unbind-tome` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/config` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/disable-service` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/enable-service` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/install-service-template` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/is-service-installed` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/kill-process` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/learn-spellbook` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/logs` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/package-managers` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/pocket-dimension` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/system/reload-ssh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/remove-service` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/restart-service` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/restart-ssh` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/service-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/start-service` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/stop-service` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/system/update-all` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/tasks/check` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/tasks/get-checked` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/tasks/rename-interactive` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/tasks/uncheck` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/translocation/blink` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/translocation/close-portal` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/translocation/enchant-portkey` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/translocation/follow-portkey` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/translocation/go-up` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/translocation/jump-to-marker` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Missing set -eu; Uses ==; No opening comment |  |
| `./spells/translocation/mark-location` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/translocation/open-portal` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/translocation/open-teletype` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/wards/banish` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/wards/ssh-barrier` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/wards/ward-system` | 2026-02-06 | 🔴 | 🔴 | 🟡 | 🟢 | 🟢 | Uses ==; Too many functions (6); No opening comment |  |
| `./spells/web/build` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/web/change-site-port` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/web/check-https-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/configure-nginx` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/web/create-from-template` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/create-site` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/create-site-prompt` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/delete-site` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/diagnose-sse` | 2026-02-06 | 🟢 | 🟢 | 🟢 | 🟢 | 🟢 |  |  |
| `./spells/web/disable-https` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/https` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/web/renew-https` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/serve-site` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/web/setup-https` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./spells/web/site-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/site-status` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/stop-site` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/template-menu` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/toggle-site-tor-hosting` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/update-from-template` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟡 | 🟢 | No opening comment |  |
| `./spells/web/web-wizardry` | 2026-02-06 | 🟡 | 🟢 | 🟡 | 🟢 | 🟢 | No opening comment |  |
| `./tutorials/00_terminal.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/01_navigating.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/02_variables.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/03_quoting.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/04_comparison.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/05_conditionals.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/06_loops.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/07_functions.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/08_pipe.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/09_permissions.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/10_regex.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/11_debugging.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/12_aliases.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/13_eval.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/14_bg.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/15_advanced_terminal.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/16_parentheses.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/17_shebang.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/18_shell_options_basic.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/19_shell_options_advanced.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/20_backticks.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/21_env.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/22_history.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/23_best_practices.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/24_distribution.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/25_ssh.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/26_git.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/27_usability.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/28_posix_vs_bash.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/29_antipatterns.sh` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |
| `./tutorials/rosetta-stone` | 2026-02-06 | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | Unknown type |  |

---

## Audit Methodology

### Rubric Compression

The complete 184-item audit checklist from AUDIT.md is compressed into evaluable categories:

**Code Quality** encompasses:
- ✅ POSIX Compliance (Section 7): Shebang, set -eu, no bash-isms, proper quoting
- ✅ Engineering Standards Shell (Section 12): POSIX idioms, portable commands
- ✅ Engineering Standards Structure (Section 13): Function discipline, naming, structure
- ✅ Code Quality Metrics (Section 19): Line length, indentation, no dead code
- ✅ No Functions Policy (Section 4): Function count limits, linear flow

**Comment Quality** encompasses:
- ✅ Didacticism (Section 6): Well-commented code, opening comments, help text
- ✅ Spell Standards (Section 20): Opening description, --help handler
- ✅ Imp Standards (Section 21): Comment headers

**Theming** encompasses:
- ✅ Theming & Flavor (Section 15): Appropriate MUD vocabulary, not excessive

**Policy Compliance** encompasses:
- ✅ No Globals (Section 3): No env vars for coordination
- ✅ Values Alignment (Section 9): Useful, teaching, cross-platform
- ✅ Policies (Section 10): Non-commercial, FOSS-first, no AI integration
- ✅ Design Tenets (Section 11): Minimalism, atomicity, self-healing
- ✅ Security (Section 17): No secrets, input validation, safe operations

### Automated Checks

The audit uses automated analysis to detect:
- Shebang correctness (`#!/bin/sh`)
- Presence of `set -eu` (with exemptions for conditional imps)
- Bash-isms: `[[`, `==`, arrays, `local`, etc.
- Function count (spells: ≤3, imps: 0)
- Opening comments (line 2 should start with `#`)
- Help handlers (`--help`, `--usage`, `-h`)
- Basic theming presence (magical vocabulary)

### Manual Review Recommended

While automated checks catch many issues, manual review is still recommended for:
- Code complexity and readability
- Comment helpfulness and appropriateness
- Theming balance (not too much/little)
- Security concerns beyond basic patterns
- Cross-platform compatibility nuances
- Test coverage completeness

---

## Next Steps

### For 🔴 Critical Failures

1. Review each file listed in Critical Failures section
2. Address the specific issues noted
3. Re-run audit to verify fixes
4. Mark fixes with 🔧 in Fixes column
5. Update Last Audit date

### For 🟡 Warnings

1. Prioritize warnings in frequently-used spells/imps
2. Address issues systematically by category
3. Document any exemptions in EXEMPTIONS.md
4. Update audit results as fixes are applied

### For Ongoing Audits

1. Run audit before major releases
2. Check new files against rubric
3. Track metrics over time
4. Update LESSONS.md with insights
5. Refine rubric based on findings

---

*Last updated: 2026-02-06*

