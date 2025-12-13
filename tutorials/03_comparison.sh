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

echo "This spell will teach you the basics of boolean values and string comparison in POSIX-compliant Bash."
echo "To study the code of the examples, please use the command: cat 23_boolean_values.sh"

# Basic boolean values
echo $((1 == 1)) # 0
echo $((1 != 1)) # 1
echo $((1 > 2)) # 1
echo $((1 < 2)) # 0

# Basic string comparison
string1="Hello"
string2="World"

echo $((string1 == string2)) # 0
echo $((string1 != string2)) # 1
echo $((string1 > string2)) # 1
echo $((string1 < string2)) # 0

echo "Spell cast successfully"