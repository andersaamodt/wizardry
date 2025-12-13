#!/bin/sh

# This spell will teach you how to work with environment variables in POSIX sh
# This spell will teach you about environment variables, which are variables that are accessible to all processes running in the operating system. They store information such as system paths, user preferences, and other settings.
# Limitations on naming conventions vary by operating system, but in general, they can only contain alphanumeric characters and underscores, and have a maximum length of around 1024 characters. They cannot be aliased, but they can be exported and referenced in the .bashrc file.

echo "To cast the spell, please use the command: ./25_env.sh"

# Setting an environment variable
export MY_ENV_VAR="This is my environment variable"
echo "Environment variable MY_ENV_VAR is set to $MY_ENV_VAR"

# Checking if an environment variable is set
if [ -z "$MY_ENV_VAR" ]; then
  echo "MY_ENV_VAR is not set"
else
  echo "MY_ENV_VAR is set to $MY_ENV_VAR"
fi

# Exporting a variable in .bashrc
echo "export MY_ENV_VAR_IN_BASHRC=This variable is set in .bashrc" >> ~/.bashrc

# Loading .bashrc
source ~/.bashrc
echo "MY_ENV_VAR_IN_BASHRC is set to $MY_ENV_VAR_IN_BASHRC"

echo "Spell cast successfully"

#!/bin/sh
# This spell will teach you about environment variables and exporting in POSIX sh
# Environment variables are variables that contain information about the environment in which a process runs. They can be used to set various options and make certain information available to processes.
# The limitations on names of environment variables are that they can only contain letters, numbers, and underscores, and the maximum length is determined by the system's limit on the length of environment variable strings. Environment variables cannot be aliased.

# Setting an environment variable
export MY_ENV_VAR="This is my environment variable"
echo "MY_ENV_VAR is set to: $MY_ENV_VAR"

# Accessing an environment variable
echo "The value of MY_ENV_VAR is: $MY_ENV_VAR"

# Exporting an environment variable in .bashrc
echo "export MY_ENV_VAR=\"This is my environment variable\"" >> ~/.bashrc

# Accessing an exported environment variable in a new terminal session
echo "The value of MY_ENV_VAR is: $MY_ENV_VAR"

echo "Spell cast successfully"

#!/bin/sh
# This spell will teach you the basics of environment variables in POSIX sh
# To study the code of the examples, please use the command: cat 25_env.sh

echo "Welcome to the land of magic, where we will be learning about environment variables"

# Setting an environment variable
export MY_VAR="Dragon's breath"
echo "The variable MY_VAR has been set to $MY_VAR"

# Listing all environment variables
echo "All the current environment variables are:"
printenv

# Unsetting an environment variable
unset MY_VAR
echo "The variable MY_VAR has been unset"

# Checking if a variable is set
if [ -z "$MY_VAR" ]; then
  echo "MY_VAR is unset"
else
  echo "MY_VAR is set"
fi

# Using an environment variable in a command
export FILE_LOCATION="/usr/local/spells"
ls "$FILE_LOCATION"

echo "Spell cast successfully"

#!/bin/sh
# This spell will teach you the basics of working with environment variables in POSIX sh

# Listing all environment variables
echo "The current environment variables are:"
printenv

# Setting an environment variable
export MY_VAR="Dragon's breath potion"

# Checking if a variable is set
if [ -z "$MY_VAR" ]; then
  echo "MY_VAR is not set"
else
  echo "MY_VAR is set to $MY_VAR"
fi

# Using an environment variable in a command
echo "The ingredients of the $MY_VAR are:"
cat potion_recipe.txt

# Unsetting an environment variable
unset MY_VAR

# Special predefined environment variables
echo "The current working directory is $PWD"
echo "The current user is $USER"
echo "The current shell is $SHELL"

echo "Spell cast successfully"