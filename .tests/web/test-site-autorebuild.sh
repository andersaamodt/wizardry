#!/bin/sh

# Tests for site-autorebuild spell.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_site_autorebuild_help() {
  run_cmd sh "$ROOT_DIR/spells/web/site-autorebuild" --help
  assert_success
  assert_output_contains "Usage: site-autorebuild"
  assert_output_contains "watch-daemon"
}

test_site_autorebuild_requires_target() {
  run_cmd sh "$ROOT_DIR/spells/web/site-autorebuild" enable
  assert_status 2
  assert_error_contains "SITENAME required"
}

test_site_autorebuild_local_enable_run_disable() {
  skip-if-compiled || return $?

  web_root=$(temp-dir site-autorebuild-web)
  site_root="$web_root/testsite"
  mkdir -p "$site_root/site/pages"
  printf '%s\n' '# Test page' > "$site_root/site/pages/index.md"

  fake_wizardry=$(temp-dir site-autorebuild-wizardry)
  mkdir -p "$fake_wizardry/spells/web"
  build_log=$(temp-file site-autorebuild-build-log)
  cat > "$fake_wizardry/spells/web/build" <<'EOS'
#!/bin/sh
set -eu
printf '%s\n' "$1" >> "${SITE_AUTOREBUILD_BUILD_LOG:?}"
EOS
  chmod +x "$fake_wizardry/spells/web/build"

  stub_dir=$(temp-dir site-autorebuild-stub)
  cron_file=$(temp-file site-autorebuild-cron)
  cat > "$stub_dir/crontab" <<'EOS'
#!/bin/sh
set -eu
state_file=${CRON_STUB_FILE:?}
if [ "${1-}" = "-l" ]; then
  [ -f "$state_file" ] || exit 1
  cat "$state_file"
  exit 0
fi
[ $# -eq 1 ] || exit 2
cat "$1" > "$state_file"
EOS
  chmod +x "$stub_dir/crontab"

  run_cmd env \
    PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" \
    WEB_WIZARDRY_ROOT="$web_root" \
    WIZARDRY_DIR="$fake_wizardry" \
    CRON_STUB_FILE="$cron_file" \
    SITE_AUTOREBUILD_BUILD_LOG="$build_log" \
    sh "$ROOT_DIR/spells/web/site-autorebuild" enable testsite
  assert_success
  assert_output_contains "enabled=yes"
  assert_output_contains "cron_installed=yes"

  printf '%s\n' '# Changed' >> "$site_root/site/pages/index.md"
  run_cmd env \
    PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" \
    WEB_WIZARDRY_ROOT="$web_root" \
    WIZARDRY_DIR="$fake_wizardry" \
    CRON_STUB_FILE="$cron_file" \
    SITE_AUTOREBUILD_BUILD_LOG="$build_log" \
    sh "$ROOT_DIR/spells/web/site-autorebuild" run testsite
  assert_success
  assert_output_contains "enabled=yes"

  if ! grep -q '^testsite$' "$build_log"; then
    TEST_FAILURE_REASON="build spell was not invoked for testsite"
    rm -rf "$web_root" "$fake_wizardry" "$stub_dir"
    return 1
  fi

  run_cmd env \
    PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" \
    WEB_WIZARDRY_ROOT="$web_root" \
    WIZARDRY_DIR="$fake_wizardry" \
    CRON_STUB_FILE="$cron_file" \
    SITE_AUTOREBUILD_BUILD_LOG="$build_log" \
    sh "$ROOT_DIR/spells/web/site-autorebuild" disable testsite
  assert_success
  assert_output_contains "enabled=no"

  rm -rf "$web_root" "$fake_wizardry" "$stub_dir"
}

setup_managed_site_autorebuild_fixture() {
  managed_root=$(temp-dir site-autorebuild-managed)
  site_root="$managed_root/site-root"
  stub_dir=$(temp-dir site-autorebuild-managed-stub)
  fake_cron_root="$managed_root/fake-cron"
  build_log=$(temp-file site-autorebuild-managed-build-log)
  site_user=$(id -un 2>/dev/null || printf 'wizard')

  mkdir -p \
    "$site_root/releases/current/build" \
    "$site_root/.sitedata/site/pages" \
    "$site_root/.wizardry/spells/web" \
    "$site_root/.wizardry/spells/.imps/sys" \
    "$fake_cron_root"
  ln -s "releases/current" "$site_root/site"

  printf 'preserved from current release\n' \
    > "$site_root/releases/current/build/preserved.txt"
  printf 'updated from content root\n' \
    > "$site_root/.sitedata/site/pages/index.md"

  cat > "$site_root/.wizardry/spells/web/build" <<'EOS'
#!/bin/sh
set -eu
release_name=$1
release_dir=$WEB_WIZARDRY_ROOT/$release_name
printf '%s\n' "$release_name" >> "${SITE_AUTOREBUILD_BUILD_LOG:?}"
if [ "${SITE_AUTOREBUILD_BUILD_FAIL-0}" = "1" ]; then
  exit 1
fi
mkdir -p "$release_dir/build"
cp "$HOME/.sitedata/site/pages/index.md" "$release_dir/build/index.md"
printf '%s\n' "$release_name" > "$release_dir/build/release-name.txt"
EOS
  chmod +x "$site_root/.wizardry/spells/web/build"

  cat > "$site_root/.wizardry/spells/.imps/sys/env-clear" <<'EOS'
:
EOS

  cat > "$stub_dir/run_sudo_cmd" <<'EOS'
#!/bin/sh
set -eu
stub_dir=${SITE_AUTOREBUILD_STUB_DIR:?}
if [ "${1-}" = "command" ] && [ "${2-}" = "-v" ] && [ $# -eq 3 ]; then
  if PATH="$stub_dir:$PATH" command -v "$3" >/dev/null 2>&1; then
    exit 0
  fi
  exit 1
fi
PATH="$stub_dir:$PATH"
export PATH
exec "$@"
EOS

  cat > "$stub_dir/test" <<'EOS'
#!/bin/sh
set -eu
remap_arg() {
  case "$1" in
    /etc/cron.d/headquarters-content-rebuild-*)
      printf '%s/%s\n' "${SITE_AUTOREBUILD_FAKE_CRON_ROOT:?}" "${1##*/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}
quoted_args=''
for arg do
  mapped=$(remap_arg "$arg")
  quoted=$(printf '%s' "$mapped" | sed "s/'/'\\''/g")
  quoted_args="$quoted_args '$quoted'"
done
eval "set --$quoted_args"
if [ -x /bin/test ]; then
  exec /bin/test "$@"
fi
exec /usr/bin/test "$@"
EOS

  cat > "$stub_dir/grep" <<'EOS'
#!/bin/sh
set -eu
remap_arg() {
  case "$1" in
    /etc/cron.d/headquarters-content-rebuild-*)
      printf '%s/%s\n' "${SITE_AUTOREBUILD_FAKE_CRON_ROOT:?}" "${1##*/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}
quoted_args=''
for arg do
  mapped=$(remap_arg "$arg")
  quoted=$(printf '%s' "$mapped" | sed "s/'/'\\''/g")
  quoted_args="$quoted_args '$quoted'"
done
eval "set --$quoted_args"
if [ -x /usr/bin/grep ]; then
  exec /usr/bin/grep "$@"
fi
exec /bin/grep "$@"
EOS

  cat > "$stub_dir/rm" <<'EOS'
#!/bin/sh
set -eu
remap_arg() {
  case "$1" in
    /etc/cron.d/headquarters-content-rebuild-*)
      printf '%s/%s\n' "${SITE_AUTOREBUILD_FAKE_CRON_ROOT:?}" "${1##*/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}
quoted_args=''
for arg do
  mapped=$(remap_arg "$arg")
  quoted=$(printf '%s' "$mapped" | sed "s/'/'\\''/g")
  quoted_args="$quoted_args '$quoted'"
done
eval "set --$quoted_args"
if [ -x /bin/rm ]; then
  exec /bin/rm "$@"
fi
exec /usr/bin/rm "$@"
EOS

  cat > "$stub_dir/install" <<'EOS'
#!/bin/sh
set -eu
remap_arg() {
  case "$1" in
    /etc/cron.d/headquarters-content-rebuild-*)
      printf '%s/%s\n' "${SITE_AUTOREBUILD_FAKE_CRON_ROOT:?}" "${1##*/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}
quoted_args=''
while [ $# -gt 0 ]; do
  case "$1" in
    -o|-g)
      shift 2
      ;;
    *)
      mapped=$(remap_arg "$1")
      quoted=$(printf '%s' "$mapped" | sed "s/'/'\\''/g")
      quoted_args="$quoted_args '$quoted'"
      shift
      ;;
  esac
done
eval "set --$quoted_args"
if [ -x /usr/bin/install ]; then
  exec /usr/bin/install "$@"
fi
exec /bin/install "$@"
EOS

  cat > "$stub_dir/ln" <<'EOS'
#!/bin/sh
set -eu
site_root=${SITE_AUTOREBUILD_SITE_ROOT:?}
if [ "${1-}" = "-sfn" ] && [ $# -eq 3 ]; then
  source_path=$2
  link_path=$3
  case "$source_path" in
    "$site_root"/releases/*)
      case "$link_path" in
        "$site_root"/site)
          source_path=${source_path#"$site_root"/}
          set -- "$1" "$source_path" "$link_path"
          ;;
      esac
      ;;
  esac
fi
if [ -x /bin/ln ]; then
  exec /bin/ln "$@"
fi
exec /usr/bin/ln "$@"
EOS

  chmod +x \
    "$stub_dir/run_sudo_cmd" \
    "$stub_dir/test" \
    "$stub_dir/grep" \
    "$stub_dir/rm" \
    "$stub_dir/install" \
    "$stub_dir/ln"
}

run_managed_site_autorebuild() {
  run_cmd env \
    PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" \
    SITE_AUTOREBUILD_FAKE_CRON_ROOT="$fake_cron_root" \
    SITE_AUTOREBUILD_SITE_ROOT="$site_root" \
    SITE_AUTOREBUILD_STUB_DIR="$stub_dir" \
    SITE_AUTOREBUILD_BUILD_LOG="$build_log" \
    WIZARDRY_DIR="$site_root/.wizardry" \
    sh "$ROOT_DIR/spells/web/site-autorebuild" "$@"
}

test_site_autorebuild_managed_enable_disable() {
  skip-if-compiled || return $?
  setup_managed_site_autorebuild_fixture

  run_managed_site_autorebuild enable --managed "$site_user" --site-root "$site_root"
  assert_success || return 1
  assert_output_contains "enabled=yes" || return 1
  assert_output_contains "cron_installed=yes" || return 1
  assert_output_contains "script_installed=yes" || return 1

  runtime_spell="$site_root/.wizardry/spells/web/site-autorebuild"
  managed_cron_file="$fake_cron_root/headquarters-content-rebuild-$site_user"

  if [ ! -x "$runtime_spell" ]; then
    TEST_FAILURE_REASON="managed runtime spell was not installed"
    return 1
  fi

  if [ ! -f "$managed_cron_file" ]; then
    TEST_FAILURE_REASON="managed cron file was not installed"
    return 1
  fi

  if ! grep -q 'watch-daemon --managed .* \.' "$managed_cron_file"; then
    TEST_FAILURE_REASON="managed cron file does not start watcher in managed mode"
    return 1
  fi

  run_managed_site_autorebuild disable --managed "$site_user" --site-root "$site_root"
  assert_success || return 1
  assert_output_contains "enabled=no" || return 1
  assert_output_contains "cron_installed=no" || return 1

  if [ -f "$managed_cron_file" ]; then
    TEST_FAILURE_REASON="managed cron file was not removed"
    return 1
  fi
}

test_site_autorebuild_managed_run_stages_release() {
  skip-if-compiled || return $?
  setup_managed_site_autorebuild_fixture

  previous_link=$(readlink "$site_root/site")

  run_managed_site_autorebuild run --managed "$site_user" --site-root "$site_root"
  assert_success || return 1
  assert_output_contains "enabled=no" || return 1

  current_link=$(readlink "$site_root/site")
  if [ -z "$current_link" ]; then
    TEST_FAILURE_REASON="managed current site link was not updated"
    return 1
  fi

  if [ "$current_link" = "$previous_link" ]; then
    TEST_FAILURE_REASON="managed run did not stage a new release"
    return 1
  fi

  case "$current_link" in
    releases/*) : ;;
    *)
      TEST_FAILURE_REASON="managed current site link should stay relative to releases/"
      return 1
      ;;
  esac

  release_name=${current_link##*/}
  if ! grep -q "^$release_name$" "$build_log"; then
    TEST_FAILURE_REASON="managed build did not record the staged release name"
    return 1
  fi

  staged_release="$site_root/$current_link"
  if [ ! -f "$staged_release/build/preserved.txt" ]; then
    TEST_FAILURE_REASON="managed staged release did not preserve existing build artifacts"
    return 1
  fi

  if ! grep -q 'updated from content root' "$staged_release/build/index.md"; then
    TEST_FAILURE_REASON="managed build did not rebuild from content root"
    return 1
  fi

  if ! grep -q "^$release_name$" "$staged_release/build/release-name.txt"; then
    TEST_FAILURE_REASON="managed build did not record the active release name"
    return 1
  fi
}

test_site_autorebuild_managed_run_cleans_failed_stage() {
  skip-if-compiled || return $?
  setup_managed_site_autorebuild_fixture

  previous_link=$(readlink "$site_root/site")

  run_cmd env \
    PATH="$stub_dir:/usr/bin:/bin:/usr/sbin:/sbin" \
    SITE_AUTOREBUILD_FAKE_CRON_ROOT="$fake_cron_root" \
    SITE_AUTOREBUILD_SITE_ROOT="$site_root" \
    SITE_AUTOREBUILD_STUB_DIR="$stub_dir" \
    SITE_AUTOREBUILD_BUILD_LOG="$build_log" \
    SITE_AUTOREBUILD_BUILD_FAIL=1 \
    WIZARDRY_DIR="$site_root/.wizardry" \
    sh "$ROOT_DIR/spells/web/site-autorebuild" run --managed "$site_user" --site-root "$site_root"
  assert_failure || return 1

  current_link=$(readlink "$site_root/site")
  if [ "$current_link" != "$previous_link" ]; then
    TEST_FAILURE_REASON="managed failure should not swap the current release link"
    return 1
  fi

  release_count=$(find "$site_root/releases" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  if [ "$release_count" != 1 ]; then
    TEST_FAILURE_REASON="managed failure should clean up staged releases"
    return 1
  fi
}

run_test_case "site-autorebuild --help" test_site_autorebuild_help
run_test_case "site-autorebuild validates target" test_site_autorebuild_requires_target
run_test_case "site-autorebuild local enable/run/disable" \
  test_site_autorebuild_local_enable_run_disable
run_test_case "site-autorebuild managed enable/disable installs runtime and cron" \
  test_site_autorebuild_managed_enable_disable
run_test_case "site-autorebuild managed run stages a new release" \
  test_site_autorebuild_managed_run_stages_release
run_test_case "site-autorebuild managed run cleans failed staged releases" \
  test_site_autorebuild_managed_run_cleans_failed_stage

finish_tests
