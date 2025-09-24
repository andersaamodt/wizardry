#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test_framework.sh"

setup_home() {
  tmp_home=$(make_temp_dir)
  export HOME="$tmp_home"
  mkdir -p "$HOME"
  cat <<'RC' >"$HOME/.bashrc"
# test bashrc
RC
}

setup_home

target_dir=$(make_temp_dir)
missing_dir="$HOME/does-not-exist"
default_dir=$(make_temp_dir)

# No arguments should complain about usage.
run_script "spells/path-wizard"
expect_exit_code 1
expect_in_output "requires one or two arguments" "$RUN_STDOUT"

# Invalid actions should be rejected.
run_script "spells/path-wizard" "list"
expect_exit_code 1
expect_in_output "The first argument must be 'add' or 'remove'." "$RUN_STDOUT"

# Non-existent directories must not be added.
run_script "spells/path-wizard" "add" "$missing_dir"
expect_exit_code 1
expect_in_output "The directory does not exist." "$RUN_STDOUT"

# Missing ~/.bashrc should surface an explicit error.
mv "$HOME/.bashrc" "$HOME/.bashrc.bak"
run_script "spells/path-wizard" "add" "$target_dir"
expect_exit_code 1
expect_in_output "The '.bashrc' file does not exist" "$RUN_STDOUT"
mv "$HOME/.bashrc.bak" "$HOME/.bashrc"

# Successfully adding a directory prepends an entry.
run_script "spells/path-wizard" "add" "$target_dir"
expect_exit_code 0
entry="export PATH=$target_dir:\$PATH"
if ! grep -Fqx "$entry" "$HOME/.bashrc"; then
  record_failure "path-wizard should add $target_dir to .bashrc"
fi
expect_in_output "The directory has been added to your PATH." "$RUN_STDOUT"
expect_in_output "source ~/.bashrc" "$RUN_STDOUT" "path-wizard should remind users to reload"

# Adding again should report that the directory already exists.
run_script "spells/path-wizard" "add" "$target_dir"
expect_exit_code 0
expect_in_output "The directory is already in your PATH." "$RUN_STDOUT"

# Removing should delete the entry and print the right reminder.
run_script "spells/path-wizard" "remove" "$target_dir"
expect_exit_code 0
if grep -Fqx "$entry" "$HOME/.bashrc"; then
  record_failure "path-wizard should remove $target_dir from .bashrc"
fi
expect_in_output "The directory has been removed from your PATH." "$RUN_STDOUT"
expect_in_output "open a new terminal" "$RUN_STDOUT"

# Removing a directory that is not listed should fail.
run_script "spells/path-wizard" "remove" "$target_dir"
expect_exit_code 1
expect_in_output "The directory is not in your PATH." "$RUN_STDOUT"

# Adding without a directory should default to the current working directory.
old_pwd=$(pwd)
cd "$default_dir"
run_script "spells/path-wizard" "add"
cd "$old_pwd"
expect_exit_code 0
default_entry="export PATH=$default_dir:\$PATH"
if ! grep -Fqx "$default_entry" "$HOME/.bashrc"; then
  record_failure "path-wizard should add the current directory when none is provided"
fi

# Removing the default directory entry should succeed.
run_script "spells/path-wizard" "remove" "$default_dir"
expect_exit_code 0

# Adding using tilde expansion should resolve to $HOME.
magic_dir="$HOME/magic"
mkdir -p "$magic_dir"
run_script "spells/path-wizard" "add" "~/magic"
expect_exit_code 0
tilde_entry="export PATH=$magic_dir:\$PATH"
if ! grep -Fqx "$tilde_entry" "$HOME/.bashrc"; then
  record_failure "path-wizard should expand tildes"
fi
run_script "spells/path-wizard" "remove" "$magic_dir"
expect_exit_code 0

# Using '.' should resolve to the absolute path of the current directory.
dot_dir=$(make_temp_dir)
old_pwd=$(pwd)
cd "$dot_dir"
run_script "spells/path-wizard" "add" "."
cd "$old_pwd"
expect_exit_code 0
dot_entry="export PATH=$dot_dir:\$PATH"
if ! grep -Fqx "$dot_entry" "$HOME/.bashrc"; then
  record_failure "path-wizard should resolve '.' to an absolute path"
fi
run_script "spells/path-wizard" "remove" "$dot_dir"
expect_exit_code 0

# Relative directories should be converted to absolute paths.
relative_dir="$HOME/relative"
mkdir -p "$relative_dir"
old_pwd=$(pwd)
cd "$HOME"
run_script "spells/path-wizard" "add" "relative"
cd "$old_pwd"
expect_exit_code 0
relative_entry="export PATH=$relative_dir:\$PATH"
if ! grep -Fqx "$relative_entry" "$HOME/.bashrc"; then
  record_failure "path-wizard should resolve relative directories"
fi
run_script "spells/path-wizard" "remove" "$relative_dir"
expect_exit_code 0

assert_all_expectations_met
