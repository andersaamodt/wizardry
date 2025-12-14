#!/bin/sh
# To make this script executable, use the command: chmod +x 11_debugging.sh
# To run the script, use the command: ./11_debugging.sh
echo "This spell will teach you the basics of script debugging and error handling in POSIX sh"
echo "To study the code of the examples, please use the command: cat 11_debugging.sh"

# echo and set -x (debugging)
echo "The echo command is used to print messages to the terminal. The set -x command enables the display of commands and their arguments as they are executed."
echo "Example: set -x; echo 'Debugging message'; set +x"
set -x; echo 'Debugging message'; set +x

# trap and signal handling (error handling)
echo "The trap command is used to catch signals sent to the script. Signals are used to communicate with processes, and are typically sent when a program needs to terminate or interrupt another program."
echo "Example: trap 'echo Signal received, exiting...; exit 0' INT; sleep 10; echo 'This line will not be executed'"
trap 'echo Signal received, exiting...; exit 0' INT; sleep 10; echo 'This line will not be executed'

# exit status and return values (error handling)
echo "Every command in POSIX sh returns an exit status, which is the value that the command returns to the parent process. The value can be checked using the $? variable. A value of 0 indicates success, and any other value indicates failure."
echo "Example: echo $? (this should be 0)"
echo $?

# Using the exit status in a conditional statement
command
if [ $? -eq 0 ]; then
  echo "Command executed successfully"
else
  echo "Command failed with exit status $?"
fi

# Setting the exit status of the script
echo "You can also set the exit value of a script manually with the 'exit' command. 0 means success, every other value is an error. This script will exit with an error code of 42."
exit 42

echo "Spell cast successfully"
