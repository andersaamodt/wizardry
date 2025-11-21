#!/usr/bin/env bash
# Shared loader for cantrips Bats tests
# shellcheck disable=SC1090
source "$(CDPATH= cd -- "$(dirname "$BATS_TEST_FILENAME")/.." && pwd -P)/test_helper/load.bash"
