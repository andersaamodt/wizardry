#!/bin/sh
set -eu

make_fixture() {
  fixture=$(make_tempdir)
  mkdir -p "$fixture/bin" "$fixture/log" "$fixture/home/.local/bin"
  printf '%s\n' "$fixture"
}

write_apt_stub() {
  fixture=$1
  cat <<'STUB' >"$fixture/bin/apt-get"
#!/bin/sh
echo "$0 $*" >>"${APT_LOG:?}" || exit 1
exit ${APT_EXIT:-0}
STUB
  chmod +x "$fixture/bin/apt-get"
}

write_sudo_stub() {
  fixture=$1
  cat <<'STUB' >"$fixture/bin/sudo"
#!/bin/sh
exec "$@"
STUB
  chmod +x "$fixture/bin/sudo"
}

write_command_stub() {
  dir=$1
  name=$2
  cat <<'STUB' >"$dir/$name"
#!/bin/sh
exit 0
STUB
  chmod +x "$dir/$name"
}

provide_basic_tools() {
  fixture=$1
  for cmd in mktemp mkdir rm cat env ln sh dirname; do
    tool_path=$(command -v "$cmd" 2>/dev/null || true)
    if [ -n "$tool_path" ]; then
      ln -s "$tool_path" "$fixture/bin/$cmd"
    fi
  done
}
