#!/bin/sh
# To make this script executable, use the command: chmod +x 08_regex.sh
# To run the script, use the command: ./08_regex.sh
echo "This spell will teach you the basics of regular expressions and pattern matching in POSIX-compliant Bash"
echo "To study the code of the examples, please use the command: cat 08_regex.sh"

# Basic regular expressions (special characters)
echo "Regular expressions are a way to search for patterns in text. Common special characters include:"
echo "^ - beginning of a line"
echo "$ - end of a line"
echo "* - any number of characters"
echo "? - any single character"
echo "[] - any character in the brackets"
echo "() - group characters together"
echo "| - or"
echo "\\ - escape special characters"

# grep (search in text)
echo "The grep command searches for a pattern in a file or input."
echo "grep '^root:' /etc/passwd - searches for the pattern '^root:' in the file /etc/passwd"
echo "Example: grep 'bash' /etc/passwd - searches for the pattern 'bash' in the file /etc/passwd"
grep 'bash' /etc/passwd

# sed (replace in text)
echo "The sed command is a stream editor that can perform basic text transformations on an input stream (a file or input from a pipeline)."
echo "sed 's/root/admin/' /etc/passwd - replaces the first occurence of 'root' with 'admin' in the file /etc/passwd"
echo "Example: sed 's/bash/zsh/' /etc/passwd - replaces the first occurence of 'bash' with 'zsh' in the file /etc/passwd"
echo "backup" | sed 's/backup/backup_file/'

# awk (advanced text processing)
echo "The awk command is a text processing tool that can perform more complex text transformations."
echo "awk -F: '{ print $1 }' /etc/passwd - prints the first field of each line of the file /etc/passwd, where the field separator is ':'"
awk '{ print $1 }' /etc/passwd
echo "root:x:0:0:root:/root:/bin/bash" | awk -F: '{print $1}'

# find and xargs (run command for all found files)
echo "The find command is used to search for files in a directory hierarchy. xargs is used to build and execute command lines from standard input."
echo "find / -name '*.txt' | xargs grep 'example' - searches for all .txt files in the root directory and its subdirectories, and runs 'grep 'example'' on each file found"
find /etc -name "*.conf" -exec grep "root" {} \;

echo "Spell cast successfully"
