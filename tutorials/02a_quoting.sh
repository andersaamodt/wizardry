#!/bin/sh
# To make this script executable, use the command: chmod +x 02a_quoting.sh
# To run the script, use the command: ./02a_quoting.sh

echo "This spell will teach you the mystical art of quoting in POSIX sh"
echo "Quoting is essential for protecting your incantations from unintended effects"

# Single quotes preserve everything literally
# Use single quotes when you want the exact string, no substitutions
spell='echo $HOME'
echo "Literal spell preserved: $spell"

# Double quotes allow variable expansion and command substitution
# Use double quotes for variables to prevent word splitting and globbing
ingredient="Dragon's blood"
echo "The ingredient is: $ingredient"

# ALWAYS quote variables when using them
# This protects against word splitting and filename expansion

# Example: Word splitting without quotes (dangerous!)
items="potion scroll wand"
# Don't do: echo $items (would split into separate words)
# Do this instead:
echo "All items together: $items"

# Example: Protecting spaces in paths
spell_path="/path/to/my spells"
# Wrong: cd $spell_path (would try to cd to /path/to/my)
# Right: cd "$spell_path"

# Example: Protecting from glob patterns
pattern="*.txt"
# Without quotes, $pattern would expand to matching files
# With quotes, it stays as the literal string
echo "The pattern is: $pattern"

# Best practices for quoting:
echo "1. Always quote variables: \"\$var\" not \$var"
echo "2. Use single quotes for literal strings: 'literal text'"
echo "3. Use double quotes for strings with variables: \"text with \$var\""
echo "4. Quote command substitutions: \"\$(command)\""

# Special case: Arrays of arguments
# When you need to pass multiple arguments, use positional parameters
set -- "arg with spaces" "another arg" "third"
echo "First argument: $1"
echo "Second argument: $2"
echo "Third argument: $3"

# Acceptable practice: Unquoted variables in specific contexts
# Numeric comparisons are safe without quotes
count=5
if [ $count -gt 3 ]; then
  echo "Count is greater than 3"
fi

# Variable assignment is safe without quotes
new_value=$count
echo "New value: $new_value"

# However, when in doubt, ALWAYS quote!
# The safest practice is to quote all variable expansions

echo "Quoting spell cast successfully!"
echo "Remember: Quote thy variables, lest chaos ensue"
