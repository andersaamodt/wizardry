#!/bin/sh

# Spell cast: Secure Shell (ssh) and Secure Copy (scp)

echo "Welcome, apprentice. Today we will be learning about the Secure Shell (ssh) and Secure Copy (scp) commands."
echo "These spells are crucial for securely accessing remote servers and copying files between them."
echo "Let's begin by setting up an ssh key. This will allow us to securely log in to a remote server without using a password."

# Generate an ssh key
ssh-keygen -t rsa

echo "Your ssh key has been generated. Now we need to add it to the remote server's authorized_keys file"

# Add ssh key to remote server
ssh-copy-id user@remote_server

echo "Your ssh key has been added to the remote server. You can now log in to the remote server using ssh."

# Log in to remote server
ssh user@remote_server

echo "Now that we are logged in to the remote server, let's try copying a file using the secure copy (scp) command."

# Copy file from local to remote server
scp file.txt user@remote_server:/path/to/file.txt

echo "The file has been successfully copied to the remote server. You can also copy files from the remote server to your local machine using scp."

# Copy file from remote to local server
scp user@remote_server:/path/to/file.txt file.txt

echo "You can also copy entire directories using the -r flag."

# Copy directory from local to remote server
scp -r local_directory user@remote_server:/path/to/remote_directory

echo "You can also copy files and directories between remote servers"

# Copy file from remote server 1 to remote server 2
scp user1@remote_server1:/path/to/file.txt user2@remote_server2:/path/to/file.txt

echo "And that's it for our lesson on ssh and scp. Remember, these spells are powerful tools for securely accessing and transferring files between servers. Use them wisely."

echo "Spell cast successfully!"
