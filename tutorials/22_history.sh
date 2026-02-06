#!/bin/sh
# This spell will teach you about command history in interactive shells

echo "Command history is a shell feature, not POSIX sh."
echo "History works in interactive shells (bash, zsh) but not in POSIX sh scripts."
echo ""
echo "Interactive shell features (bash/zsh only):"
echo "  - history          # View command history"
echo "  - history 10       # View last 10 commands"
echo "  - history | grep X # Search history"
echo "  - !3               # Re-run command #3 from history"
echo "  - !!               # Re-run last command"
echo "  - history -c       # Clear history (bash)"
echo ""
echo "POSIX sh alternative:"
echo "  - Use up/down arrows in interactive shell to navigate history"
echo "  - Set HISTFILE and HISTSIZE environment variables"
echo "  - History is stored in ~/.sh_history or ~/.history"
echo ""
echo "To use these features, try them in an interactive bash or zsh shell,"
echo "not in this script!"

echo "History spell cast successfully!"
