#!/usr/bin/env bash
set -euo pipefail

TEST_DIR=$(cd "$(dirname "$0")/.." && pwd)
VENDOR_DIR="$TEST_DIR/vendor"

BATS_CORE_VERSION="${BATS_CORE_VERSION:-v1.10.0}"
BATS_SUPPORT_VERSION="${BATS_SUPPORT_VERSION:-v0.3.0}"
BATS_ASSERT_VERSION="${BATS_ASSERT_VERSION:-v2.1.0}"
BATS_MOCK_VERSION="${BATS_MOCK_VERSION:-v1.2.5}"

ensure_command() {
  if command -v "$1" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

fetch_tarball() {
  local url=$1
  local destination=$2

  if ensure_command curl; then
    curl -fsSL "$url" -o "$destination"
  elif ensure_command wget; then
    wget -q -O "$destination" "$url"
  else
    echo "error: unable to download $url (need curl or wget)" >&2
    return 1
  fi
}

install_component() {
  local name=$1
  local version=$2
  local url=$3
  local check_path=$4

  local dest="$VENDOR_DIR/$name"
  local stamp="$dest/.version"

  if [ -f "$stamp" ] && [ "$(<"$stamp")" = "$version" ] && [ -e "$dest/$check_path" ]; then
    return 0
  fi

  echo "Fetching $name $version" >&2

  local workdir
  workdir=$(mktemp -d)
  trap "rm -rf '$workdir'" RETURN

  local archive="$workdir/archive.tar.gz"
  if ! fetch_tarball "$url" "$archive"; then
    echo "error: failed to download $name from $url" >&2
    return 1
  fi

  mkdir -p "$workdir/unpack"
  if ! tar -xzf "$archive" -C "$workdir/unpack"; then
    echo "error: failed to extract $name archive" >&2
    return 1
  fi

  local extracted
  extracted=$(find "$workdir/unpack" -mindepth 1 -maxdepth 1 -type d | head -n 1)
  if [ -z "$extracted" ]; then
    echo "error: archive for $name did not contain a directory" >&2
    return 1
  fi

  mkdir -p "$VENDOR_DIR"
  rm -rf "$dest"
  if ! mv "$extracted" "$dest"; then
    echo "error: failed to move $name into place" >&2
    return 1
  fi

  echo "$version" >"$stamp"
  rm -rf "$workdir"
  trap - RETURN

  if [ ! -e "$dest/$check_path" ]; then
    echo "error: expected $check_path inside $dest" >&2
    return 1
  fi
}

main() {
  install_component bats-core "$BATS_CORE_VERSION" "https://github.com/bats-core/bats-core/archive/refs/tags/$BATS_CORE_VERSION.tar.gz" "bin/bats"
  install_component bats-support "$BATS_SUPPORT_VERSION" "https://github.com/bats-core/bats-support/archive/refs/tags/$BATS_SUPPORT_VERSION.tar.gz" "load.bash"
  install_component bats-assert "$BATS_ASSERT_VERSION" "https://github.com/bats-core/bats-assert/archive/refs/tags/$BATS_ASSERT_VERSION.tar.gz" "load.bash"
  install_component bats-mock "$BATS_MOCK_VERSION" "https://github.com/jasonkarns/bats-mock/archive/refs/tags/$BATS_MOCK_VERSION.tar.gz" "stub.bash"

  printf '%s\n' "$VENDOR_DIR/bats-core/bin/bats"
}

main "$@"
