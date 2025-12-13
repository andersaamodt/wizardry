#!/bin/sh
# This script is a spell that will teach you about the bg and fg commands in POSIX sh
# To study the code of the examples, please use the command: cat 12_bg.sh

echo "This spell will teach you about the bg and fg commands in POSIX sh"
echo "To study the code of the examples, please use the command: cat 12_bg.sh"

# Running a command in the background
sleep 5 &
echo "Background task started. You can continue with other spells while waiting for it to finish."

# Listing background tasks
jobs

# Moving a background task to the foreground
fg %1
echo "Background task is now in the foreground."

# Sending a background task to the background
bg %1
echo "Foreground task is now in the background."
