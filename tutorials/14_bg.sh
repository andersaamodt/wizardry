#!/bin/sh
# This script is a spell that will teach you about the bg and fg commands in POSIX sh
# To study the code of the examples, please use the command: cat 14_bg.sh

echo "This spell will teach you about the bg and fg commands in POSIX sh"
echo "To study the code of the examples, please use the command: cat 14_bg.sh"

# Running a command in the background
sleep 10 &
job_pid=$!
echo "Background task started (PID: $job_pid). You can continue with other spells while waiting."

# Listing background tasks
jobs

# Wait for background task to complete
echo "Waiting for background task to finish..."
wait $job_pid
echo "Background task completed."

# Note: fg and bg are interactive commands that work in shells but not reliably in scripts
# To test them interactively:
#   1. Run: sleep 30 &
#   2. Run: jobs (see the job number)
#   3. Run: fg %1 (brings to foreground)
#   4. Press Ctrl+Z to suspend
#   5. Run: bg %1 (continues in background)

echo "See the comments above to learn about fg and bg commands."
