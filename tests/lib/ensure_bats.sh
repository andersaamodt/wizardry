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

resolve_preconfigured_bats() {
  local candidate

  if [ -n "${BATS_BIN:-}" ]; then
    if [ -x "$BATS_BIN" ]; then
      printf '%s\n' "$BATS_BIN"
      return 0
    fi
    echo "error: BATS_BIN '$BATS_BIN' is not executable" >&2
    return 1
  fi

  if [ -n "${BATS_DIR:-}" ]; then
    for candidate in "$BATS_DIR/bin/bats" "$BATS_DIR/bats-core/bin/bats"; do
      if [ -x "$candidate" ]; then
        printf '%s\n' "$candidate"
        return 0
      fi
    done
    echo "error: BATS_DIR '$BATS_DIR' does not contain a bats executable" >&2
    return 1
  fi

  if ensure_command bats; then
    command -v bats
    return 0
  fi

  return 1
}

sync_component_from_dir() {
  local name=$1
  local check_path=$2

  if [ -z "${BATS_DIR:-}" ]; then
    return 1
  fi

  local src="$BATS_DIR/$name"
  local dest="$VENDOR_DIR/$name"

  if [ ! -d "$src" ] || [ ! -e "$src/$check_path" ]; then
    echo "error: BATS_DIR '$BATS_DIR' is missing $name/$check_path" >&2
    return 1
  fi

  local abs_src abs_dest
  abs_src=$(cd "$src" && pwd)
  if [ -d "$dest" ]; then
    abs_dest=$(cd "$dest" && pwd)
    if [ "$abs_src" = "$abs_dest" ]; then
      return 0
    fi
    if [ -f "$dest/.version" ] && [ -f "$src/.version" ] && \
       [ "$(<"$dest/.version")" = "$(<"$src/.version")" ]; then
      return 0
    fi
  fi

  mkdir -p "$VENDOR_DIR"
  rm -rf "$dest"
  if ! cp -R "$src" "$dest"; then
    echo "error: failed to copy $name from '$BATS_DIR'" >&2
    return 1
  fi
}

copy_component_from_prefix() {
  local bats_bin=$1
  local name=$2
  local check_path=$3

  if [ -z "$bats_bin" ]; then
    return 1
  fi

  local bin_dir
  bin_dir=$(dirname "$bats_bin")
  local search_dirs=()
  local candidate prefix

  if prefix=$(cd "$bin_dir/.." 2>/dev/null && pwd); then
    search_dirs+=("$prefix/$name" "$prefix/lib/$name" "$prefix/share/$name" "$prefix/libexec/$name")
  fi
  search_dirs+=("/usr/lib/$name" "/usr/local/lib/$name" "/usr/share/$name")

  for candidate in "${search_dirs[@]}"; do
    if [ -d "$candidate" ] && [ -e "$candidate/$check_path" ]; then
      local abs_candidate
      abs_candidate=$(cd "$candidate" && pwd)
      if [ -d "$VENDOR_DIR/$name" ]; then
        local abs_dest
        abs_dest=$(cd "$VENDOR_DIR/$name" && pwd)
        if [ "$abs_candidate" = "$abs_dest" ]; then
          return 0
        fi
      fi
      local workdir
      workdir=$(mktemp -d)
      if cp -R "$candidate" "$workdir/$name"; then
        mkdir -p "$VENDOR_DIR"
        rm -rf "$VENDOR_DIR/$name"
        mv "$workdir/$name" "$VENDOR_DIR/$name"
        rm -rf "$workdir"
        return 0
      fi
      rm -rf "$workdir"
      echo "error: failed to copy $name from '$candidate'" >&2
      return 1
    fi
  done

  return 1
}

ensure_component() {
  local bats_bin=$1
  local name=$2
  local version=$3
  local url=$4
  local check_path=$5

  if install_component "$name" "$version" "$url" "$check_path"; then
    return 0
  fi

  if copy_component_from_prefix "$bats_bin" "$name" "$check_path"; then
    return 0
  fi

  return 1
}

ensure_helper_availability() {
  local bats_bin=$1

  if [ -n "${BATS_DIR:-}" ]; then
    sync_component_from_dir bats-support load.bash
    sync_component_from_dir bats-assert load.bash
    sync_component_from_dir bats-mock stub.bash
    return
  fi

  ensure_component "$bats_bin" bats-support "$BATS_SUPPORT_VERSION" "https://github.com/bats-core/bats-support/archive/refs/tags/$BATS_SUPPORT_VERSION.tar.gz" "load.bash"
  ensure_component "$bats_bin" bats-assert "$BATS_ASSERT_VERSION" "https://github.com/bats-core/bats-assert/archive/refs/tags/$BATS_ASSERT_VERSION.tar.gz" "load.bash"
  ensure_component "$bats_bin" bats-mock "$BATS_MOCK_VERSION" "https://github.com/jasonkarns/bats-mock/archive/refs/tags/$BATS_MOCK_VERSION.tar.gz" "stub.bash"
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
  local preconfigured
  preconfigured=$(resolve_preconfigured_bats) || preconfigured=""

  if [ -z "$preconfigured" ]; then
    install_component bats-core "$BATS_CORE_VERSION" "https://github.com/bats-core/bats-core/archive/refs/tags/$BATS_CORE_VERSION.tar.gz" "bin/bats"
    preconfigured="$VENDOR_DIR/bats-core/bin/bats"
  fi

  ensure_helper_availability "$preconfigured"

  printf '%s\n' "$preconfigured"
}

main "$@"
