#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  set -euo pipefail
fi

wizardry_stub_base_dir() {
  if [ -n "${TEST_TMPDIR:-}" ]; then
    printf '%s\n' "$TEST_TMPDIR"
  elif [ -n "${BATS_TEST_TMPDIR:-}" ]; then
    printf '%s\n' "$BATS_TEST_TMPDIR"
  else
    printf '%s\n' "${TMPDIR:-/tmp}"
  fi
}

wizardry_create_stub_dir() {
  local base
  base=$(wizardry_stub_base_dir)
  mktemp -d "$base/stubs.XXXXXX"
}

wizardry_join_paths() {
  local result=""
  local part
  for part in "$@"; do
    if [ -z "$part" ]; then
      continue
    fi
    if [ -z "$result" ]; then
      result="$part"
    else
      result="$result:$part"
    fi
  done
  printf '%s\n' "$result"
}

wizardry_install_clipboard_stubs() {
  local dir
  dir=$(wizardry_create_stub_dir)
  local commands=("$@")
  if [ ${#commands[@]} -eq 0 ]; then
    commands=(pbcopy xsel xclip)
  fi
  local cmd
  for cmd in "${commands[@]}"; do
    case "$cmd" in
      pbcopy)
        cat <<'STUB' >"$dir/pbcopy"
#!/usr/bin/env bash
set -euo pipefail
if [ -z "${CLIPBOARD_FILE:-}" ]; then
  echo "pbcopy stub: CLIPBOARD_FILE is not set" >&2
  exit 1
fi
cat >"$CLIPBOARD_FILE"
STUB
        chmod +x "$dir/pbcopy"
        ;;
      xsel)
        cat <<'STUB' >"$dir/xsel"
#!/usr/bin/env bash
set -euo pipefail
if [ -z "${CLIPBOARD_FILE:-}" ]; then
  echo "xsel stub: CLIPBOARD_FILE is not set" >&2
  exit 1
fi
cat >"$CLIPBOARD_FILE"
STUB
        chmod +x "$dir/xsel"
        ;;
      xclip)
        cat <<'STUB' >"$dir/xclip"
#!/usr/bin/env bash
set -euo pipefail
if [ -z "${CLIPBOARD_FILE:-}" ]; then
  echo "xclip stub: CLIPBOARD_FILE is not set" >&2
  exit 1
fi
cat >"$CLIPBOARD_FILE"
STUB
        chmod +x "$dir/xclip"
        ;;
      *)
        echo "Unknown clipboard stub: $cmd" >&2
        return 1
        ;;
    esac
  done
  printf '%s\n' "$dir"
}

wizardry_install_attr_stubs() {
  if [ -z "${ROOT_DIR:-}" ]; then
    echo "ROOT_DIR must be set before calling wizardry_install_attr_stubs" >&2
    return 1
  fi
  local dir
  dir=$(wizardry_create_stub_dir)
  local commands=("$@")
  if [ ${#commands[@]} -eq 0 ]; then
    commands=(attr xattr setfattr getfattr)
  fi
  local cmd
  for cmd in "${commands[@]}"; do
    case "$cmd" in
      attr)
        cat <<'STUB' >"$dir/attr"
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="__ROOT_DIR__"
. "$ROOT_DIR/tests/lib/attr_store.sh"

should_fail() {
  local op=$1
  local flag=${ATTR_FAIL:-}
  case ":${flag}:" in
    *:all:*) return 0 ;;
    *:${op}:*) return 0 ;;
  esac
  return 1
}

if [ "$#" -eq 0 ]; then
  echo "attr: missing arguments" >&2
  exit 1
fi

case $1 in
  -s)
    shift
    key=$1
    shift
    if [ "${1-}" != "-V" ]; then
      echo "attr: expected -V" >&2
      exit 1
    fi
    shift
    value=$1
    shift
    file=$1
    if should_fail set; then
      echo "attr: simulated failure" >&2
      exit 1
    fi
    set_attr_value "$file" "$key" "$value"
    ;;
  -g)
    shift
    key=$1
    shift
    file=$1
    if should_fail get; then
      echo "attr: simulated failure" >&2
      exit 1
    fi
    if ! value=$(get_attr_value "$file" "$key"); then
      printf 'attr_get: Attribute "%s" not found\n' "$key" >&2
      exit 1
    fi
    printf 'Attribute "%s" has a value: %s\n' "$key" "$value"
    ;;
  -r)
    shift
    key=$1
    shift
    file=$1
    if should_fail remove; then
      echo "attr: simulated failure" >&2
      exit 1
    fi
    remove_attr_value "$file" "$key"
    ;;
  -l)
    shift
    file=$1
    if should_fail list; then
      echo "attr: simulated failure" >&2
      exit 1
    fi
    list_attr_keys "$file"
    ;;
  *)
    echo "attr: unsupported operation" >&2
    exit 1
    ;;
 esac
STUB
        sed -i "s|__ROOT_DIR__|$ROOT_DIR|g" "$dir/attr"
        chmod +x "$dir/attr"
        ;;
      xattr)
        cat <<'STUB' >"$dir/xattr"
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="__ROOT_DIR__"
. "$ROOT_DIR/tests/lib/attr_store.sh"

should_fail() {
  local op=$1
  local flag=${XATTR_FAIL:-}
  case ":${flag}:" in
    *:all:*) return 0 ;;
    *:${op}:*) return 0 ;;
  esac
  return 1
}

if [ "$#" -lt 1 ]; then
  echo "xattr: missing arguments" >&2
  exit 1
fi

case $1 in
  -w)
    shift
    key=$1
    shift
    value=$1
    shift
    file=$1
    if should_fail write; then
      echo "xattr: simulated failure" >&2
      exit 1
    fi
    set_attr_value "$file" "$key" "$value"
    ;;
  -p)
    shift
    key=$1
    shift
    file=$1
    if should_fail read; then
      echo "xattr: simulated failure" >&2
      exit 1
    fi
    if ! get_attr_value "$file" "$key"; then
      echo "xattr: [$file] no such xattr: $key" >&2
      exit 1
    fi
    ;;
  -l)
    shift
    file=$1
    if should_fail list; then
      echo "xattr: simulated failure" >&2
      exit 1
    fi
    while IFS= read -r key; do
      value=$(get_attr_value "$file" "$key" || printf '')
      printf '%s: %s\n' "$key" "$value"
    done < <(list_attr_keys "$file")
    ;;
  -d)
    shift
    key=$1
    shift
    file=$1
    if should_fail delete; then
      echo "xattr: simulated failure" >&2
      exit 1
    fi
    remove_attr_value "$file" "$key"
    ;;
  -c)
    shift
    file=$1
    if should_fail clear; then
      echo "xattr: simulated failure" >&2
      exit 1
    fi
    clear_attr_values "$file"
    ;;
  *)
    file=$1
    if should_fail list; then
      echo "xattr: simulated failure" >&2
      exit 1
    fi
    list_attr_keys "$file"
    ;;
 esac
STUB
        sed -i "s|__ROOT_DIR__|$ROOT_DIR|g" "$dir/xattr"
        chmod +x "$dir/xattr"
        ;;
      setfattr)
        cat <<'STUB' >"$dir/setfattr"
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="__ROOT_DIR__"
. "$ROOT_DIR/tests/lib/attr_store.sh"

should_fail() {
  local op=$1
  local flag=${SETFATTR_FAIL:-}
  case ":${flag}:" in
    *:all:*) return 0 ;;
    *:${op}:*) return 0 ;;
  esac
  return 1
}

if [ "$#" -lt 1 ]; then
  echo "setfattr: missing arguments" >&2
  exit 1
fi

case $1 in
  -n)
    shift
    key=$1
    shift
    if [ "${1-}" != "-v" ]; then
      echo "setfattr: expected -v" >&2
      exit 1
    fi
    shift
    value=$1
    shift
    file=$1
    if should_fail write; then
      echo "setfattr: simulated failure" >&2
      exit 1
    fi
    set_attr_value "$file" "$key" "$value"
    ;;
  -x)
    shift
    key=$1
    shift
    file=$1
    if should_fail delete; then
      echo "setfattr: simulated failure" >&2
      exit 1
    fi
    remove_attr_value "$file" "$key"
    ;;
  *)
    echo "setfattr: unsupported arguments" >&2
    exit 1
    ;;
 esac
STUB
        sed -i "s|__ROOT_DIR__|$ROOT_DIR|g" "$dir/setfattr"
        chmod +x "$dir/setfattr"
        ;;
      getfattr)
        cat <<'STUB' >"$dir/getfattr"
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="__ROOT_DIR__"
. "$ROOT_DIR/tests/lib/attr_store.sh"

should_fail() {
  local op=$1
  local flag=${GETFATTR_FAIL:-}
  case ":${flag}:" in
    *:all:*) return 0 ;;
    *:${op}:*) return 0 ;;
  esac
  return 1
}

mode=list
key=""
file=""
while [ $# -gt 0 ]; do
  case $1 in
    -d)
      mode=list
      shift
      ;;
    -h)
      shift
      ;;
    -m|-e)
      shift 2
      ;;
    -n)
      mode=value
      shift
      key=$1
      shift
      ;;
    --only-values)
      shift
      ;;
    --absolute-names)
      shift
      ;;
    *)
      file=$1
      shift
      ;;
  esac
done

if [ -z "$file" ]; then
  echo "getfattr: missing file operand" >&2
  exit 1
fi

if [ "$mode" = "value" ]; then
  if should_fail read; then
    echo "getfattr: simulated failure" >&2
    exit 1
  fi
  if ! value=$(get_attr_value "$file" "$key"); then
    printf 'getfattr: %s: %s: No such attribute\n' "$file" "$key" >&2
    exit 1
  fi
  printf '%s\n' "$value"
  exit 0
fi

if should_fail list; then
  echo "getfattr: simulated failure" >&2
  exit 1
fi
printf '# file: %s\n' "$file"
list_attr_keys "$file" | while IFS= read -r current_key; do
  value=$(get_attr_value "$file" "$current_key" || printf '')
  printf '%s="%s"\n' "$current_key" "$value"
done
STUB
        sed -i "s|__ROOT_DIR__|$ROOT_DIR|g" "$dir/getfattr"
        chmod +x "$dir/getfattr"
        ;;
      *)
        echo "Unknown attr stub: $cmd" >&2
        return 1
        ;;
    esac
  done
  printf '%s\n' "$dir"
}

wizardry_install_systemd_stubs() {
  local dir
  dir=$(wizardry_create_stub_dir)
  cat <<'STUB' >"$dir/ask_yn"
#!/usr/bin/env bash
set -euo pipefail
response_file="${ASK_YN_STUB_FILE:-}"
if [ -z "$response_file" ]; then
  response="${ASK_YN_STUB_RESPONSE:-}"
else
  if [ -s "$response_file" ]; then
    response=$(head -n1 "$response_file")
    tail -n +2 "$response_file" >"$response_file.tmp"
    mv "$response_file.tmp" "$response_file"
  else
    response=""
  fi
fi
if [ -z "$response" ]; then
  exit 1
fi
printf '%s\n' "$response" >&2
case "$response" in
  [Yy]*) exit 0 ;;
  [Nn]*) exit 1 ;;
  *) exit 1 ;;
 esac
STUB
  chmod +x "$dir/ask_yn"

  cat <<'STUB' >"$dir/ask_Yn"
#!/usr/bin/env bash
set -euo pipefail
if [ -z "${ASK_YN_STUB_RESPONSE:-}" ]; then
  exit 1
fi
printf '%s\n' "$ASK_YN_STUB_RESPONSE" >&2
case "$ASK_YN_STUB_RESPONSE" in
  [Yy]*) exit 0 ;;
  [Nn]*) exit 1 ;;
  *) exit 1 ;;
 esac
STUB
  chmod +x "$dir/ask_Yn"

  cat <<'STUB' >"$dir/sudo"
#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -eq 0 ]; then
  exit 0
fi
exec "$@"
STUB
  chmod +x "$dir/sudo"

  cat <<'STUB' >"$dir/systemctl"
#!/usr/bin/env bash
set -euo pipefail
STATE_DIR="${SYSTEMCTL_STATE_DIR:-${TEST_TMPDIR:-/tmp}}/systemctl"
mkdir -p "$STATE_DIR"
subcommand=${1:-}
case "$subcommand" in
  is-active)
    shift
    if [ "${1:-}" = "--quiet" ]; then
      shift
    fi
    service=${1:-}
    if [ -z "$service" ]; then
      echo "systemctl stub: missing service for is-active" >&2
      exit 1
    fi
    if [ -f "$STATE_DIR/$service.active" ]; then
      exit 0
    else
      exit 3
    fi
    ;;
  stop)
    shift
    service=${1:-}
    if [ -z "$service" ]; then
      echo "systemctl stub: missing service for stop" >&2
      exit 1
    fi
    rm -f "$STATE_DIR/$service.active"
    echo "systemctl stub stopped $service" >&2
    ;;
  daemon-reload)
    touch "$STATE_DIR/daemon-reload"
    ;;
  *)
    echo "systemctl stub: unsupported invocation $*" >&2
    exit 1
    ;;
 esac
STUB
  chmod +x "$dir/systemctl"

  printf '%s\n' "$dir"
}

wizardry_install_uname_stub() {
  local dir
  dir=$(wizardry_create_stub_dir)
  cat <<'STUB' >"$dir/uname"
#!/usr/bin/env bash
set -euo pipefail
if [ -n "${FAKE_UNAME_OUTPUT:-}" ]; then
  printf '%s\n' "$FAKE_UNAME_OUTPUT"
  exit 0
fi
if command -v /usr/bin/uname >/dev/null 2>&1; then
  exec /usr/bin/uname "$@"
fi
exec /bin/uname "$@"
STUB
  chmod +x "$dir/uname"
  printf '%s\n' "$dir"
}
