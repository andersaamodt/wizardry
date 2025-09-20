#!/bin/sh
# To make this script executable, use the command: chmod +x 07_permissions.sh
# To run the script, use the command: ./07_permissions.sh
echo "This spell will teach you the basics of permissions in POSIX-compliant Bash"
echo "To study the code of the examples, please use the command: cat 07_permissions.sh"

# Execution flags
echo "The chmod command changes the permissions of a file. The permissions can be represented in two ways: octal or symbolic. "
echo "In octal representation, permissions are represented by a three-digit number, with each digit representing permissions for owner, group and others respectively. In this representation, 7 means read, write and execute permissions, 5 means read and execute permissions, and 0 means no permissions."
echo "In symbolic representation, permissions are represented by a combination of letters 'ugoa' (user, group, others, all) and '+-' (add or remove) and 'rwx' (read, write, execute) permissions. For example, 'ug+x' means add execute permission for user and group."

echo "chmod +x script.sh adds the execution flag to a script"
touch my_script.sh
chmod +x my_script.sh
ls -l my_script.sh
echo "The file my_script.sh now has the execution flag set"

echo "chmod 755 script.sh adds the execution flag and read and execute permissions for owner, group and others"
touch my_script2.sh
chmod 755 my_script2.sh
ls -l my_script2.sh
echo "The file my_script2.sh now has the execution flag and read and execute permissions for owner, group and others"

echo "chmod 700 script.sh adds the execution flag and read, write and execute permissions for owner only"
touch my_script3.sh
chmod 700 my_script3.sh
ls -l my_script3.sh
echo "The file my_script3.sh now has the execution flag and read, write and execute permissions for owner only"

echo "You can also use chown to change the ownership of a file."
echo "chown user:group script.sh changes the owner and group of the script.sh file"
echo "Spell cast successfully"