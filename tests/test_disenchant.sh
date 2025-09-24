#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"
source "$(dirname "$0")/lib/stub_helpers.sh"

BASE_PATH=$PATH
attr_stubs=$(wizardry_install_attr_stubs)

# The spell requires a target.
run_script "spells/disenchant"
expect_exit_code 1
expect_in_output "Error: No file specified" "$RUN_STDOUT"

# Provide a scroll with a single enchantment.
disenchant_tmp=$(make_temp_dir)
attr_store="$disenchant_tmp/attrs"
scroll="$disenchant_tmp/scroll.txt"
printf 'plain text' >"$scroll"
ATTR_STORAGE_DIR="$attr_store" "$attr_stubs/xattr" -w color blue "$scroll"

cat <<'STUB' >"$disenchant_tmp/read-magic"
#!/usr/bin/env bash
echo "color: blue"
STUB
chmod +x "$disenchant_tmp/read-magic"

pushd "$disenchant_tmp" >/dev/null
RUN_PATH_OVERRIDE="$(wizardry_join_paths "$attr_stubs" "$BASE_PATH")" \
  ATTR_STORAGE_DIR="$attr_store" run_script "spells/disenchant" "scroll.txt" "color"
popd >/dev/null
expect_exit_code 0
expect_in_output "Disenchanted color attribute" "$RUN_STDOUT"

remaining=$(ATTR_STORAGE_DIR="$attr_store" "$attr_stubs/xattr" -p color "$scroll" 2>/dev/null || echo missing)
expect_eq "missing" "$remaining"

assert_all_expectations_met
