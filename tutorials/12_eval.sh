#!/bin/sh
echo "This spell will teach you the basics of the eval and exec functions in POSIX-compliant Bash"
echo "To study the code of the examples, please use the command: cat 11_eval.sh"

# eval function
# The eval function takes a string as an argument and treats it as if it were a command.
# It allows the user to dynamically generate and execute commands.

# Example 1: Using variables in a command
ingredient="Dragon's blood"
eval "echo Gathering ingredients for the potion: $ingredient"

# Example 2: Using command substitution
eval "echo Today is $(date)"

# Example 3: Using multiple commands
eval "echo Starting spell; sleep 2; echo Spell complete"

# exec function
# The exec function also takes a command as its argument, but it replaces the current shell process with the new command. 
# This means that the new command will not run in a subshell and any changes made by the new command will affect the current shell.

# Example 1: Using exec to run a new shell
exec /bin/sh

# Example 2: Using exec to run a command
exec echo "This command is being run by exec"

echo "Spell cast successfully"
