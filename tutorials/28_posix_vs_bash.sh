#!/bin/sh
# To make this script executable, use the command: chmod +x 28_posix_vs_bash.sh
# To run the script, use the command: ./28_posix_vs_bash.sh

echo "This spell will teach you about POSIX sh vs Bash"
echo "Understanding the difference helps you write portable, universal scripts"

# What is POSIX sh?
# POSIX sh is the standard shell specified by POSIX (Portable Operating System Interface)
# It works on nearly all Unix-like systems: Linux, macOS, BSD, Solaris, etc.
# It's the "lowest common denominator" that you can rely on everywhere

echo ""
echo "=== What is POSIX sh? ==="
echo "POSIX sh is the portable shell standard that works everywhere"
echo "It's simpler and more universal than Bash"
echo "Your scripts with #!/bin/sh should use only POSIX features"

# What is Bash?
# Bash (Bourne Again Shell) is an enhanced shell with many extra features
# It's very common on Linux, but not always available or default on other systems
# Bash adds convenient features but reduces portability

echo ""
echo "=== What is Bash? ==="
echo "Bash is a popular shell with many enhancements beyond POSIX"
echo "It's common on Linux but not guaranteed on all Unix systems"
echo "Scripts with #!/bin/bash require Bash to be installed"

# When should you use POSIX sh?
echo ""
echo "=== When to use POSIX sh ==="
echo "1. You want maximum portability across Unix systems"
echo "2. You're writing system scripts that need to work everywhere"
echo "3. You're writing for containers or minimal environments"
echo "4. You want your scripts to be simple and maintainable"
echo "5. You're learning shell scripting (start with the basics!)"

# When might you need Bash?
echo ""
echo "=== When Bash might be needed ==="
echo "1. You need Bash-specific features like arrays"
echo "2. You're working in an environment where Bash is guaranteed"
echo "3. You need advanced pattern matching with [[ ]]"
echo "4. You want to use Bash's associative arrays (hash maps)"
echo "5. You need process substitution: <(command)"

# Common Bashisms to avoid in POSIX scripts
echo ""
echo "=== Common Bashisms (avoid in POSIX sh) ==="

# 1. Double bracket test [[ ]]
echo "Bashism: [[ \$var = value ]]"
echo "POSIX:   [ \"\$var\" = \"value\" ]"

# 2. Arrays
echo "Bashism: array=(one two three)"
echo "POSIX:   Use space-separated strings or positional parameters"

# 3. Local keyword
echo "Bashism: local var=value"
echo "POSIX:   Just use: var=value (use distinct names to avoid conflicts)"

# 4. Echo with -e or -n flags
echo "Bashism: echo -e \"line1\\nline2\""
echo "POSIX:   printf \"line1\\nline2\\n\""

# 5. Source keyword
echo "Bashism: source script.sh"
echo "POSIX:   . script.sh"

# 6. Function keyword
echo "Bashism: function myfunc { ... }"
echo "POSIX:   myfunc() { ... }"

# 7. Bash string operations
echo "Bashism: \${var^^}  # uppercase"
echo "POSIX:   Use tr or awk for string manipulation"

# How to check if your script is POSIX-compliant
echo ""
echo "=== How to verify POSIX compliance ==="
echo "1. Use #!/bin/sh (not #!/bin/bash)"
echo "2. Test on different systems if possible"
echo "3. Use 'checkbashisms' tool if available"
echo "4. Use 'shellcheck' with shell=sh option"
echo "5. Read POSIX shell specification online"

# Real-world example: POSIX portable script
echo ""
echo "=== Example: Portable POSIX script ===" 
cat <<'EXAMPLE'
#!/bin/sh
# This script works on any POSIX system

set -eu  # Exit on error, error on undefined variables

# Get the directory where this script lives
script_dir=$(cd "$(dirname "$0")" && pwd -P)

# Process arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      printf 'Usage: %s [options] file\n' "$0"
      exit 0
      ;;
    -*)
      printf 'Unknown option: %s\n' "$1" >&2
      exit 2
      ;;
    *)
      file="$1"
      break
      ;;
  esac
  shift
done

# Check if file exists
if [ ! -f "$file" ]; then
  printf 'Error: File not found: %s\n' "$file" >&2
  exit 1
fi

printf 'Processing file: %s\n' "$file"
EXAMPLE

echo ""
echo "=== Summary ==="
echo "For wizardry, we use POSIX sh for maximum portability"
echo "This means: #!/bin/sh, [ ] tests, printf instead of echo -e"
echo "Bash is powerful but POSIX sh is universal"
echo "Start with POSIX - you can always switch to Bash later if truly needed"

echo ""
echo "Spell cast successfully!"
echo "May your scripts run on every Unix system under the sun!"
