#!/bin/sh
# Behavioral coverage for openstreetmaps-server-notes.

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/.arcana/openstreetmaps/openstreetmaps-server-notes"

test_openstreetmaps_server_notes_help() {
  run_spell "$target" --help
  assert_success || return 1
  assert_output_contains "Usage: openstreetmaps-server-notes" || return 1
}

test_openstreetmaps_server_notes_describe_client_assets() {
  run_spell "$target"
  assert_success || return 1
  assert_output_contains "Leaflet CSS" || return 1
}

test_openstreetmaps_server_notes_list_missing_server_components() {
  run_spell "$target"
  assert_success || return 1
  assert_output_contains "Tile rendering server" || return 1
}

run_test_case "openstreetmaps-server-notes shows help" test_openstreetmaps_server_notes_help
run_test_case "openstreetmaps-server-notes describes client assets" \
  test_openstreetmaps_server_notes_describe_client_assets
run_test_case "openstreetmaps-server-notes lists missing server components" \
  test_openstreetmaps_server_notes_list_missing_server_components

finish_tests
