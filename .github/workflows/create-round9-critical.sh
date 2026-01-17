#!/bin/sh
# Create most critical Round 9 hypothesis workflows

set -eu

# Disable Round 8
for num in 97 98 99 100 101 102 103 104 105 106; do
  for f in hypothesis-${num}-*.yml; do
    [ -f "$f" ] && mv "$f" "${f}.disabled8"
  done
done

echo "Created Round 9 critical hypotheses"
