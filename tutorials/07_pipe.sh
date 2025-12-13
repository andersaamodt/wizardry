#!/bin/sh
# To make this script executable, use the command: chmod +x 06_pipe.sh
# To run the script, use the command: ./06_pipe.sh
echo "This spell will teach you the basics of I/O redirection and pipelines in POSIX sh"
echo "To study the code of the examples, please use the command: cat 06_pipe.sh"

# Redirecting standard output to a file
echo "The '>' operator redirects the output of the command to the left of it and writes it to the file on the right. If the file already exists, its contents will be overwritten."
echo "Dragon's blood" > ingredient.txt

# Appending standard output to a file
echo "The '>>' operator works similar to '>', but it appends the output to the file instead of overwriting its contents."
echo "Appending to current_date.txt" >> current_date.txt
echo "Unicorn hair" >> ingredient.txt

# Redirecting standard input from a file
echo "The '<' operator redirects the contents of the file on the right as the input for the command on the left."
echo "Content of current_date.txt:"
sort < ingredient.txt

# Using pipelines
echo "The '|' operator takes the output of the command on the left and uses it as the input for the command on the right."
echo "All files in the current directory:"
ls -l | grep "^-"

echo "Spell cast successfully."
