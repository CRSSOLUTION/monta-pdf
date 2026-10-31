#!/usr/bin/env bash
# Prints the UDID of an available iPhone simulator on the newest installed iOS runtime.
set -euo pipefail
xcrun simctl list devices available -j | jq -r '
  [.devices | to_entries | sort_by(.key) | reverse | .[]
   | select(.key | test("iOS"))
   | .value[] | select(.name | startswith("iPhone"))][0].udid'
