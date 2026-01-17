#!/bin/sh
# Generate Round 7 hypothesis workflows targeting gloss generation corruption

cat > .github/workflows/hypothesis-77-syntax-check-glosses.yml << 'EOF'
name: "Hypothesis #77 - syntax-check-glosses"
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          echo "Testing hypothesis #77: Validate each generated gloss with sh -n"
          chmod +x spells/.wizardry/generate-glosses
          spells/.wizardry/generate-glosses
          if [ -f "$HOME/.local/share/wizardry/glossary/glosses" ]; then
            sh -n "$HOME/.local/share/wizardry/glossary/glosses" || exit 2
          fi
          . spells/.imps/sys/invoke-wizardry
          banish 8
          ./spells/.wizardry/test-magic --verbose
EOF

cat > .github/workflows/hypothesis-78-character-whitelist.yml << 'EOF'
name: "Hypothesis #78 - character-whitelist"
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          echo "Testing hypothesis #78: Filter function names to [a-zA-Z0-9_-] only"
          sed -i 's/basename "\$f"/basename "\$f" | sed "s\/[^a-zA-Z0-9_-]\/\_\/g"/' spells/.wizardry/generate-glosses
          . spells/.imps/sys/invoke-wizardry
          banish 8
          ./spells/.wizardry/test-magic --verbose
EOF

cat > .github/workflows/hypothesis-91-check-parentheses.yml << 'EOF'
name: "Hypothesis #91 - check-parentheses"
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          echo "Testing hypothesis #91: Validate parentheses balance in glosses"
          chmod +x spells/.wizardry/generate-glosses
          spells/.wizardry/generate-glosses
          if [ -f "$HOME/.local/share/wizardry/glossary/glosses" ]; then
            # Check for unbalanced parens
            if grep -n '(' "$HOME/.local/share/wizardry/glossary/glosses" | wc -l != grep -n ')' "$HOME/.local/share/wizardry/glossary/glosses" | wc -l; then
              echo "ERROR: Unbalanced parentheses detected!"
              exit 2
            fi
          fi
          . spells/.imps/sys/invoke-wizardry
          banish 8
          ./spells/.wizardry/test-magic --verbose
EOF

cat > .github/workflows/hypothesis-93-skip-parse-glosses.yml << 'EOF'
name: "Hypothesis #93 - skip-parse-glosses"
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          echo "Testing hypothesis #93: Don't generate glosses for parse command"
          sed -i '/parse/d' spells/.wizardry/generate-glosses 2>/dev/null || true
          . spells/.imps/sys/invoke-wizardry
          banish 8
          ./spells/.wizardry/test-magic --verbose
EOF

cat > .github/workflows/hypothesis-88-single-line-functions.yml << 'EOF'
name: "Hypothesis #88 - single-line-functions"
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          echo "Testing hypothesis #88: Force all gloss functions to single line"
          chmod +x spells/.wizardry/generate-glosses
          spells/.wizardry/generate-glosses
          if [ -f "$HOME/.local/share/wizardry/glossary/glosses" ]; then
            # Convert multi-line functions to single-line
            sed -i ':a;N;$!ba;s/) {\n/){ /g' "$HOME/.local/share/wizardry/glossary/glosses"
          fi
          . spells/.imps/sys/invoke-wizardry
          banish 8
          ./spells/.wizardry/test-magic --verbose
EOF

echo "Created 5 key Round 7 hypothesis workflows"
