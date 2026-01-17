#!/bin/sh
# Generate Round 8 hypothesis workflows (40 diverse tests)

# Disable Round 7 workflows
for i in 77 78 88 91 93; do
  if [ -f ".github/workflows/hypothesis-$i-"*.yml ]; then
    for f in .github/workflows/hypothesis-$i-*.yml; do
      mv "$f" "${f}.disabled7"
    done
  fi
done

printf "Round 8 workflow generation script ready\n"
printf "Will create 40 hypotheses targeting:\n"
printf "- Bash vs dash shell differences\n"
printf "- Gloss generation bugs\n"
printf "- Function definition syntax\n"
printf "- Memory/parsing issues\n"
