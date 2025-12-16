#!/bin/sh
# To make this script executable, use the command: chmod +x 02_variables.sh
# To run the script, use the command: ./02_variables.sh
echo "This script is a spell that will teach you the basics of variables and parameter expansion in POSIX sh."
echo "To study the code of the examples, please use the command: cat 02_variables.sh"

# Declaring a variable
ingredient="Dragon's blood"
echo "Gathering ingredients for the potion, $ingredient found."

# Accessing the value of a variable
echo "The ingredient used is: $ingredient"

# Re-assigning a variable
ingredient="Unicorn hair"
echo "Gathering ingredients for the potion, $ingredient found."

# Special variable: $#
echo "Number of ingredients passed to the script: $#"

# Special variable: $@
echo "All ingredients passed to the script: $@"

# Special variable: $?
echo "Effect of the last ingredient added: $?"

# Parameter expansion
echo "The first ingredient passed to the script is: ${1}" #todo: split this into another script, maybe between 01 and 02?

echo "Spell cast successfully."
