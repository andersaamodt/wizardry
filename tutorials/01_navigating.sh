#!/bin/sh

# To make this script executable, use the command: chmod +x 01_navigating.sh
# To run the script, use the command: ./01_navigating.sh

echo "This spell that will teach you the basics of navigating the filesystem using Bash."
echo "To study the bash code of this tutorial, please use the command: cat 01_navigating.sh"

echo "Casting 'pwd' command..."
echo "The 'pwd' command stands for 'print working directory' and it prints the current working directory."
pwd

echo "Casting 'ls' command..."
echo "The 'ls' command stands for 'list' and it lists the files and directories in the current working directory."
ls

echo "Casting 'cd' command with '/' argument..."
echo "The 'cd' command stands for 'change directory' and it changes the current working directory."
echo "This will take us to the root directory."
cd /
pwd

echo "Casting 'cd' command with '~' argument..."
echo "This will take us to the home directory."
cd ~
pwd

echo "Casting 'mkdir' command..."
echo "The 'mkdir' command stands for 'make directory' and it creates a new directory."
echo "We are using the '-p' option which creates any necessary parent directories."
mkdir -p ~/wizardry/charms
ls ~/wizardry

echo "Casting 'rmdir' command..."
echo "The 'rmdir' command stands for 'remove directory' and it removes an empty directory."
rmdir ~/wizardry/charms
ls ~/wizardry
rmdir ~/wizardry

echo "Spell cast successfully."
