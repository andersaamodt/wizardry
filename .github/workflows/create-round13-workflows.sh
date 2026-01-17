#!/bin/bash
# Create Round 13 hypothesis workflows - Test framework focus

create_workflow() {
  local num=$1
  local name=$2
  local desc=$3
  local test_cmd=$4
  
  cat > "hypothesis-${num}-${name}.yml" << EOF
name: "Hypothesis #${num}: ${desc}"

on:
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  test-ubuntu:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    env:
      WIZARDRY_OS_LABEL: ubuntu
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Make scripts executable
        run: chmod +x spells/.arcana/mud/install-mud spells/.arcana/tor/setup-tor spells/.imps/fs/xattr-helper-usable spells/.imps/fs/xattr-list-keys spells/.imps/fs/xattr-read-value
      
      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y bubblewrap uidmap attr file
        
      - name: Setup user namespaces
        run: |
          sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "\$(whoami)"
          sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 root
          {
            echo 'kernel.unprivileged_userns_clone=1'
            echo 'kernel.apparmor_restrict_unprivileged_userns=0'
          } | sudo tee /etc/sysctl.d/99-unprivileged-userns.conf
          sudo sysctl --system
      
      - name: Test bubblewrap
        run: |
          if bwrap --unshare-user-try --ro-bind / / /bin/true; then
            echo "bubblewrap usable with user namespaces"
          elif sudo -n bwrap --unshare-user-try --ro-bind / / /bin/true; then
            echo "bubblewrap usable via sudo with user namespaces"
          elif sudo -n bwrap --ro-bind / / /bin/true; then
            echo "bubblewrap usable via sudo"
          else
            echo "bubblewrap unusable; proceeding without sandboxing" >&2
          fi
      
      - name: ${desc}
        run: |
          ${test_cmd}
EOF
}

# Test Framework Bypass
create_workflow "167" "skip-test-magic" "Skip test-magic entirely" \
  ". spells/.imps/sys/invoke-wizardry && banish 8 && echo 'Tests skipped, glosses generated'"

create_workflow "168" "single-test-file" "Run single test directly" \
  ". spells/.imps/sys/invoke-wizardry && banish 8 && /bin/sh .tests/common/test-common-tests.sh"

create_workflow "169" "no-test-preload" "Disable test framework preload" \
  "unset WIZARDRY_TEST_MODE && . spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose"

create_workflow "170" "echo-instead-of-test" "Simple echo instead of test-magic" \
  ". spells/.imps/sys/invoke-wizardry && banish 8 && echo 'All tests pass'"

create_workflow "171" "sh-for-tests" "Force sh for test execution" \
  "/bin/sh -c '. spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose'"

# Test Execution
create_workflow "172" "limit-10-tests" "Limit to 10 tests maximum" \
  ". spells/.imps/sys/invoke-wizardry && banish 8 && WIZARDRY_MAX_TESTS=10 ./spells/.wizardry/test-magic --verbose"

create_workflow "173" "sequential-tests" "Run tests sequentially" \
  ". spells/.imps/sys/invoke-wizardry && banish 8 && WIZARDRY_TEST_PARALLEL=0 ./spells/.wizardry/test-magic --verbose"

create_workflow "174" "sleep-between-tests" "Add waits between tests" \
  ". spells/.imps/sys/invoke-wizardry && banish 8 && WIZARDRY_TEST_DELAY=1 ./spells/.wizardry/test-magic --verbose"

# Environment
create_workflow "175" "clear-bash-env" "Clear bash-specific environment" \
  "env -i PATH=\$PATH HOME=\$HOME /bin/bash -c '. spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose'"

create_workflow "176" "clean-subshell-env" "Run in clean subshell" \
  "(. spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose)"

echo "Created 10 Round 13 workflows"
