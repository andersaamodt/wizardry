#!/bin/sh
# To make this script executable, use the command: chmod +x 21_backticks.sh
# To run the script, use the command: ./21_backticks.sh
echo "This spell will teach you the basics of capturing command output with backticks in POSIX sh"
echo "To study the code of the examples, please use the command: cat 21_backticks.sh"

# Capturing output with backticks
current_dir=`pwd`
echo "You are currently in the $current_dir directory"

# Assigning output of multiple commands to a variable
system_info=`uname -a; uptime`
echo "System information: $system_info"

# Using backticks in command substitution
echo "The current date and time is `date`"

echo "Spell cast successfully"
