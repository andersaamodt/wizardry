#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"

# Build a study lined with enchanted scrolls.
magic_tmp=$(make_temp_dir)
cat <<'STUB' >"$magic_tmp/read-magic"
#!/usr/bin/env bash
case "$1" in
  heavy.txt)
    for i in $(seq 1 40); do
      printf 'sigil:%d\n' "$i"
    done
    ;;
  light.txt)
    for i in $(seq 1 25); do
      printf 'glyph:%d\n' "$i"
    done
    ;;
  *)
    exit 0
    ;;
esac
STUB
chmod +x "$magic_tmp/read-magic"
printf 'dense' >"$magic_tmp/heavy.txt"
printf 'faint' >"$magic_tmp/light.txt"

pushd "$magic_tmp" >/dev/null
RANDOM=0 run_script "spells/detect-magic"
popd >/dev/null

expect_exit_code 0
expect_in_output "File" "$RUN_STDOUT"
expect_in_output "heavy.txt" "$RUN_STDOUT"
expect_in_output "light.txt" "$RUN_STDOUT"
expect_in_output "I can feel the" "$RUN_STDOUT" "detect-magic should describe the ambience"
expect_not_in_output "ordinary.txt" "$RUN_STDOUT"

assert_all_expectations_met
