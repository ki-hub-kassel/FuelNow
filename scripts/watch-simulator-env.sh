# shellcheck shell=bash
# Shared helpers for Watch-Simulator-Skripte (watchOS).

fuelnow_resolve_watch_simulator_udid() {
  local sim_name="${WATCH_SIMULATOR_NAME:-Apple Watch Series 11 (46mm)}"
  xcrun simctl list devices available 2>/dev/null \
    | grep "${sim_name} (" \
    | head -1 \
    | grep -oE '[A-F0-9]{8}-([A-F0-9]{4}-){3}[A-F0-9]{12}' \
    | head -1
}
