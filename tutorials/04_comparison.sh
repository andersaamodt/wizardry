#!/bin/sh
# To make this script executable, use the command: chmod +x 03_comparison.sh
# To run the script, use the command: ./03_comparison.sh

echo "This spell will teach you the basics of boolean values and basic string comparison in POSIX sh"
echo "To study the code of the examples, please use the command: cat 03_comparison.sh"
# Basic string comparison

string1="magic"
string2="wizardry"

echo "Are 'magic' and 'wizardry' the same? (Should be false)"
[ "$string1" = "$string2" ]
echo $?

echo "Are 'magic' and 'magic' the same? (Should be true)"
[ "$string1" = "$string1" ]
echo $?

echo "Is 'magic' not 'wizardry'? (Should be true)"
[ "$string1" != "$string2" ]
echo $?

echo "Is 'magic' greater than 'wizardry'? (Should be false)"
[ "$string1" > "$string2" ]
echo $?

echo "Is 'wizardry' greater than 'magic'? (Should be true)"
[ "$string2" > "$string1" ]
echo $?

echo "Spell cast successfully"

# To make this script executable, use the command: chmod +x 23_boolean_values.sh
# To run the script, use the command: ./23_boolean_values.sh

echo "This spell will teach you the basics of boolean values and string comparison in POSIX sh."
echo "To study the code of the examples, please use the command: cat 23_boolean_values.sh"

# Basic boolean values (using test command)
echo "Testing numeric equality with test:"
test 1 -eq 1 && echo "1 equals 1: true (exit 0)" || echo "1 equals 1: false (exit 1)"
test 1 -ne 1 && echo "1 not-equals 1: true" || echo "1 not-equals 1: false (exit 1)"
test 1 -gt 2 && echo "1 > 2: true" || echo "1 > 2: false (exit 1)"
test 1 -lt 2 && echo "1 < 2: true (exit 0)" || echo "1 < 2: false"

# Basic string comparison
string1="Hello"
string2="World"

echo "Testing string equality with test:"
test "$string1" = "$string2" && echo "Strings equal: true" || echo "Strings equal: false (exit 1)"
test "$string1" != "$string2" && echo "Strings not equal: true (exit 0)" || echo "Strings not equal: false"
# Note: String comparison with > and < is lexicographic and not POSIX-portable in test
# Use [ "$string1" \> "$string2" ] with backslash in some shells, but best avoided

echo "Spell cast successfully"