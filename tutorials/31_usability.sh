#!/bin/bash

# Spell cast successfully!

# This spell will teach you about best practices for making UNIX scripts and command line utilities usable

# One important aspect of script usability is providing clear and concise usage instructions. 
# You can do this by adding a usage function or a help flag, such as `-h` or `--help`.

usage() {
    echo "Usage: $0 [-h] [-v] [-f file] arg1 arg2"
}

while getopts "hvf:" opt; do
    case ${opt} in
        h )
            usage
            exit 0
            ;;
        v )
            echo "Verbose mode on"
            ;;
        f )
            file="$OPTARG"
            ;;
        \? )
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# Another aspect of usability is providing clear and informative error messages. 
# This can help users quickly understand what went wrong and how to fix it.

if [[ -z $1 ]]; then
    echo "Error: missing required argument arg1"
    usage
    exit 1
fi

if [[ ! -f $file ]]; then
    echo "Error: $file is not a valid file"
    exit 1
fi

# You can also improve usability by providing a consistent interface and adhering to conventions. 
# For example, using long options with a double dash, like `--help` is more user-friendly than using short options with a single dash like `-h`.

echo "arg1: $1"
echo "arg2: $2"
echo "file: $file"

# Additionally, providing tab-completion options for your script can greatly enhance usability.

# Lastly, testing your script with different inputs and edge cases can help ensure it is robust and usable for a wide range of users.

# Spell cast successfully!

#!/bin/bash
# The Very Usable, the most usable script
# By studying this spell, your scripts shall be top-notch and fleet
# With usage and help options, your users shall never be lost
# And clear error messages, at any cost

# First, let's add usage and help flags
while getopts ":h" opt; do
  case $opt in
    h)
      echo "Usage: $(basename $0) [-h] [arguments]"
      echo "This is a highly usable script that demonstrates best practices for making unix scripts and command line utilities usable."
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Now let's add some actions for the script
if [ $# -eq 0 ]; then
  echo "No arguments provided. Use -h flag for help." >&2
  exit 1
else
  echo "Performing actions with provided arguments: $@"
fi

# Let's make sure our script exits with appropriate status codes
exit_status=0

# And let's add some error handling
error_message="Error: unknown error"
trap 'echo $error_message; exit $exit_status' ERR

# Now, let's add some actions that may fail
false # this command always exits with status 1

# Let's update our error message and exit status before exiting
error_message="Error: false command failed"
exit_status=1

# The Very Usable spell has been cast successfully