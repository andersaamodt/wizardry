#!/bin/sh
# Spell cast: Script packaging and distribution

# Introduction:
# Packaging and distributing your scripts is an important step in making them usable by others.
# This spell will teach you the basics of creating an executable file and packaging it for distribution.

echo "Welcome to the Script Packaging and Distribution tutorial"
echo "To study the code of the examples, please use the command: cat 24_distribution.sh"

# Creating an executable file
# In order to run a script, it needs to have the correct permissions set.
# To make a script executable, you can use the chmod command.
# For example, the following command will give the owner and group execute permissions:

chmod u+x script_name.sh

# This will allow the script to be run by typing its name in the terminal.

# Packaging for distribution
# Once your script is executable, you can package it for distribution.
# One common way to do this is to create a .tar file which can be easily extracted on other machines.
# The following command will create a .tar file of your script:

tar -cvf script_name.tar script_name.sh

# You can then distribute the .tar file to others who can extract it and run the script.

# Another way to package your script is to create a .deb package using the dpkg command.
# This is useful if you want to distribute your script as a package that can be easily installed and uninstalled.
# To create a .deb package, you will need to create a control file and a post-installation script.
# Once you have those, you can use the following command to create the package:

dpkg-deb --build script_name

# You can then distribute the .deb package to others who can install it using the dpkg command.

# Creating a .rpm package
# A .rpm package is a format used for software distribution in Red Hat based systems. 
# This can be useful for distribution of your script to other users on the same system. 
# One way to create a .rpm package is to use the rpm command, 
# which will create a .rpm package of the script and install it on the system.
rpmbuild -bb --define "_topdir $PWD" --define "debug_package %{nil}" my_script.spec

# Creating a self-contained script
echo "Creating a self-contained script"
cat > self_contained.sh <<'EOF'
#!/bin/sh
# Your script code here
EOF
chmod +x self_contained.sh

# Creating a tarball
echo "Creating a tarball with the command tar -cvzf script_name.tar.gz script_name.sh"
tar -cvzf script_name.tar.gz script_name.sh

# Specifying interpreter in script for portability
echo "Specifying interpreter in script for portability"
echo '#!/usr/bin/env sh' | cat - my_script.sh > temp && mv temp my_script.sh

# Adding a shebang line
echo "Adding a shebang line to the script"
echo '#!/bin/sh' | cat - my_script.sh > temp && mv temp my_script.sh

# Conclusion:
# These are just a few basic techniques for packaging and distributing your scripts.
# With these skills, you will be able to share your scripts with others and make them easily usable.
echo "Spell cast successfully"