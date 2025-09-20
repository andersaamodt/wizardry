#!/bin/sh
# This spell will teach you the basics of Bash scripting best practices and optimization techniques

echo "The magic of scripting can be improved with the following best practices and optimization techniques:"

# 1. Use shebang
# Always use the shebang line (#!/bin/sh or #!/bin/bash) at the top of your script to specify the interpreter.

# 2. Use single quotes for strings
# Use single quotes for strings to prevent variable and command substitution.

string='Hello, World!'
echo $string # This will print 'Hello, World!'

# 3. Avoid using unnecessary subshells
# Avoid using subshells by using command substitution with $() instead of backticks `` or $(command).

result=$(command) # Better
result=`command` # Not recommended

# 4. Use double quotes for variables
# Use double quotes for variables to prevent word splitting and globbing.

name="John Doe"
echo "My name is $name" # This will print 'My name is John Doe'

# 5. Declare variables as local
# Declare variables as local when they are only used within a function.

my_function() {
  local my_variable="Hello, World!"
  echo $my_variable
}

my_function

# 6. Use the -e option for echo
# Use the -e option for echo to enable the interpretation of backslash escapes.

echo -e "This is a new line \nThis is a tab \t"

# 7. Use the -n option for echo
# Use the -n option for echo to suppress the trailing newline.

echo -n "Hello, "; echo "World!" # This will print 'Hello, World!' on the same line

# 8. Use the -x option for debugging
# Use the -x option to debug your script by displaying commands and their arguments as they are executed.

# 9. Use the -u option for undefined variables
# Use the -u option to catch references to uninitialized variables.

# 10. Use the -o option for options
# Use the -o option to enable or disable options within a script.

echo "Spell cast successfully"
