#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_add_pkgin_to_path_adds_paths() {
  # Create a fake pkgin structure
  tmp_pkg_dir="$WIZARDRY_TMPDIR/test-pkgin"
  mkdir -p "$tmp_pkg_dir/bin" "$tmp_pkg_dir/sbin"
  
  # Create a fake pkgin executable
  printf '#!/bin/sh\nprintf "fake pkgin\\n"\n' > "$tmp_pkg_dir/bin/pkgin"
  chmod +x "$tmp_pkg_dir/bin/pkgin"
  
  # Test that sourcing adds to PATH
  OUTPUT=$(sh -c "cd '$test_root' && PKGIN_CANDIDATES='$tmp_pkg_dir/bin/pkgin' && export PKGIN_CANDIDATES && set -eu && . spells/.imps/sys/add-pkgin-to-path && printf '%s' \"\$PATH\"" 2>&1)
  STATUS=$?
  export STATUS OUTPUT
  
  [ "$STATUS" -eq 0 ] || { TEST_FAILURE_REASON="add-pkgin-to-path failed with status $STATUS"; return 1; }
  case "$OUTPUT" in
    *"$tmp_pkg_dir/sbin"*) return 0 ;;
    *) TEST_FAILURE_REASON="PATH does not contain expected sbin directory: $OUTPUT"; return 1 ;;
  esac
}

test_add_pkgin_to_path_succeeds() {
  # Test that it succeeds even when pkgin is already in PATH
  OUTPUT=$(sh -c "cd '$test_root' && set -eu && . spells/.imps/sys/add-pkgin-to-path && echo 'success'" 2>&1)
  STATUS=$?
  export STATUS OUTPUT
  
  [ "$STATUS" -eq 0 ] || { TEST_FAILURE_REASON="add-pkgin-to-path failed"; return 1; }
  case "$OUTPUT" in
    *success*) return 0 ;;
    *) TEST_FAILURE_REASON="did not complete successfully"; return 1 ;;
  esac
}

run_test_case "adds pkgin paths to PATH" test_add_pkgin_to_path_adds_paths
run_test_case "succeeds when pkgin in PATH" test_add_pkgin_to_path_succeeds
finish_tests
