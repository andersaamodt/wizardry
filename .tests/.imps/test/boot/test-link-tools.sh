#!/bin/sh
# Test link-tools imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_links_tools() {
  tmpdir=$(_make_tempdir)
  _link_tools "$tmpdir" cat
  [ -L "$tmpdir/cat" ]
}

test_skips_existing() {
  tmpdir=$(_make_tempdir)
  printf '#!/bin/sh\n' > "$tmpdir/cat"
  chmod +x "$tmpdir/cat"
  _link_tools "$tmpdir" cat
  # Should still be a regular file, not a symlink
  [ -f "$tmpdir/cat" ] && [ ! -L "$tmpdir/cat" ]
}

_run_test_case "link-tools creates symlinks" test_links_tools
_run_test_case "link-tools skips existing files" test_skips_existing

_finish_tests
