#!/bin/sh
# To make this script executable, use the command: chmod +x 10_aliases_functions.sh
# To run the script, use the command: ./10_aliases_functions.sh
echo "This spell will teach you the basics of Aliases and Functions in POSIX-compliant Bash"
echo "To study the code of the examples, please use the command: cat 10_aliases_functions.sh"

# Aliases
echo "Creating an alias for a command"
alias ll='ls -al'
ll

echo "Aliases are used to create short, easy-to-remember commands for frequently used commands or sequences of commands."
echo "For example, we just created an alias 'll' for 'ls -al' command"

echo "Creating an alias of an alias"
alias la='ll -a'
la

echo "Spell cast successfully"
