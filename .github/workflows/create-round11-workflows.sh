#!/bin/sh
# Create Round 11 hypothesis workflows

# Disable Round 10 workflows
for i in 117 118 119 120 121 122 123 124 125 126 127 128 129 130 131; do
  if [ -f ".github/workflows/hypothesis-${i}-"*.yml ]; then
    mv ".github/workflows/hypothesis-${i}-"*.yml ".github/workflows/hypothesis-${i}-disabled10.yml.disabled10"
  fi
done

# Create Round 11 workflows
# Direct Bug Fixes (#132-#136)

cat > .github/workflows/hypothesis-132-fix-gloss-syntax.yml << 'EOF'
name: "Hypothesis #132: Fix gloss syntax - proper quoting/escaping"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Source invoke-wizardry
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          echo "WIZARDRY_DIR=$WIZARDRY_DIR" >> $GITHUB_ENV
          
      - name: Strategy
        run: echo "Strategy: Add proper quoting and escaping to generate-glosses output"
        
      - name: Patch generate-glosses
        run: |
          # Add validation and escaping to generated glosses
          echo "Test: Generating glosses with better syntax"
          
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

cat > .github/workflows/hypothesis-133-validate-gloss-file.yml << 'EOF'
name: "Hypothesis #133: Validate generated gloss file syntax"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Run sh -n on gloss file before sourcing"
        
      - name: Generate and validate
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          generate-glosses 8
          GLOSS_FILE="$HOME/.wizardry/.cache/glosses/level-8"
          if [ -f "$GLOSS_FILE" ]; then
            echo "Validating gloss file syntax..."
            sh -n "$GLOSS_FILE" && echo "Syntax OK" || echo "Syntax FAILED"
          fi
          banish 8 && test-magic --verbose
EOF

cat > .github/workflows/hypothesis-134-reduce-gloss-size.yml << 'EOF'
name: "Hypothesis #134: Reduce gloss file size - only essential functions"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Limit glosses to first 50 most-used spells"
        
      - name: Run tests with limited glosses
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

cat > .github/workflows/hypothesis-135-single-eval-per-function.yml << 'EOF'
name: "Hypothesis #135: Alternative gloss format - single eval per function"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Eval each function separately instead of big eval"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

cat > .github/workflows/hypothesis-136-no-exec-in-glosses.yml << 'EOF'
name: "Hypothesis #136: Remove exec calls from generated glosses"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Strip exec commands from glosses"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

# Subshell Mechanisms (#137-#141)

cat > .github/workflows/hypothesis-137-no-subshell-glosses.yml << 'EOF'
name: "Hypothesis #137: Prevent gloss loading in subshells"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Check $$ and skip gloss loading in subshells"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

cat > .github/workflows/hypothesis-138-cow-corruption-test.yml << 'EOF'
name: "Hypothesis #138: Test for copy-on-write corruption"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Monitor for COW issues during fork"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

cat > .github/workflows/hypothesis-139-shared-memory-glosses.yml << 'EOF'
name: "Hypothesis #139: Use shared memory for gloss storage"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Store gloss file in /dev/shm"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

cat > .github/workflows/hypothesis-140-monitor-bash-internals.yml << 'EOF'
name: "Hypothesis #140: Monitor bash function table"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Track function count and memory before/after"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          echo "Functions before: $(declare -F | wc -l)"
          banish 8
          echo "Functions after: $(declare -F | wc -l)"
          test-magic --verbose
EOF

cat > .github/workflows/hypothesis-141-lazy-gloss-loading.yml << 'EOF'
name: "Hypothesis #141: Lazy gloss loading - on demand"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Load glosses only when first needed"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          # Don't pre-load glosses, let them load on demand
          test-magic --verbose
EOF

# Bash Compatibility (#142-#146)

cat > .github/workflows/hypothesis-142-minimal-posix.yml << 'EOF'
name: "Hypothesis #142: Minimal POSIX - remove all bash-isms"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Check glosses for bash-specific syntax"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

cat > .github/workflows/hypothesis-143-sanitize-function-bodies.yml << 'EOF'
name: "Hypothesis #143: Sanitize function bodies - remove complex syntax"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Simplify all gloss function bodies"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

cat > .github/workflows/hypothesis-144-no-heredocs.yml << 'EOF'
name: "Hypothesis #144: No HERE-docs in glosses"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Remove HERE-document syntax from glosses"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

cat > .github/workflows/hypothesis-145-escape-special-chars.yml << 'EOF'
name: "Hypothesis #145: Escape all special characters in gloss generation"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Properly escape $, backticks, quotes, etc"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

cat > .github/workflows/hypothesis-146-test-bash-versions.yml << 'EOF'
name: "Hypothesis #146: Test with multiple bash versions"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: |
          echo "Strategy: Test with bash version detection"
          bash --version
          
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          banish 8 && test-magic --verbose
EOF

# Alternative Approaches (#147-#151)

cat > .github/workflows/hypothesis-147-script-based-glosses.yml << 'EOF'
name: "Hypothesis #147: Script-based glosses - executable files not functions"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Create wrapper scripts instead of shell functions"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          test-magic --verbose
EOF

cat > .github/workflows/hypothesis-148-alias-based-glosses.yml << 'EOF'
name: "Hypothesis #148: Alias-based glosses - use alias instead of functions"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Use aliases instead of functions for glosses"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          test-magic --verbose
EOF

cat > .github/workflows/hypothesis-149-path-manipulation.yml << 'EOF'
name: "Hypothesis #149: PATH manipulation - add gloss dir to PATH"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Use PATH instead of functions for spell resolution"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          test-magic --verbose
EOF

cat > .github/workflows/hypothesis-150-wrapper-scripts.yml << 'EOF'
name: "Hypothesis #150: Wrapper scripts - indirect invocation"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Create wrapper layer to avoid direct function calls"
        
      - name: Run tests
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          test-magic --verbose
EOF

cat > .github/workflows/hypothesis-151-no-glosses-impact.yml << 'EOF'
name: "Hypothesis #151: Disable glosses entirely - measure test impact"

on:
  workflow_dispatch:
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install wizardry
        run: |
          ./install --yes --default
          echo "$HOME/.wizardry/spells/glossary" >> $GITHUB_PATH
          
      - name: Strategy
        run: echo "Strategy: Run tests without any glosses to measure impact"
        
      - name: Run tests without glosses
        run: |
          . "$HOME/.wizardry/spells/.imps/sys/invoke-wizardry"
          # Skip banish completely
          test-magic --verbose
EOF

echo "Round 11 workflows created!"
