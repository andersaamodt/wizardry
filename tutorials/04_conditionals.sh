#!/bin/sh
# To make this script executable, use the command: chmod +x 03_conditionals.sh
# To run the script, use the command: ./03_conditionals.sh

echo "This spell will teach you the basics of conditional statements in POSIX-compliant Bash."
echo "To study the code of the examples, please use the command: cat 03_conditionals.sh"

# Using if statement
echo "Checking if the ingredient is Dragon's blood"
ingredient="Dragon's blood"
if [ "$ingredient" = "Dragon's blood" ]; then
  echo "The ingredient is Dragon's blood, adding it to the potion"
else
  echo "The ingredient is not Dragon's blood, adding something else to the potion"
fi

# Using if-else statement
echo "Checking if the ingredient is Dragon's blood or Unicorn hair"
ingredient="Unicorn hair"
if [ "$ingredient" = "Dragon's blood" ]; then
  echo "The ingredient is Dragon's blood, adding it to the potion"
elif [ "$ingredient" = "Unicorn hair" ]; then
  echo "The ingredient is Unicorn hair, adding it to the potion"
else
  echo "The ingredient is not Dragon's blood nor Unicorn hair, adding something else to the potion"
fi

# Using test command
echo "Checking if the number of ingredients is greater than 5"
ingredients_count=6
if test $ingredients_count -gt 5; then
  echo "The number of ingredients is greater than 5"
else
  echo "The number of ingredients is not greater than 5"
fi

echo "Spell cast successfully."
