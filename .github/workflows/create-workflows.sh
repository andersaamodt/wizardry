#!/bin/sh
# Create 20 targeted Round 6 hypotheses based on breakthrough

for i in 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76; do
  case $i in
    57) name="source-one-at-time"; desc="Source each gloss function individually with sync"; test='sed -i "/eval.*_glosses/s/.*/while IFS= read -r _line; do eval \"\$_line\"; sync; done < \"\$_gloss_file\"/" spells/.imps/sys/word-of-binding' ;;
    58) name="validate-before-eval"; desc="Validate syntax before each eval"; test='sed -i "/eval.*_glosses/i\\    sh -n \"\$_gloss_file\" 2>/dev/null || return 1" spells/.imps/sys/word-of-binding' ;;
    59) name="subshell-per-function"; desc="Eval each function in separate subshell"; test='sed -i "s/eval \"\$_glosses\"/while read _l; do (eval \"\$_l\"); done <<EOF\n\$_glosses\nEOF/" spells/.imps/sys/word-of-binding' ;;
    60) name="limit-glosses-100"; desc="Only source first 100 gloss functions"; test='sed -i "s/cat \"\$_gloss_file\"/head -100 \"\$_gloss_file\"/" spells/.imps/sys/word-of-binding' ;;
    61) name="reverse-gloss-order"; desc="Source glosses in reverse order"; test='sed -i "s/sort/sort -r/" spells/.wizardry/generate-glosses' ;;
    62) name="trap-errors-during-eval"; desc="Trap ERR during gloss evaluation"; test='sed -i "/eval.*_glosses/i\\    trap \"echo ERROR\" ERR" spells/.imps/sys/word-of-binding' ;;
    63) name="set-pipefail"; desc="Enable pipefail during sourcing"; test='sed -i "s/set -eu/set -euo pipefail/" spells/.imps/sys/word-of-binding' ;;
    64) name="clear-hash-before-eval"; desc="Clear command hash before sourcing"; test='sed -i "/eval.*_glosses/i\\    hash -r" spells/.imps/sys/word-of-binding' ;;
    65) name="disable-job-control"; desc="Disable job control during eval"; test='sed -i "s/eval \"\$_glosses\"/set +m; eval \"\$_glosses\"; set -m/" spells/.imps/sys/word-of-binding' ;;
    66) name="atomic-file-read"; desc="Read gloss file atomically into variable"; test='sed -i "s/cat \"\$_gloss_file\"/_g=\$(cat \"\$_gloss_file\"); echo \"\$_g\"/" spells/.imps/sys/word-of-binding' ;;
    67) name="no-command-subst"; desc="Prevent command substitution in glosses"; test='sed -i "s/\$(/BLOCKED_SUBST/g" /tmp/.wizardry-glosses-*.sh 2>/dev/null || true' ;;
    68) name="unset-before-source"; desc="Unset all functions before sourcing"; test='sed -i "/eval.*_glosses/i\\    for _f in \$(compgen -A function); do unset -f \"\$_f\" 2>/dev/null; done" spells/.imps/sys/word-of-binding' ;;
    69) name="minimize-gloss-bodies"; desc="Replace gloss bodies with minimal code"; test='sed -i "s/{.*parse.*exec.*}/{parse \"\$@\";}/" /tmp/.wizardry-glosses-*.sh 2>/dev/null || true' ;;
    70) name="no-exec-in-glosses"; desc="Remove exec from all gloss bodies"; test='sed -i "s/exec //g" /tmp/.wizardry-glosses-*.sh 2>/dev/null || true' ;;
    71) name="local-scope-all"; desc="Add local scope to all gloss functions"; test='sed -i "s/^\\([a-z-]*\\)() {/\\1() { local _s=1;/" /tmp/.wizardry-glosses-*.sh 2>/dev/null || true' ;;
    72) name="source-to-temp-first"; desc="Source to temp location before eval"; test='sed -i "s/eval \"\$_glosses\"/_tf=\$(mktemp); echo \"\$_glosses\" > \"\$_tf\"; . \"\$_tf\"; rm \"\$_tf\"/" spells/.imps/sys/word-of-binding' ;;
    73) name="wait-after-source"; desc="Wait/sync after sourcing glosses"; test='sed -i "/eval.*_glosses/a\\    wait; sync; sleep 0.5" spells/.imps/sys/word-of-binding' ;;
    74) name="readonly-after-define"; desc="Mark functions readonly after define"; test='sed -i "/eval.*_glosses/a\\    readonly -f \$(compgen -A function)" spells/.imps/sys/word-of-binding' ;;
    75) name="disable-optimization"; desc="Disable shell optimization"; test='sed -i "1 a set +o" spells/.imps/sys/word-of-binding' ;;
    76) name="source-alphabetically"; desc="Force alphabetical sourcing order"; test='sed -i "s/cat \"\$_gloss_file\"/sort \"\$_gloss_file\"/" spells/.imps/sys/word-of-binding' ;;
  esac
  
  cat > "hypothesis-$i-$name.yml" << EOF
name: "Hypothesis #$i - $name"

on:
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup
        run: |
          chmod +x spells/.arcana/mud/install-mud spells/.arcana/tor/setup-tor
          chmod +x spells/.imps/fs/xattr-helper-usable spells/.imps/fs/xattr-list-keys spells/.imps/fs/xattr-read-value
          sudo apt-get update && sudo apt-get install -y attr
      
      - name: Test hypothesis
        run: |
          echo "Testing hypothesis #$i: $desc"
          $test
          . spells/.imps/sys/invoke-wizardry
          banish 8
          ./spells/.wizardry/test-magic --verbose
EOF
done

echo "Created 20 Round 6 workflows"
