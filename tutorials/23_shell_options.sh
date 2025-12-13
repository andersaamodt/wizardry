# Set command
echo "The set command is used to set or unset various shell options, as well as positional parameters."

# Setting a shell option
echo "Here we are setting the -x option, which enables the display of commands and their arguments as they are executed."
set -x
echo "This line will be displayed in the terminal, as the -x option is set."

# Unsetting a shell option
echo "Now we will unset the -x option, so command execution will no longer be displayed in the terminal."
set +x
echo "This line will not be displayed in the terminal, as the -x option is unset."

# Setting positional parameters
echo "We can also use set to set the positional parameters."
set -- "one" "two" "three"
echo "Positional parameter 1: $1"
echo "Positional parameter 2: $2"
echo "Positional parameter 3: $3"

echo "The set command allows for greater control over shell options and positional parameters."
echo "This spell will teach you about the 'set' command and different shell options in POSIX sh"
echo "To study the code of the examples, please use the command: cat 07_variables.sh"

# Setting shell options
echo "Setting the 'errexit' option, which exits the script if any command returns a non-zero exit status"
set -e

# Using set -e to exit the script if a command fails
echo "Creating a file with touch command, which will not return a non-zero exit status"
touch example.txt

echo "Creating a file with a non-existent command, which will return a non-zero exit status and cause the script to exit"
nonexistentCommand

echo "This line will not be executed because the script exits on the previous command"

# Unsetting shell options
echo "Unsetting the 'errexit' option"
set +e

# Using set +e to continue the script even if a command fails
echo "Creating a file with a non-existent command, which will return a non-zero exit status but the script will continue"
nonexistentCommand

echo "This line will be executed because the script does not exit on the previous command"

echo "The spell has been cast successfully"
#!/bin/sh
# This script is a spell that will teach you about various shell options in POSIX sh
# To study the code of the examples, please use the command: cat 12_shell_options.sh

# Setting the -u option
echo "Setting the -u option: unset variables will cause an error"
set -u

# Demonstrating the effect of the -u option
echo "Value of unset variable: $unset_variable"

# Setting the -e option
echo "Setting the -e option: commands that return non-zero exit status will cause an error"
set -e

# Demonstrating the effect of the -e option
echo "This command will fail: false"

# Setting the -f option
echo "Setting the -f option: file name generation using wildcard characters will be disabled"
set -f

# Demonstrating the effect of the -f option
echo "List of files: *"

echo "Casting the spell is finished, check the code of the spell by using 'cat 12_shell_options.sh' command"

# This script is a spell that will teach you about the n, v, and o options in POSIX sh.

# To study the code of the examples, please use the command: cat 12_shell_options_2.sh

echo "This spell will teach you about the n, v, and o options in POSIX sh"

echo "Using the -n option to prevent execution of the commands"
set -n
echo "This line won't be executed"
set +n

echo "Using the -v option to print commands before execution"
set -v
echo "This line will be printed before execution"
set +v

echo "Using the -o option to set an option"
set -o nounset
echo "This line will trigger an error if the variable is not set"
set +o nounset

echo "Casting the spell is finished, check the code of the spell by using 'cat 12_shell_options_2.sh' command"


# This script is a spell that will teach you about some additional shell options in POSIX sh.
# To study the code of the examples, please use the command: cat script_name.sh

# -u option: Treat unset variables as an error and exit
# This will cause the script to exit if an unset variable is used
set -u
echo "Using unset variable: $unset_variable" # This will cause the script to exit with an error

# -C option: Prevent file overwriting with >
# This will cause the script to exit if the file already exists
set -C
echo "Hello World" > existing_file.txt # This will cause the script to exit with an error

# -B option: Enable brace expansion
echo {a,b,c} # This will print "a b c"
echo {1..3} # This will print "1 2 3"

# -e option: Exit immediately if a command exits with a non-zero status
set -e
ls does_not_exist.txt # This will cause the script to exit with an error

echo "Casting the spell is finished, check the code of the spell by using 'cat script_name.sh' command"

# This script is a spell that will teach you about some advanced shell options in POSIX sh

# -m: monitor mode
# This option will automatically exit the shell when all jobs have completed
set -m
sleep 10 &
wait
echo "All jobs have completed and the shell has exited"

# -r: restricted mode
# This option will restrict the shell's abilities, making it more secure by disabling certain dangerous commands
set -r
echo "This line will be executed"
cp /etc/passwd /tmp/passwd # this command will be disabled and the script will exit with an error
echo "This line won't be executed"

# -s: silent mode
# This option will make the shell more silent by not printing commands before they are executed
set -s
echo "This line will be executed"
echo "This line won't be printed"

# -h: hash all commands
# This option will make the shell remember the location of commands as they are executed
# so that next time the same command is executed, it will be faster
set -h
which ls # this command will be hashed
which ls # this command will be faster because the location of ls has been hashed

# -a: export all variables
# This option will export all variables to child processes
set -a
myvar="Hello World"
./script.sh # in script.sh, myvar will be available

# -b: notify of background completion
# This option will notify the user when a background job has completed
set -b
sleep 10 &
echo "Waiting for background job to complete"
wait
echo "Background job has completed"

# -f: disable file name generation (globbing)
# This option will disable file name generation, so that wildcards like * won't be expanded
set -f
echo * # this will print * instead of all files in the current directory

# -i: interactive mode
# This option will make the shell more interactive, by keeping the terminal open after a script has executed
set -i
echo "The terminal will remain open after this script has executed"

# -P: physical directory, don't follow symlinks
# This option will make the cd command not follow symlinks
set -P
ln -s /usr/local /tmp/locallink
cd /tmp/locallink
pwd # this will print /tmp/locallink


# Setting the -T option
set -T

# Attempting to execute a binary that's not in the PATH
./nonexistent_binary

# Outputting the exit status of the last command
echo "Exit status of last command: $?"

echo "Casting the spell is finished,"
