#!/bin/sh
# To make this script executable, use the command: chmod +x 21_parentheses.sh
# To run the script, use the command: ./11_parentheses.sh
echo "This spell will teach you the basics of differentiating between similar parenthetical syntax in POSIX sh"
echo "To study the code of the examples, please use the command: cat 21_parentheses.sh"

# Using $() command substitution
echo "Using command substitution with $()"
current_date=$(date)
echo "Today's date is: $current_date"

# Using $(()) arithmetic expansion
echo "Using arithmetic expansion with $(())"
num1=5
num2=3
result=$((num1 + num2))
echo "5 + 3 = $result"

# Using string list
echo "Using string list with \"\""
ingredients="Dragon's blood Unicorn hair Phoenix feather"
echo "Ingredients: $ingredients"

# Using array
echo "Using array with ()"
ingredients=("Dragon's blood" "Unicorn hair" "Phoenix feather")
echo "Ingredients: ${ingredients[@]}"

# Using [] test command
echo "Using test command with []"
string="Dragon's blood"
if [ "$string" = "Dragon's blood" ]; then
  echo "The string is Dragon's blood"
else
  echo "The string is not Dragon's blood"
fi

echo "Spell cast successfully."
