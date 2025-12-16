#!/bin/sh
# To make this script executable, use the command: chmod +x 07_functions.sh
# To run the script, use the command: ./07_functions.sh
echo "This spell will teach you the basics of functions in POSIX sh"
echo "To study the code of the examples, please use the command: cat 07_functions.sh"

# Defining a function
create_potion() {
  echo "Creating potion with $1 and $2"
}

# Calling a function
create_potion "Dragon's blood" "Unicorn hair"

# Defining a function with return value
calculate_price() {
  echo $((10 + 20))
}

# Calling a function with return value
price=$(calculate_price)
echo "Price of the potion is $price golds"

echo "Functions can also be loaded in your shell configuration file to make them available in all terminals."
echo "For example, you can add the following line in your shell rc file to load the 'hello' function: 'hello() { echo \"Hello, \$1\" }'"

echo "Creating a function that changes the working directory"
go_to_spell_folder() {
    cd ~/spells
    pwd
}

# Return statement
echo "The 'return' statement cause the function to return immediately. The return value can be captured in a variable."
my_function() {
    echo "Inside the function"
    return 5
    echo "This line will not be executed"
}

echo "Before calling the function"
result=$(my_function)
echo "The function returned $result"
echo "After calling the function"

echo "Spell cast successfully"

