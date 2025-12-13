#!/bin/sh
set -eu

# Test suite for tutorials
# This tests that tutorials follow POSIX standards and best practices

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

tutorials_dir="$ROOT_DIR/tutorials"

# Test: All shell tutorials have #!/bin/sh shebang
test_all_tutorials_have_posix_shebang() {
  for tutorial in "$tutorials_dir"/*.sh; do
    [ -f "$tutorial" ] || continue
    first_line=$(head -n 1 "$tutorial")
    case "$first_line" in
      "#!/bin/sh"|"#!/usr/bin/env sh")
        # Good - POSIX shebang
        ;;
      *)
        printf 'FAIL: %s has non-POSIX shebang: %s\n' "$(basename "$tutorial")" "$first_line" >&2
        return 1
        ;;
    esac
  done
  return 0
}

# Test: No tutorials use bashisms like [[, local, echo -e
test_no_bashisms_in_tutorials() {
  bashisms=""
  
  for tutorial in "$tutorials_dir"/*.sh; do
    [ -f "$tutorial" ] || continue
    name=$(basename "$tutorial")
    
    # Skip tutorials that explicitly demonstrate bash-isms
    case "$name" in
      28_posix_vs_bash.sh|29_antipatterns.sh)
        continue
        ;;
    esac
    
    # Check for [[ ]] (but not in comments showing what NOT to do)
    if grep -q '^[^#]*\[\[' "$tutorial"; then
      bashisms="${bashisms}${name}: uses [[ ]] test
"
    fi
    
    # Check for 'local' keyword as a bash keyword (not just the word "local")
    # Look for 'local varname=' or 'local varname' at start of word
    if grep -E '^[^#]*\blocal[[:space:]]+[a-zA-Z_]' "$tutorial" >/dev/null 2>&1; then
      bashisms="${bashisms}${name}: uses 'local' keyword
"
    fi
    
    # Check for echo -e or echo -n (but not in comments or in antipatterns tutorial)
    case "$name" in
      28_posix_vs_bash.sh|29_antipatterns.sh)
        # These tutorials are allowed to show anti-patterns
        ;;
      *)
        if grep -q '^[^#]*echo[[:space:]]*-[en]' "$tutorial"; then
          bashisms="${bashisms}${name}: uses echo -e or echo -n
"
        fi
        ;;
    esac
    
    # Check for == in tests (should use = instead) - but skip example tutorials
    case "$name" in
      28_posix_vs_bash.sh|29_antipatterns.sh)
        ;;
      *)
        if grep -q '\[\s*[^]]*==\s*[^]]*\]' "$tutorial"; then
          bashisms="${bashisms}${name}: uses == instead of =
"
        fi
        ;;
    esac
  done
  
  if [ -n "$bashisms" ]; then
    printf 'FAIL: Bashisms found:\n%s' "$bashisms" >&2
    return 1
  fi
  return 0
}

# Test: Tutorials don't reference "bash" (should say "POSIX sh" or just "shell")
test_no_bash_terminology() {
  bash_refs=""
  
  for tutorial in "$tutorials_dir"/*.sh; do
    [ -f "$tutorial" ] || continue
    name=$(basename "$tutorial")
    
    # Skip the POSIX vs Bash tutorial which legitimately discusses Bash
    case "$name" in
      28_posix_vs_bash.sh|29_antipatterns.sh)
        continue
        ;;
    esac
    
    # Check for references to "Bash" or "bash" that aren't in shebangs or about Bash itself
    if grep -i 'bash' "$tutorial" | grep -v '^#!/' | grep -v 'checkbashisms' | grep -v 'bash.*completion' >/dev/null 2>&1; then
      bash_refs="${bash_refs}${name}: references Bash
"
    fi
  done
  
  if [ -n "$bash_refs" ]; then
    printf 'FAIL: Bash terminology found:\n%s' "$bash_refs" >&2
    return 1
  fi
  return 0
}

# Test: Tutorials have proper quoting in examples
test_tutorials_quote_variables() {
  unquoted=""
  
  for tutorial in "$tutorials_dir"/*.sh; do
    [ -f "$tutorial" ] || continue
    name=$(basename "$tutorial")
    
    # Skip tutorials that explicitly demonstrate quoting issues
    case "$name" in
      03_quoting.sh|29_antipatterns.sh)
        continue
        ;;
    esac
    
    # Look for common unquoted variable patterns (simplified check)
    # This catches: echo $var, cd $path, test $var
    if grep -E '^[^#]*(echo|cd|test|ls)[[:space:]]+\$[a-zA-Z_]' "$tutorial" | grep -v '"' >/dev/null 2>&1; then
      unquoted="${unquoted}${name}: may have unquoted variables in commands
"
    fi
  done
  
  if [ -n "$unquoted" ]; then
    printf 'FAIL: Possible unquoted variables:\n%s' "$unquoted" >&2
    return 1
  fi
  return 0
}

# Test: All tutorials are executable
test_tutorials_are_executable() {
  non_executable=""
  
  for tutorial in "$tutorials_dir"/*.sh; do
    [ -f "$tutorial" ] || continue
    if [ ! -x "$tutorial" ]; then
      non_executable="${non_executable}$(basename "$tutorial")
"
    fi
  done
  
  if [ -n "$non_executable" ]; then
    printf 'FAIL: Non-executable tutorials:\n%s' "$non_executable" >&2
    return 1
  fi
  return 0
}

# Test: Tutorials are numbered sequentially
test_tutorials_sequential_numbering() {
  expected=0
  gaps=""
  
  for tutorial in "$tutorials_dir"/[0-9]*.sh "$tutorials_dir"/[0-9]*.txt; do
    [ -f "$tutorial" ] || continue
    name=$(basename "$tutorial")
    
    # Extract number (handles both 00 and 0 format)
    num=$(printf '%s' "$name" | sed 's/^\([0-9][0-9]*\).*/\1/' | sed 's/^0*//')
    [ -z "$num" ] && num=0
    
    if [ "$num" != "$expected" ]; then
      gaps="${gaps}Expected ${expected}, found ${num} (${name})
"
    fi
    expected=$((expected + 1))
  done
  
  if [ -n "$gaps" ]; then
    printf 'FAIL: Numbering gaps:\n%s' "$gaps" >&2
    return 1
  fi
  return 0
}

# Run all tests
_run_test_case "all tutorials have POSIX shebang" test_all_tutorials_have_posix_shebang
_run_test_case "no bashisms in tutorials" test_no_bashisms_in_tutorials
_run_test_case "no bash terminology in tutorials" test_no_bash_terminology
_run_test_case "tutorials quote variables properly" test_tutorials_quote_variables
_run_test_case "all tutorials are executable" test_tutorials_are_executable
_run_test_case "tutorials have sequential numbering" test_tutorials_sequential_numbering

_finish_tests
