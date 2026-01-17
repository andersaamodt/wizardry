#!/bin/sh
# Minimal reproduction for xattr gloss SIGSEGV (exit 139).

show_usage() {
  cat <<'USAGE'
Usage: repro-139-xattr-gloss.sh

Runs a minimal reproduction of the xattr gloss crash under xtrace.
Set XATTR_REPRO_XTRACE=0 to disable xtrace during the call.
USAGE
}

case "${1-}" in
  --help|--usage|-h)
    show_usage
    exit 0
    ;;
  "")
    ;;
  *)
    printf '%s\n' "repro-139-xattr-gloss: unknown argument: $1" >&2
    exit 2
    ;;
esac

set -eu

script_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/.." && pwd -P)

export WIZARDRY_DIR=${WIZARDRY_DIR:-$repo_root}

gloss_file=$(mktemp "${TMPDIR:-/tmp}/wizardry-gloss.XXXXXX")
"$WIZARDRY_DIR/spells/.wizardry/generate-glosses" --output "$gloss_file"
. "$gloss_file"

if ! type xattr 2>/dev/null | grep -q "function"; then
  printf '%s\n' "repro-139-xattr-gloss: xattr gloss function not found" >&2
  exit 1
fi

if ! command -v xattr >/dev/null 2>&1; then
  printf '%s\n' "repro-139-xattr-gloss: xattr command not found" >&2
  exit 1
fi

tmp=$(mktemp "${TMPDIR:-/tmp}/wizardry-xattr.XXXXXX")

xtrace=${XATTR_REPRO_XTRACE:-1}
if [ "$xtrace" -eq 1 ]; then
  set -x
fi

xattr -w user.test value "$tmp"
xattr -p user.test "$tmp"
xattr -d user.test "$tmp"

if [ "$xtrace" -eq 1 ]; then
  set +x
fi

rm -f "$tmp"
