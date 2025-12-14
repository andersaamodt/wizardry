#!/bin/sh
# To make this script executable, use the command: chmod +x 19_shell_options_advanced.sh
# To run the script, use the command: ./19_shell_options_advanced.sh

echo "This spell will teach you about advanced shell options in POSIX sh"
echo "These are less commonly used but can be useful in specific situations"

# -v: Verbose mode
echo ""
echo "=== Option -v: Verbose Mode ==="
echo "Prints shell input lines as they are read"
cat <<'EXAMPLE'
set -v
echo "Command being read"
set +v
EXAMPLE

# -n: No execute mode (syntax check)
echo ""
echo "=== Option -n: No Execute Mode ==="
echo "Read commands but don't execute them (syntax check only)"
cat <<'EXAMPLE'
set -n
echo "This won't actually run"
# Useful for checking script syntax without running it
EXAMPLE
echo "Note: With -n set, the script won't execute further!"

# -C: Noclobber (prevent file overwriting)
echo ""
echo "=== Option -C: Noclobber ==="
echo "Prevents overwriting existing files with > redirection"
cat <<'EXAMPLE'
set -C
echo "data" > file.txt       # Creates file
echo "more" > file.txt       # ERROR: file exists
echo "more" >| file.txt      # OK: >| forces overwrite
set +C
EXAMPLE

# -a: Export all variables
echo ""
echo "=== Option -a: Export All Variables ==="
echo "Automatically export all variables to child processes"
cat <<'EXAMPLE'
set -a
myvar="value"  # Automatically exported
./child_script.sh  # Can access $myvar
set +a
EXAMPLE

# -b: Notify background job completion
echo ""
echo "=== Option -b: Background Job Notification ==="
echo "Report status of background jobs immediately"
cat <<'EXAMPLE'
set -b
sleep 5 &
# You'll be notified when the job completes
set +b
EXAMPLE

# -m: Monitor mode (job control)
echo ""
echo "=== Option -m: Monitor Mode ==="
echo "Enable job control (usually automatic in interactive shells)"
cat <<'EXAMPLE'
set -m
command &  # Job control is enabled
set +m
EXAMPLE

# -h: Hash commands
echo ""
echo "=== Option -h: Hash Commands ==="
echo "Remember the location of commands (slight performance boost)"
cat <<'EXAMPLE'
set -h
# First lookup of 'ls' searches PATH and remembers location
# Subsequent calls are faster
EXAMPLE

# Using set -o for named options
echo ""
echo "=== Using set -o for Named Options ==="
echo "You can use long names for options with -o"
cat <<'EXAMPLE'
set -o errexit    # Same as set -e
set -o nounset    # Same as set -u
set -o xtrace     # Same as set -x
set -o noclobber  # Same as set -C
set -o vi         # Vi editing mode (interactive)
set -o emacs      # Emacs editing mode (interactive)
EXAMPLE

# Checking current options
echo ""
echo "=== Checking Current Options ==="
echo "Use 'set -o' to see all current option settings"
echo "Current options:"
set -o | head -10

# Practical combinations
echo ""
echo "=== Practical Option Combinations ==="
echo ""
echo "For development:"
echo "  set -euxo pipefail  # Strict + debug (pipefail is Bash-only)"
echo "  set -eux  # POSIX version"
echo ""
echo "For production scripts:"
echo "  set -eu  # Strict error handling"
echo ""
echo "For syntax checking:"
echo "  sh -n script.sh  # Check syntax without running"
echo ""
echo "To prevent accidental file overwrites:"
echo "  set -C  # Use >| to force overwrite when needed"

# Non-standard options (Bash-specific, mentioned for awareness)
echo ""
echo "=== Note: Some Options Are Not POSIX ==="
echo "These require Bash and won't work in POSIX sh:"
echo "  set -o pipefail  # Bash-only: fail if any pipe command fails"
echo "  set -o errtrace  # Bash-only: inherit ERR trap"
echo "  set -o functrace # Bash-only: inherit DEBUG trap"
echo ""
echo "Stick to -e, -u, -x, -f for POSIX compatibility"

echo ""
echo "=== Summary of Advanced Options ==="
echo "-v  Verbose: print input lines as read"
echo "-n  No execute: syntax check only"
echo "-C  Noclobber: prevent > from overwriting files"
echo "-a  Export all variables automatically"
echo "-b  Notify when background jobs complete"
echo "-m  Monitor mode: enable job control"
echo "-h  Hash: remember command locations"
echo ""
echo "Use 'set -o optionname' for long-form option names"

echo ""
echo "Spell cast successfully!"
echo "For most scripts, 'set -eu' is all you need"
