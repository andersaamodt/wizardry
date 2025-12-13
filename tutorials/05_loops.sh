#!/bin/sh
# To make this script executable, use the command: chmod +x 04_loops.sh
# To run the script, use the command: ./04_loops.sh
echo "To study the code of the examples, please use the command: cat 04_loops.sh"
echo "This spell will teach you the basics of loops in POSIX sh"

# Todo: give an example of using a for loop with both a number and an array (which is more like for-each)

# A for loop continues looping for as many iterations as the number of things in "in"
echo "Iterating through ingredients"
ingredients=("Dragon's blood" "Unicorn hair" "Phoenix feather")
for ingredient in "${ingredients[@]}"; do
  echo "  Adding $ingredient to the potion"
done

# A while loop continues as long as its test condition evaluates to true
echo "Iterating through numbers"
count=1
while test "$count" -le 5; do
  echo "  Adding number $count to the potion"
  count=$((count + 1))
done

# The 'break' keyword exits out of a loop
echo "Making a second potion, only adding ingredients up through Unicorn hair"
for ingredient in "${ingredients[@]}"; do
  echo "  Adding $ingredient to the potion"
  if [ "$ingredient" = "Unicorn hair" ]; then
  	echo "  Found Unicorn hair, this potion is finished."
    break
  fi
done

# The 'continue' keyword skips ahead to the next loop iteration
echo "Making a third potion, skipping adding the Unicorn hair this time"
for ingredient in "${ingredients[@]}"; do
  if [ "$ingredient" = "Unicorn hair" ]; then
  	echo "  Found Unicorn hair, skipping adding this ingredient."
    continue
  fi
  echo "  Adding $ingredient to the potion"
done

echo "Spell cast successfully"