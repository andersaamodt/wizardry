#!/bin/sh
# To make this script executable, use the command: chmod +x 30_antipatterns.sh
# To run the script, use the command: ./30_antipatterns.sh

echo "This spell will teach you common shell scripting anti-patterns"
echo "Learn what NOT to do, and why these patterns cause trouble"

echo ""
echo "=== ANTI-PATTERN #1: Unquoted Variables ==="
echo "WRONG:"
cat <<'WRONG'
  file=$1
  cat $file  # Breaks with spaces, globs with wildcards
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  file="$1"
  cat "$file"  # Always quote variables!
RIGHT

echo ""
echo "=== ANTI-PATTERN #2: Using echo -e or echo -n ==="
echo "WRONG:"
cat <<'WRONG'
  echo -e "Line 1\nLine 2"  # Not POSIX portable
  echo -n "No newline"      # Not POSIX portable
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  printf "Line 1\nLine 2\n"  # POSIX standard
  printf "No newline"         # Works everywhere
RIGHT

echo ""
echo "=== ANTI-PATTERN #3: Using [[ ]] for Tests ==="
echo "WRONG:"
cat <<'WRONG'
  if [[ $var = "value" ]]; then  # Bash-only, not POSIX
    echo "match"
  fi
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  if [ "$var" = "value" ]; then  # POSIX standard
    echo "match"
  fi
RIGHT

echo ""
echo "=== ANTI-PATTERN #4: Using 'which' Command ==="
echo "WRONG:"
cat <<'WRONG'
  if which git > /dev/null; then  # which is not standard
    git status
  fi
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  if command -v git >/dev/null 2>&1; then  # POSIX standard
    git status
  fi
RIGHT

echo ""
echo "=== ANTI-PATTERN #5: Using 'local' Keyword ==="
echo "WRONG:"
cat <<'WRONG'
  my_function() {
    local var="value"  # local is not POSIX
    echo "$var"
  }
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  my_function() {
    myfunc_var="value"  # Use distinct names
    echo "$myfunc_var"
  }
RIGHT

echo ""
echo "=== ANTI-PATTERN #6: Using == for String Comparison ==="
echo "WRONG:"
cat <<'WRONG'
  if [ $var == "value" ]; then  # == is Bash-ism
    echo "equal"
  fi
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  if [ "$var" = "value" ]; then  # = is POSIX standard
    echo "equal"
  fi
RIGHT

echo ""
echo "=== ANTI-PATTERN #7: Using 'source' Instead of '.' ==="
echo "WRONG:"
cat <<'WRONG'
  source ./config.sh  # source is Bash keyword
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  . ./config.sh  # dot is POSIX standard
RIGHT

echo ""
echo "=== ANTI-PATTERN #8: Using 'function' Keyword ==="
echo "WRONG:"
cat <<'WRONG'
  function myfunc {  # Bash-style function definition
    echo "hello"
  }
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  myfunc() {  # POSIX style
    echo "hello"
  }
RIGHT

echo ""
echo "=== ANTI-PATTERN #9: Forgetting set -eu ==="
echo "WRONG:"
cat <<'WRONG'
  #!/bin/sh
  # No strict mode - errors silently ignored
  result=$undefinedvar
  false && echo "continues anyway"
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  #!/bin/sh
  set -eu  # Exit on error, error on undefined vars
  result="${defined_var}"
  false || echo "error caught"
RIGHT

echo ""
echo "=== ANTI-PATTERN #10: Using Backticks for Command Substitution ==="
echo "WRONG:"
cat <<'WRONG'
  result=`date`  # Old style, hard to nest
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  result=$(date)  # Modern style, easy to nest
RIGHT

echo ""
echo "=== ANTI-PATTERN #11: Not Checking Command Success ==="
echo "WRONG:"
cat <<'WRONG'
  cd /some/directory
  rm *  # If cd failed, deletes wrong directory!
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  cd /some/directory || exit 1
  rm *
  
  # Or with set -e:
  set -e
  cd /some/directory
  rm *
RIGHT

echo ""
echo "=== ANTI-PATTERN #12: Using realpath (Not Always Available) ==="
echo "WRONG:"
cat <<'WRONG'
  full_path=$(realpath file.txt)  # Not available everywhere
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  full_path="$(cd "$(dirname "file.txt")" && pwd -P)/$(basename "file.txt")"
RIGHT

echo ""
echo "=== ANTI-PATTERN #13: Imperative Error Messages ==="
echo "WRONG:"
cat <<'WRONG'
  echo "Please install git" >&2
  echo "You must run this as root" >&2
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  echo "script-name: git not found" >&2
  echo "script-name: requires root privileges" >&2
  # Even better: Try to fix it automatically!
RIGHT

echo ""
echo "=== ANTI-PATTERN #14: Not Quoting in Tests ==="
echo "WRONG:"
cat <<'WRONG'
  if [ -z $var ]; then  # Breaks when var is unset
    echo "empty"
  fi
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  if [ -z "$var" ]; then  # Always quote in tests
    echo "empty"
  fi
RIGHT

echo ""
echo "=== ANTI-PATTERN #15: Using #!/bin/bash When #!/bin/sh Works ==="
echo "WRONG:"
cat <<'WRONG'
  #!/bin/bash
  # Script uses only POSIX features
  # But requires Bash to be installed
WRONG
echo ""
echo "RIGHT:"
cat <<'RIGHT'
  #!/bin/sh
  # Works on any POSIX system
  # Maximum portability
RIGHT

echo ""
echo "=== Summary: Remember These Rules ==="
echo "1. Always quote variables: \"\$var\" not \$var"
echo "2. Use [ ] not [[ ]] for tests"
echo "3. Use printf not echo -e"
echo "4. Use command -v not which"
echo "5. Use = not == for string comparison"
echo "6. Use . not source"
echo "7. Use set -eu for strict mode"
echo "8. Use \$(command) not \`command\`"
echo "9. Use #!/bin/sh when POSIX features suffice"
echo "10. Check command success before proceeding"

echo ""
echo "Spell cast successfully!"
echo "May you never fall into these common traps again!"
