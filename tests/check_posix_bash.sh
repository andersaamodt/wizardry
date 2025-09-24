#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
DEFAULT_TARGETS=()

collect_targets() {
  local -n out=$1
  if [ -n "${COVERAGE_TARGETS:-}" ]; then
    read -r -a out <<<"$COVERAGE_TARGETS"
    return
  fi
  mapfile -t out < <(cd "$ROOT_DIR/spells" && find . -type f | sort)
  local i
  for i in "${!out[@]}"; do
    out[$i]="spells/${out[$i]#./}"
  done
}

warn_non_posix_bash() {
  local script=$1
  local abs="$ROOT_DIR/$script"
  if [ ! -f "$abs" ]; then
    return
  fi

  local first_line shebang_line interpreter arg shell
  if ! IFS= read -r first_line <"$abs"; then
    first_line=""
  fi

  if [[ $first_line != "#!"* ]]; then
    printf 'Warning: %s does not declare a shebang; expected "#!/bin/sh" for plain POSIX Bash.\n' "$script" >&2
    return
  fi

  shebang_line=${first_line#\#!}
  shebang_line=${shebang_line# } # remove leading space if present
  if [ -z "$shebang_line" ]; then
    printf 'Warning: %s has an empty shebang; expected "#!/bin/sh" for plain POSIX Bash.\n' "$script" >&2
    return
  fi

  read -r interpreter arg _ <<<"$shebang_line"
  shell=""
  case "$interpreter" in
    /usr/bin/env)
      shell=$arg
      ;;
    *)
      shell=$(basename "$interpreter")
      ;;
  esac

  if [ "$shell" != "sh" ]; then
    printf 'Warning: %s uses "%s"; rewrite it for plain POSIX Bash with "#!/bin/sh".\n' "$script" "$first_line" >&2
  fi
}

collect_targets DEFAULT_TARGETS

for script in "${DEFAULT_TARGETS[@]}"; do
  warn_non_posix_bash "$script"
done
