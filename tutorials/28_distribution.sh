#!/bin/sh
# Spell cast: Script packaging and distribution

# Introduction:
# Packaging and distributing your scripts is an important step in making them usable by others.
# This spell will teach you the basics of creating an executable file and packaging it for distribution.

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

# Conclusion:
# These are just a few basic techniques for packaging and distributing your scripts.
# With these skills, you will be able to share your scripts with others and make them easily usable.
# Spell cast successfully!

#!/bin/bash
# This spell will teach you about Bash Script Packaging and Distribution

echo "Welcome to the Script Packaging and Distribution tutorial"
echo "To study the code of the examples, please use the command: cat 27_script_packaging.sh"

# Creating an executable file
# In order for your script to be executed, it needs to have the execute permission. 
# This can be done by using the chmod command, such as chmod +x script.sh. 
# This will give the owner of the file execute permission, allowing them to run the script.
chmod +x script.sh

# Creating a .deb package
# A .deb package is a format used for software distribution in Debian based systems. 
# This can be useful for distribution of your script to other users on the same system. 
# One way to create a .deb package is to use the checkinstall command, 
# which will create a .deb package of the script and install it on the system.
checkinstall -D --install=no --pkgname=my_script --pkgversion="1.0" --pkgrelease="1" --pakdir=../ --maintainer=myemail@example.com --exclude=/.git/ -y 

# Creating a .rpm package
# A .rpm package is a format used for software distribution in Red Hat based systems. 
# This can be useful for distribution of your script to other users on the same system. 
# One way to create a .rpm package is to use the rpm command, 
# which will create a .rpm package of the script and install it on the system.
rpmbuild -bb --define "_topdir $PWD" --define "debug_package %{nil}" my_script.spec

# Creating a standalone executable
# A standalone executable is a single file that contains all the necessary dependencies 
# for the script to run, making it easy to distribute to other users. 
# One way to create a standalone executable is to use the pyinstaller command for python scripts, 
# or the cxfreeze command for python scripts.
pyinstaller --onefile script.py
cxfreeze script.py --target-dir dist

echo "Script packaging and distribution spell cast successfully"

#!/bin/sh
# To make this script executable, use the command: chmod +x script_name.sh
# This spell will teach you how to package and distribute your Bash scripts

# Creating a self-contained script
echo "Creating a self-contained script"
cat > self_contained.sh <<'EOF'
#!/bin/bash
# Your script code here
EOF
chmod +x self_contained.sh

# Using a package manager
echo "Using a package manager"
apt-get install bash-completion

# Creating an executable file
echo "Creating an executable file with the command chmod +x script_name.sh"
chmod +x script_name.sh

# Creating a tarball
echo "Creating a tarball with the command tar -cvzf script_name.tar.gz script_name.sh"
tar -cvzf script_name.tar.gz script_name.sh

# Creating a deb package
echo "Creating a deb package with the command dpkg-deb --build script_name"
dpkg-deb --build script_name

echo "Spell cast successfully"

#!/bin/bash
# To cast this spell, use the command: ./27_script_packaging.sh
echo "This spell will teach you how to package and distribute your Bash scripts"
echo "To study the code of the examples, please use the command: cat 27_script_packaging.sh"

# Creating an executable file
echo "Creating an executable file for the script 'my_script.sh'"
chmod +x my_script.sh

# Compressing the script
echo "Compressing the script for distribution"
tar -czf my_script.tar.gz my_script.sh

# Specifying interpreter in script
echo "Specifying interpreter in script for portability"
echo '#!/usr/bin/env bash' | cat - my_script.sh > temp && mv temp my_script.sh

# Adding a shebang line
echo "Adding a shebang line to the script"
echo '#!/bin/bash' | cat - my_script.sh > temp && mv temp my_script.sh

echo "Spell cast successfully"