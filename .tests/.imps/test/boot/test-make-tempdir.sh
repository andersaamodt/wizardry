#!/bin/sh
# Test make-tempdir imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_creates_dir() {
  tmpdir=$(make_tempdir)
  [ -d "$tmpdir" ]
}

test_unique_paths() {
  dir1=$(make_tempdir)
  dir2=$(make_tempdir)
  [ "$dir1" != "$dir2" ]
}

run_test_case "make-tempdir creates directory" test_creates_dir
run_test_case "make-tempdir creates unique directories" test_unique_paths

finish_tests
