#!/bin/sh
# To make this script executable, use the command: chmod +x 23_shell_options_basic.sh
# To run the script, use the command: ./23_shell_options_basic.sh

echo "This spell will teach you about basic shell options in POSIX sh"
echo "Shell options control how your script behaves"

# The set command is used to set or unset shell options
echo ""
echo "=== The 'set' Command ==="
echo "The set command controls shell behavior with flags"

# -e: Exit on error (errexit)
echo ""
echo "=== Option -e: Exit on Error ==="
echo "When set -e is active, the script exits if any command fails"
cat <<'EXAMPLE'
#!/bin/sh
set -e
ls /nonexistent  # This will fail and exit the script
echo "This won't print"
EXAMPLE

echo ""
echo "This is essential for catching errors early!"

# -u: Error on undefined variables (nounset)
echo ""
echo "=== Option -u: Error on Undefined Variables ==="
echo "When set -u is active, using undefined variables causes an error"
cat <<'EXAMPLE'
#!/bin/sh
set -u
echo "$undefined_var"  # This will cause an error
EXAMPLE

echo ""
echo "This prevents silent bugs from unset variables"

# Best practice: Use both together
echo ""
echo "=== Best Practice: set -eu ==="
echo "Always use 'set -eu' at the start of your scripts"
cat <<'EXAMPLE'
#!/bin/sh
set -eu  # Exit on error, error on undefined vars

# Now your script is more robust
file="${1:-default.txt}"  # Use default if $1 is not set
echo "Processing file: $file"
EXAMPLE

# -x: Print commands as they execute (xtrace)
echo ""
echo "=== Option -x: Debug Mode ==="
echo "When set -x is active, commands are printed before execution"

set -x
echo "This command will be printed before it runs"
ls /tmp > /dev/null 2>&1
set +x

echo "Debug mode is very useful for troubleshooting!"

# -f: Disable filename globbing
echo ""
echo "=== Option -f: Disable Glob Expansion ==="
echo "When set -f is active, wildcards are not expanded"

set -f
pattern="*.txt"
echo "Pattern: $pattern"  # Prints *.txt literally
set +f

# Setting positional parameters
echo ""
echo "=== Using 'set' with Arguments ==="
echo "You can use 'set' to set positional parameters"

set -- "first" "second" "third"
echo "Parameter 1: $1"
echo "Parameter 2: $2"  
echo "Parameter 3: $3"

# Unsetting options
echo ""
echo "=== Unsetting Options ==="
echo "Use + instead of - to unset an option"
cat <<'EXAMPLE'
set -e   # Enable exit on error
set +e   # Disable exit on error
EXAMPLE

# Common combinations
echo ""
echo "=== Common Option Combinations ==="
echo "set -eu    # Recommended for all scripts"
echo "set -eux   # Debug mode + strict error handling"
echo "set -euf   # Strict mode + no glob expansion"

echo ""
echo "=== Summary of Basic Options ==="
echo "-e  Exit immediately if a command fails"
echo "-u  Treat unset variables as an error"
echo "-x  Print commands before executing (debug)"
echo "-f  Disable filename expansion (globbing)"
echo ""
echo "Use +flag to disable an option (e.g., set +x)"

echo ""
echo "Spell cast successfully!"
echo "Always start your scripts with: set -eu"
