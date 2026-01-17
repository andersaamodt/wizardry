#!/bin/bash
# Generate Round 12 hypothesis workflows - Core mechanism alternatives

create_workflow() {
  local num="$1"
  local name="$2"
  local desc="$3"
  local test_cmd="$4"
  
  cat > ".github/workflows/hypothesis-${num}-${name}.yml" << EOF
name: "Hypothesis #${num}: ${desc}"

on:
  pull_request:
    paths:
      - '.github/workflows/hypothesis-${num}-*.yml'
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    timeout-minutes: 3
    steps:
      - uses: actions/checkout@v4
      - name: Setup
        run: |
          chmod +x spells/.arcana/mud/install-mud spells/.arcana/tor/setup-tor spells/.imps/fs/xattr-helper-usable spells/.imps/fs/xattr-list-keys spells/.imps/fs/xattr-read-value
          sudo apt-get update && sudo apt-get install -y bubblewrap uidmap attr file
          
      - name: Test hypothesis
        run: |
${test_cmd}
EOF
}

# Core gloss bypass strategies
create_workflow 152 "no-word-of-binding" "Skip word-of-binding entirely" '          
          # Modify banish to skip word-of-binding call
          sed -i "/word_of_binding/d" spells/.imps/wards/banish
          . spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose'

create_workflow 153 "empty-gloss-file" "Generate empty gloss file" '          
          # Make generate-glosses create empty file
          echo "# Empty glosses" > /tmp/test-glosses
          export WIZARDRY_GLOSSES_FILE=/tmp/test-glosses
          . spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose'

create_workflow 154 "disable-parse-gloss" "Disable parse command glossing" '
          # Make parse not use glosses
          sed -i "s/command -v \"\$_spell_name\"/false/" spells/.imps/lex/parse
          . spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose'

create_workflow 155 "hardcoded-glosses" "Use hardcoded gloss functions" '
          # Create minimal hardcoded glosses
          cat > /tmp/glosses.sh << "GLOSS"
look() { exec "\$WIZARDRY_DIR/spells/arcane/look" "\$@"; }
GLOSS
          export WIZARDRY_GLOSSES_FILE=/tmp/glosses.sh
          . spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose'

# Alternative shell invocation
create_workflow 156 "sh-not-bash" "Force /bin/sh explicitly" '
          # Run with explicit sh
          /bin/sh -c ". spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose"'

create_workflow 157 "no-set-eu" "Remove set -eu from key scripts" '
          # Remove set -eu from banish and word-of-binding
          sed -i "/^set -eu/d" spells/.imps/wards/banish spells/.imps/lex/word-of-binding
          . spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose'

# Timing and sequencing
create_workflow 158 "sleep-before-banish" "Add delay before banish" '
          # Add delay to change timing
          . spells/.imps/sys/invoke-wizardry
          sleep 5
          banish 8
          ./spells/.wizardry/test-magic --verbose'

create_workflow 159 "banish-twice" "Call banish multiple times" '
          # Test if second banish works
          . spells/.imps/sys/invoke-wizardry
          banish 8 || true
          sleep 1
          banish 8
          ./spells/.wizardry/test-magic --verbose'

# Process isolation
create_workflow 160 "subshell-banish" "Run banish in explicit subshell" '
          # Test subshell hypothesis differently
          . spells/.imps/sys/invoke-wizardry
          (banish 8)
          ./spells/.wizardry/test-magic --verbose'

create_workflow 161 "background-banish" "Run banish in background" '
          # Background process test
          . spells/.imps/sys/invoke-wizardry
          banish 8 &
          wait
          ./spells/.wizardry/test-magic --verbose'

# Code generation bypass  
create_workflow 162 "no-eval" "Source file instead of eval" '
          # Modify word-of-binding to source instead of eval
          sed -i "s/eval \"\$_glosses\"/. \"\${WIZARDRY_GLOSSES_FILE}\"/" spells/.imps/lex/word-of-binding
          . spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose'

create_workflow 163 "printf-not-cat" "Use printf instead of cat in gloss gen" '
          # Change how glosses are output
          sed -i "s/cat/printf '\''%s\\n'\''/" spells/.wizardry/generate-glosses
          . spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose'

# Memory and limits
create_workflow 164 "tiny-gloss-limit" "Generate only 5 glosses" '
          # Extreme size reduction
          sed -i "1a exit 0" spells/.wizardry/generate-glosses
          echo "look() { :; }" > /tmp/tiny-glosses
          export WIZARDRY_GLOSSES_FILE=/tmp/tiny-glosses
          . spells/.imps/sys/invoke-wizardry && banish 8 && ./spells/.wizardry/test-magic --verbose'

create_workflow 165 "gc-before-banish" "Force garbage collection" '
          # Try to clean up before banish
          . spells/.imps/sys/invoke-wizardry
          unset $(compgen -v | grep -v "^WIZARDRY")
          banish 8
          ./spells/.wizardry/test-magic --verbose'

# Simple functions test
create_workflow 166 "one-function-only" "Define single test function" '
          # Absolute minimal function test
          . spells/.imps/sys/invoke-wizardry
          test_func() { echo "test"; }
          banish 8
          ./spells/.wizardry/test-magic --verbose'

echo "Created 15 Round 12 hypothesis workflows"
