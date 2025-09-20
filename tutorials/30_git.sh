#!/bin/bash

# Spell cast: Git Magic
# This spell will teach you the basics of using git for common tasks.

# First, let's initialize a git repository in the current directory
git init

# Now, let's create a new file and add it to the repository
touch newfile.txt
git add newfile.txt

# We can check the status of our repository to see what changes have been made
git status

# To commit the changes, we use the commit command
git commit -m "Added newfile.txt"

# To clone a repository from a remote source, we use the clone command
git clone https://github.com/user/repo.git

# To add changes to the repository
echo "Hello, Git!" >> newfile.txt
git add newfile.txt
git commit -m "Modified newfile.txt"

# To remove a file from the repository
git rm newfile.txt
git commit -m "Removed newfile.txt"

# To reset changes to a file
git reset newfile.txt

# To reset files to the last version
git reset --hard

# Spell cast successfully!
