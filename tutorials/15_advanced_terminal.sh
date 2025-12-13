#!/bin/sh
# To make this script executable, use the command: chmod +x 15_advanced_terminal.sh
# To run the script, use the command: ./15_advanced_terminal.sh

echo "This spell will teach you about advanced terminal keyboard shortcuts"
echo "These shortcuts help you navigate and edit commands more efficiently"

echo ""
echo "=== Cursor Movement ==="
echo "Ctrl+A - Move cursor to beginning of line"
echo "Ctrl+E - Move cursor to end of line"
echo "Ctrl+B - Move cursor backward one character (same as Left arrow)"
echo "Ctrl+F - Move cursor forward one character (same as Right arrow)"
echo "Alt+B  - Move cursor backward one word"
echo "Alt+F  - Move cursor forward one word"

echo ""
echo "=== Deleting Text ==="
echo "Ctrl+D - Delete character under cursor"
echo "Ctrl+H - Delete character before cursor (same as Backspace)"
echo "Ctrl+W - Delete word before cursor"
echo "Alt+D  - Delete word after cursor"
echo "Ctrl+K - Delete from cursor to end of line"
echo "Ctrl+U - Delete from cursor to beginning of line"

echo ""
echo "=== Command History ==="
echo "Ctrl+R - Search command history (reverse search)"
echo "Ctrl+P - Previous command (same as Up arrow)"
echo "Ctrl+N - Next command (same as Down arrow)"
echo "Ctrl+G - Cancel history search"
echo "!!     - Repeat last command"
echo "!$     - Last argument of previous command"

echo ""
echo "=== Line Editing ==="
echo "Ctrl+L - Clear screen (same as 'clear' command)"
echo "Ctrl+T - Swap current character with previous"
echo "Alt+T  - Swap current word with previous"
echo "Alt+U  - Uppercase word from cursor to end"
echo "Alt+L  - Lowercase word from cursor to end"
echo "Ctrl+Y - Paste (yank) last deleted text"

echo ""
echo "=== Process Control ==="
echo "Ctrl+C - Interrupt (kill) current process"
echo "Ctrl+Z - Suspend current process (use 'fg' to resume)"
echo "Ctrl+D - Exit current shell (logout)"

echo ""
echo "=== Example: Try these commands ==="
echo "Type a long command and practice moving around with Ctrl+A and Ctrl+E"
echo "Try Ctrl+R and type part of a previous command to search history"
echo "Use Alt+Backspace or Ctrl+W to delete words quickly"

echo ""
echo "Spell cast successfully!"
echo "Master these shortcuts to become a terminal wizard!"