#!/bin/sh
# Generate blank audit table for AUDIT_RESULTS.md
# This script lists all auditable files in the repository and creates
# a markdown table ready for AI-driven audit.

set -eu

cd "$(dirname "$0")/.."

printf "Generating audit table...\n" >&2

# Header
cat << 'EOF'
| File Path | Last Audit | Thoroughness | Result | Code | Docs | Theme | Policy | Ethos | Issues | Fixes |
|-----------|------------|--------------|--------|------|------|-------|--------|-------|--------|-------|
EOF

# Find all auditable files and create table rows
# Categories:
# 1. Shell scripts (spells, imps, install)
# 2. Test scripts
# 3. Documentation
# 4. Templates
# 5. Configuration files

find_files() {
  # Spells (executable shell scripts in spells/)
  find spells -type f ! -path '*/.*' ! -name '*.md' 2>/dev/null | sort
  
  # Install script
  [ -f install ] && printf 'install\n'
  
  # Test scripts
  find .tests -type f -name '*.sh' 2>/dev/null | sort
  
  # Documentation
  find . -maxdepth 1 -name '*.md' 2>/dev/null | sed 's|^\./||' | sort
  find .github -maxdepth 1 -name '*.md' 2>/dev/null | sort
  
  # Templates
  find .templates -type f 2>/dev/null | sort
  
  # Tutorials
  find tutorials -type f -name '*.sh' 2>/dev/null | sort
  find tutorials -type f ! -name '*.sh' 2>/dev/null | sort
  
  # Configuration files that should be audited
  [ -f .gitignore ] && printf '.gitignore\n'
  [ -f .shellcheckrc ] && printf '.shellcheckrc\n'
}

# Generate table rows
find_files | while IFS= read -r file; do
  printf '| %s | - | - | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | ⚪ | - | - |\n' "$file"
done

printf "\nGenerated %d file entries\n" "$(find_files | wc -l)" >&2
