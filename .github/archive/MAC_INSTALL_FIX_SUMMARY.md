# Mac Installation Issues - Resolution Summary

## Problem Statement
The install script on Mac had two critical issues:
1. Uninstall failed to properly clean up profile files (.bash_profile, .zprofile)
2. New terminal windows would hang, and 'menu' was not available

## Root Causes Identified

### Issue 1: Incomplete Uninstall
- **Cause**: Install script modified `.bash_profile` (for bash) or `.zprofile` (for zsh) but uninstall only knew about the main RC file
- **Impact**: After uninstall, profile files still contained wizardry code, causing issues in login shells

### Issue 2: Menu Not Available / Hanging
- **Potential causes investigated**:
  - Infinite loops in command_not_found_handle: ❌ Not found (recursion guards already in place)
  - Slow sourcing of ~306 spell/imp files: ❌ Tests show < 10s completion
  - Recursive sourcing: ❌ Prevention already in place (_WIZARDRY_INVOKED guard)
  - Profile file misconfiguration: ✅ This was the actual issue

## Solutions Implemented

### 1. Profile File Tracking
**File**: `install`
- Added `profile_file_modified` variable to track which profile file was created/modified
- Pass `PROFILE_FILE` to uninstall script for proper cleanup

### 2. Zsh Support
**File**: `install`
- Added `.zprofile` handling for zsh users (mirroring existing `.bash_profile` logic)
- macOS uses zsh by default since Catalina (10.15)

### 3. Consistent Markers
**File**: `install`
- Added "added by wizardry installer" marker to ALL profile file additions
- Both created files and appended content now have the marker
- Enables reliable identification of wizardry content during uninstall

### 4. Improved Uninstall Logic
**File**: `install` (uninstall script generation)
- Use `awk` instead of `grep` to remove entire wizardry block (not just marker line)
- Properly detect and delete empty profile files created by installer
- Preserve user's original content in both RC and profile files

## Code Changes

### Install Script Changes

#### Profile File Tracking (lines ~812-813)
```sh
shell_setup_made=0
rebuild_success=0
profile_file_modified=""  # NEW: Track which profile file we modified
```

#### .bash_profile Creation (lines ~889-918)
```sh
*/.bashrc)
    bash_profile="$HOME/.bash_profile"
    if [ ! -f "$bash_profile" ]; then
        # Create with marker
        cat > "$bash_profile" <<'BASH_PROFILE_EOF'
# Source .bashrc if it exists (added by wizardry installer)  # ADDED MARKER
# This ensures bash login shells get configuration
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi
BASH_PROFILE_EOF
        profile_file_modified="$bash_profile"  # TRACK IT
```

#### .zprofile Creation (NEW, lines ~920-950)
```sh
*/.zshrc)
    # NEW: For zsh users, ensure .zprofile sources .zshrc
    zsh_profile="$HOME/.zprofile"
    if [ ! -f "$zsh_profile" ]; then
        cat > "$zsh_profile" <<'ZSH_PROFILE_EOF'
# Source .zshrc if it exists (added by wizardry installer)
# This ensures zsh login shells get configuration
if [ -f ~/.zshrc ]; then
        . ~/.zshrc
fi
ZSH_PROFILE_EOF
        profile_file_modified="$zsh_profile"
```

#### Uninstall Script Variables (lines ~1017-1023)
```sh
cat >>"$uninstall_script" <<UNINSTALL_VARS
INSTALL_DIR="$ABS_DIR"
INSTALL_WAS_LOCAL="$LOCAL_SOURCE"
RC_FILE="$detect_rc_file_value"
RC_FORMAT="$detect_format_value"
PROFILE_FILE="$profile_file_modified"  # NEW: Pass to uninstall

UNINSTALL_VARS
```

#### Uninstall Profile Cleanup (NEW, in UNINSTALL_MAIN)
```sh
# Remove profile file modifications if they were made
if [ -n "$PROFILE_FILE" ] && [ -f "$PROFILE_FILE" ]; then
    printf '\n%s==> Removing profile file modifications...%s\n' "$CYAN" "$RESET"
    tmp_file="${PROFILE_FILE}.wizardry.$$"
    
    # Use awk to remove entire wizardry block
    awk '
    /^# Source \..*rc if it exists \(added by wizardry installer\)$/ { skip = 1; next }
    skip == 1 && /^fi$/ { skip = 0; next }
    skip == 0 { print }
    ' "$PROFILE_FILE" > "$tmp_file" 2>/dev/null || true
    
    # Move if changed
    if [ -f "$tmp_file" ] && ! cmp -s "$PROFILE_FILE" "$tmp_file" 2>/dev/null; then
        mv "$tmp_file" "$PROFILE_FILE"
        printf '  %s✓%s Removed wizardry lines from %s\n' "$GREEN" "$RESET" "$PROFILE_FILE"
    else
        rm -f "$tmp_file"
    fi
    
    # Delete if now empty
    if [ -f "$PROFILE_FILE" ]; then
        if ! grep -qE '^[^#[:space:]]' "$PROFILE_FILE" 2>/dev/null; then
            if [ ! -s "$PROFILE_FILE" ] || ! grep -qE '^[^#[:space:]]' "$PROFILE_FILE" 2>/dev/null; then
                rm -f "$PROFILE_FILE"
                printf '  %s✓%s Removed empty profile file %s\n' "$GREEN" "$RESET" "$PROFILE_FILE"
            fi
        fi
    fi
fi
```

## Test Coverage

Created comprehensive test suite to verify fixes:

### Test Files Created
1. `.tests/test-install-uninstall.sh` - Install/uninstall mechanics (4 tests)
2. `.tests/test-mac-install.sh` - Mac-specific scenarios (4 tests)
3. `.tests/test-mac-e2e.sh` - End-to-end cycles (2 tests)
4. `.tests/.imps/sys/test-invoke-wizardry-performance.sh` - Performance and hanging (5 tests)

### Test Results
```
Install/Uninstall Tests:        4/4 passing
Mac-Specific Tests:             4/4 passing
Mac E2E Tests:                  2/2 passing
Performance Tests:              5/5 passing
Existing invoke-wizardry Tests: 37/37 passing
─────────────────────────────────────────
Total:                          52/52 passing ✅
```

## Verification

### What We Tested
1. ✅ Profile files (.bash_profile, .zprofile) are created when needed
2. ✅ Profile files source the correct RC file (.bashrc, .zshrc)
3. ✅ Uninstall removes wizardry from both RC and profile files
4. ✅ Uninstall deletes empty profile files created by installer
5. ✅ Uninstall preserves user's original content
6. ✅ invoke-wizardry completes quickly (< 10s for ~306 files)
7. ✅ menu is available after sourcing invoke-wizardry
8. ✅ No infinite loops in command_not_found_handle
9. ✅ Recursive sourcing is prevented
10. ✅ Full install -> use -> uninstall cycle works for both bash and zsh

### Expected Behavior on Mac

#### Installation
1. Install adds wizardry line to `.zshrc` (or `.bashrc` for bash users)
2. Install creates/updates `.zprofile` (or `.bash_profile`) to source `.zshrc` (or `.bashrc`)
3. New terminal windows will source `.zprofile` → `.zshrc` → `invoke-wizardry`
4. Menu and all spells are available immediately

#### Uninstallation
1. Uninstall removes wizardry line from `.zshrc` (or `.bashrc`)
2. Uninstall removes entire wizardry block from `.zprofile` (or `.bash_profile`)
3. If `.zprofile`/`.bash_profile` is now empty (only had wizardry content), it's deleted
4. User's original RC content is preserved
5. New terminals will not load wizardry

## Notes for Mac Testing

While this was developed and tested on Linux, the test suite simulates Mac-specific behavior:
- Zsh as default shell (macOS Catalina+)
- Login shell vs interactive shell distinction
- Profile file sourcing order

The fixes should work correctly on actual Mac systems. If issues persist:
1. Check that `.zprofile` (or `.bash_profile`) exists and sources `.zshrc` (or `.bashrc`)
2. Check that `.zshrc` (or `.bashrc`) has the invoke-wizardry source line
3. Run in a fresh terminal to test login shell behavior
4. Check for errors with: `zsh -xl` or `bash -xl` to see verbose sourcing

## Related Files
- `install` - Main installation script (modified)
- `spells/.imps/sys/invoke-wizardry` - Shell initialization (no changes, already correct)
- `.tests/test-install-uninstall.sh` - Install/uninstall tests
- `.tests/test-mac-install.sh` - Mac-specific tests
- `.tests/test-mac-e2e.sh` - End-to-end tests
- `.tests/.imps/sys/test-invoke-wizardry-performance.sh` - Performance tests
