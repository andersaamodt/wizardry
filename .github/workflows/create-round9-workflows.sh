#!/bin/sh
# Generate Round 9 hypothesis workflows (40 bash-specific tests)

set -eu

cd "$(dirname "$0")"

# First, disable Round 8 workflows
for f in hypothesis-97-*.yml hypothesis-98-*.yml hypothesis-99-*.yml hypothesis-100-*.yml \
         hypothesis-101-*.yml hypothesis-102-*.yml hypothesis-103-*.yml hypothesis-104-*.yml \
         hypothesis-105-*.yml hypothesis-106-*.yml; do
  if [ -f "$f" ]; then
    mv "$f" "${f}.disabled8"
  fi
done

# Round 9 workflows - 40 bash-specific hypotheses
cat > hypothesis-107-extract-gloss-file.yml <<'EOF'
name: "Hypothesis #107 - Extract gloss file"
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    env:
      WIZARDRY_OS_LABEL: ubuntu
    steps:
      - uses: actions/checkout@v4
      - run: chmod +x install spells/.wizardry/generate-glosses
      - run: ./install
      - run: |
          mkdir -p /tmp/gloss-analysis
          ~/.wizardry/spells/.wizardry/generate-glosses > /tmp/gloss-analysis/glosses.sh
          head -n 200 /tmp/gloss-analysis/glosses.sh
          wc -l /tmp/gloss-analysis/glosses.sh
      - uses: actions/upload-artifact@v4
        if: always()
        with:
          name: gloss-file-107
          path: /tmp/gloss-analysis/glosses.sh
EOF

cat > hypothesis-108-first-100-functions.yml <<'EOF'
name: "Hypothesis #108 - First 100 functions only"
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    env:
      WIZARDRY_OS_LABEL: ubuntu
    steps:
      - uses: actions/checkout@v4
      - run: chmod +x install spells/.wizardry/generate-glosses
      - run: ./install
      - run: |
          cd ~/.wizardry/spells/.wizardry
          # Modify generate-glosses to limit output
          cp generate-glosses generate-glosses.orig
          # Add early exit after 100 functions (inject after emit_first_word_gloss function)
          sed -i '/^emit_first_word_gloss/a\
          _gloss_count=0' generate-glosses
          sed -i '/emit_first_word_gloss "$_emit_first_word"/a\
          _gloss_count=$((_gloss_count + 1))\
          if [ "$_gloss_count" -ge 100 ]; then break; fi' generate-glosses
      - run: banish 8 && test-magic --verbose
EOF

# Continue generating more workflows...
printf "Generated Round 9 hypothesis workflows\n"
