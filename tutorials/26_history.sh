#!/bin/sh
# This spell will teach you the basics of using the history command in Bash

echo "The history command allows you to view and manipulate your command history."
echo "To view your command history, use the command: history"

# View the last 10 commands
history 10

# Search for a specific command in history
history | grep "spell"

# Run a specific command from history
!3

# Clear your command history
history -c

echo "History spell cast successfully!"
