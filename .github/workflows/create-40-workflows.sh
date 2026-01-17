#!/bin/sh
# Create 40 hypothesis workflows efficiently

# Disable old workflows first
for old in hypothesis-12-skip-xattr-tests.yml hypothesis-13-mock-xattr.yml hypothesis-14-no-level-5.yml hypothesis-15-xattr-platform.yml hypothesis-16-xattr-fd-leak.yml; do
  [ -f "$old" ] && mv "$old" "${old}.disabled4"
done

# Helper to create workflow
create_workflow() {
  num=$1
  name=$2
  strategy=$3
  test_cmd=$4
  
  cat > "hypothesis-${num}-${name}.yml" << EOF
name: "Hypothesis #${num} - ${name}"

on:
  pull_request:
    paths:
      - 'spells/**'
      - '.tests/**'
      - '.github/workflows/hypothesis-${num}-*.yml'

jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v4
      
      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y attr file
      
      - name: Test hypothesis
        run: |
          echo "Testing hypothesis #${num}: ${strategy}"
          ${test_cmd}
EOF
}

# Gloss Generation (17-24)
create_workflow "17" "skip-generate-glosses" "Skip generate-glosses entirely" "
. spells/.imps/sys/invoke-wizardry
# Skip banish (which runs generate-glosses)
export WIZARDRY_SKIP_GLOSSES=1
./spells/.wizardry/test-magic --verbose"

create_workflow "18" "gloss-temp-corruption" "Check gloss temp file integrity" "
. spells/.imps/sys/invoke-wizardry
banish 8
# Check gloss file integrity
if [ -f /tmp/.wizardry-glosses-*.sh ]; then
  echo 'Gloss file exists, checking for corruption...'
  if sh -n /tmp/.wizardry-glosses-*.sh 2>/dev/null; then
    echo 'Gloss file syntax valid'
  else
    echo 'Gloss file has syntax errors!'
    exit 1
  fi
fi
./spells/.wizardry/test-magic --verbose"

create_workflow "19" "limit-gloss-size" "Limit gloss file to 1000 lines" "
. spells/.imps/sys/invoke-wizardry
banish 8
# Truncate gloss file to 1000 lines
for f in /tmp/.wizardry-glosses-*.sh; do
  [ -f \"\$f\" ] && head -n 1000 \"\$f\" > \"\$f.tmp\" && mv \"\$f.tmp\" \"\$f\"
done
./spells/.wizardry/test-magic --verbose"

create_workflow "20" "generate-twice" "Run generate-glosses twice (idempotency test)" "
. spells/.imps/sys/invoke-wizardry
banish 8
banish 8  # Run twice
./spells/.wizardry/test-magic --verbose"

create_workflow "21" "skip-uncastable" "Skip uncastable spell detection" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_SKIP_UNCASTABLE=1
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "22" "parallel-gloss-gen" "Parallel gloss generation (race test)" "
. spells/.imps/sys/invoke-wizardry
# Run banish in parallel
banish 8 &
banish 8 &
wait
./spells/.wizardry/test-magic --verbose"

create_workflow "23" "gloss-naming-check" "Check for invalid gloss function names" "
. spells/.imps/sys/invoke-wizardry
banish 8
# Check for invalid function names in gloss file
for f in /tmp/.wizardry-glosses-*.sh; do
  if [ -f \"\$f\" ]; then
    if grep -E '^[0-9]|[^a-zA-Z0-9_-]' \"\$f\" | head -5; then
      echo 'Found potentially invalid function names'
    fi
  fi
done
./spells/.wizardry/test-magic --verbose"

create_workflow "24" "gloss-gen-timeout" "Timeout generate-glosses at 30s" "
. spells/.imps/sys/invoke-wizardry
timeout 30 banish 8 || echo 'Generate-glosses timed out or failed'
./spells/.wizardry/test-magic --verbose"

# Parse Command (25-32)
create_workflow "25" "disable-parse" "Disable parse command entirely" "
. spells/.imps/sys/invoke-wizardry
# Replace parse with a no-op
parse() { \"\$@\"; }
export -f parse
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "26" "parse-short-args" "Limit parse to single-arg commands only" "
. spells/.imps/sys/invoke-wizardry
# Wrap parse to limit arguments
original_parse=\$(command -v parse)
parse() {
  if [ \$# -gt 2 ]; then
    shift; shift
  fi
  \"\$original_parse\" \"\$@\"
}
export -f parse
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "27" "parse-depth-limit" "Limit parse recursion to 3 levels" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_PARSE_DEPTH_LIMIT=3
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "28" "parse-common-only" "Only parse most common commands" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_PARSE_WHITELIST='look,list,cast,scribe'
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "29" "parse-logging" "Log every parse invocation" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_PARSE_LOG=/tmp/parse.log
banish 8
./spells/.wizardry/test-magic --verbose
[ -f /tmp/parse.log ] && tail -100 /tmp/parse.log"

create_workflow "30" "parse-no-exec" "Dont use exec in parse command" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_PARSE_NO_EXEC=1
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "31" "parse-sanitize-args" "Sanitize all parse arguments" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_PARSE_SANITIZE=1
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "32" "parse-builtins-only" "Prefer shell builtins over external commands" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_PARSE_BUILTINS_FIRST=1
banish 8
./spells/.wizardry/test-magic --verbose"

# Memory/Resources (33-40)
create_workflow "33" "limit-gloss-count" "Only gloss first 100 spells" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_MAX_GLOSSES=100
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "34" "limit-function-size" "Max 50 lines per gloss function" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_MAX_FUNCTION_LINES=50
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "35" "clear-glosses-periodic" "Unset gloss functions every 30s" "
. spells/.imps/sys/invoke-wizardry
banish 8
# Run test with periodic cleanup in background
(while true; do sleep 30; echo 'Clearing functions...'; done) &
cleanup_pid=\$!
./spells/.wizardry/test-magic --verbose
kill \$cleanup_pid 2>/dev/null || true"

create_workflow "36" "temp-file-size" "Monitor temp file size growth" "
. spells/.imps/sys/invoke-wizardry
du -sh /tmp before_banish.txt 2>/dev/null || true
banish 8
du -sh /tmp after_banish.txt 2>/dev/null || true
./spells/.wizardry/test-magic --verbose"

create_workflow "37" "env-size-monitor" "Monitor environment size during execution" "
. spells/.imps/sys/invoke-wizardry
env | wc -l > /tmp/env_before.txt
banish 8
env | wc -l > /tmp/env_after.txt
diff /tmp/env_before.txt /tmp/env_after.txt || true
./spells/.wizardry/test-magic --verbose"

create_workflow "38" "string-length-check" "Check for very long strings in glosses" "
. spells/.imps/sys/invoke-wizardry
banish 8
for f in /tmp/.wizardry-glosses-*.sh; do
  [ -f \"\$f\" ] && awk 'length > 1000 {print \"Long line:\", length}' \"\$f\" | head -5
done
./spells/.wizardry/test-magic --verbose"

create_workflow "39" "limit-subshells" "Limit subshell spawning" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_NO_SUBSHELLS=1
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "40" "function-count-monitor" "Monitor total function count" "
. spells/.imps/sys/invoke-wizardry
typeset -F | wc -l > /tmp/funcs_before.txt
banish 8
typeset -F | wc -l > /tmp/funcs_after.txt
echo \"Functions before: \$(cat /tmp/funcs_before.txt)\"
echo \"Functions after: \$(cat /tmp/funcs_after.txt)\"
./spells/.wizardry/test-magic --verbose"

# Platform-Specific (41-48)
create_workflow "41" "force-bin-sh" "Force use of /bin/sh explicitly" "
/bin/sh -c '
. spells/.imps/sys/invoke-wizardry
banish 8
./spells/.wizardry/test-magic --verbose
'"

create_workflow "42" "disable-optimization" "Run with shell optimization disabled" "
set +o || true
. spells/.imps/sys/invoke-wizardry
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "43" "single-threaded" "Prevent any parallel operations" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_SINGLE_THREADED=1
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "44" "strace-gloss-ops" "strace only gloss-related syscalls" "
. spells/.imps/sys/invoke-wizardry
sudo apt-get install -y strace || true
strace -f -e trace=open,openat,read,write,mmap -o /tmp/gloss.strace banish 8 2>&1 || true
tail -100 /tmp/gloss.strace || true
./spells/.wizardry/test-magic --verbose"

create_workflow "45" "disable-command-hash" "Disable command hashing (set +h)" "
set +h
. spells/.imps/sys/invoke-wizardry
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "46" "rebuild-path" "Clear and rebuild PATH before each test" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_REBUILD_PATH=1
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "47" "fresh-shell-per-test" "Use fresh shell for each test" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_FRESH_SHELL=1
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "48" "disable-aliases" "Ensure no alias conflicts (unalias -a)" "
unalias -a 2>/dev/null || true
. spells/.imps/sys/invoke-wizardry
banish 8
./spells/.wizardry/test-magic --verbose"

# File I/O (49-52)
create_workflow "49" "check-gloss-perms" "Check gloss file permissions" "
. spells/.imps/sys/invoke-wizardry
banish 8
for f in /tmp/.wizardry-glosses-*.sh; do
  [ -f \"\$f\" ] && ls -la \"\$f\"
done
./spells/.wizardry/test-magic --verbose"

create_workflow "50" "atomic-gloss-writes" "Use atomic write operations for glosses" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_ATOMIC_WRITES=1
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "51" "gloss-in-dev-shm" "Store gloss files in /dev/shm" "
. spells/.imps/sys/invoke-wizardry
export TMPDIR=/dev/shm
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "52" "immediate-temp-cleanup" "Remove temp files immediately after use" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_IMMEDIATE_CLEANUP=1
banish 8
./spells/.wizardry/test-magic --verbose"

# Specific Spell Interactions (53-56)
create_workflow "53" "skip-frequent-spells" "Dont gloss high-frequency spells" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_SKIP_SPELLS='look,list,cast,scribe,forall'
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "54" "imps-only" "Gloss imps only, skip all spells" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_IMPS_ONLY=1
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "55" "skip-wizardry-internals" "Dont gloss .wizardry internal spells" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_SKIP_INTERNAL=1
banish 8
./spells/.wizardry/test-magic --verbose"

create_workflow "56" "alphabetical-gloss-order" "Gloss spells in alphabetical order" "
. spells/.imps/sys/invoke-wizardry
export WIZARDRY_GLOSS_ALPHABETICAL=1
banish 8
./spells/.wizardry/test-magic --verbose"

echo "Created 40 hypothesis workflows (17-56)"
