#!/usr/bin/env bash
# FuelNow — erweiterter AXe-Lauf (Simulator): Onboarding/WhatsNew (optional), Karten-Flow inkl. Apple Maps,
# Offline-Splash (toter Proxy), Hinweise zu CarPlay und fehlendem In-App-„Listen“-Tab.
#
# Standard (ein Build, bestehende App-Daten): wie funktionaler Smoke + Maps + Offline + Hinweise.
#   ./scripts/run-fuelnow-extended-axe-smoke.sh
#
# Onboarding + WhatsNew erneut erleben (löscht UserDefaults-Plist der App im Simulator):
#   FUELNOW_AXE_RESET_APP_DEFAULTS=1 FUELNOW_BUILD_FIRST=1 ./scripts/run-fuelnow-extended-axe-smoke.sh
#
# CarPlay: keine AXe-Steuerung der CarPlay-Oberfläche vom iPhone-Simulator aus — siehe fuelnow_print_carplay_hint.
# „Listen“-Tab: im iPhone-Haupt-UI gibt es nur die Karte (kein Map/List-Segment); Liste existiert u. a. in CarPlay (CPListTemplate).
#
# Install: brew tap cameroncooke/axe && brew install axe
set -euo pipefail

FUELNOW_EXTENDED_DID_BUILD=0
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=simulator-env.sh
source "${ROOT}/scripts/simulator-env.sh"

BUNDLE_ID="${BUNDLE_ID:-com.vibecoding.fuelnow}"

fuelnow_app_prefs_plist() {
  local container
  container="$(xcrun simctl get_app_container "${UDID}" "${BUNDLE_ID}" data 2>/dev/null || true)"
  if [[ -z "${container}" ]]; then
    return 1
  fi
  echo "${container}/Library/Preferences/${BUNDLE_ID}.plist"
}

fuelnow_reset_app_defaults() {
  echo "FuelNow: App beenden …"
  xcrun simctl terminate "${UDID}" "${BUNDLE_ID}" 2>/dev/null || true
  local plist
  if plist="$(fuelnow_app_prefs_plist 2>/dev/null)" && [[ -f "${plist}" ]]; then
    rm -f "${plist}"
    echo "FuelNow: UserDefaults entfernt → ${plist}"
  else
    echo "FuelNow: Keine Preferences-Datei (erster Lauf?) — Reset übersprungen."
  fi
}

fuelnow_print_carplay_hint() {
  echo ""
  echo "FuelNow [CarPlay]: AXe bedient hier nur die iPhone-Oberfläche. CarPlay-UI testen:"
  echo "  • Xcode → I/O → External Displays → CarPlay (bzw. Window-Menü je nach Xcode-Version)"
  echo "  • Doku: ${ROOT}/docs/CARPLAY.md"
  echo "  • Capability prüfen: FuelNow/Support/FuelNowFeatureFlags.swift → carPlayCapabilityMode"
  echo ""
}

fuelnow_print_list_tab_hint() {
  echo "FuelNow [Liste]: Kein separater Karten/Liste-Tab im iPhone-Target — Stationsliste ist u. a. die CarPlay-Root-Liste (CPListTemplate), nicht die Simulator-AXe auf der Karten-Scene."
  echo ""
}

fuelnow_phase_offline_splash() {
  echo "FuelNow: Phase Offline-Splash (toter Proxy-URL, erwartet Konnektivitäts-Fetch-Fehler) …"
  xcrun simctl terminate "${UDID}" com.apple.Maps 2>/dev/null || true
  xcrun simctl terminate "${UDID}" "${BUNDLE_ID}" 2>/dev/null || true
  xcrun simctl privacy "${UDID}" grant location "${BUNDLE_ID}" 2>/dev/null || true
  unset SIMCTL_CHILD_TANKERKOENIG_PROXY_BASE_URL || true
  export SIMCTL_CHILD_TANKERKOENIG_PROXY_BASE_URL="http://127.0.0.1:9"
  xcrun simctl launch "${UDID}" "${BUNDLE_ID}" >/dev/null
  unset SIMCTL_CHILD_TANKERKOENIG_PROXY_BASE_URL || true
  sleep 5
  # Ohne GPS liefert `LocateMeButton` keinen Tap (disabled) — Simulator-Standort setzen, dann Abruf auslösen.
  xcrun simctl location "${UDID}" set 52.520008,13.404954 2>/dev/null || true
  sleep 1
  # Ohne Fetch bleibt lastFetchSuggestsOffline false — Standort-Zentrieren triggert typischerweise einen Abruf.
  axe tap --label "Karte auf Standort zentrieren" --wait-timeout 25 --udid "${UDID}" 2>/dev/null || true
  sleep "${FUELNOW_AXE_OFFLINE_WAIT_SECONDS:-12}"
  local ax_json
  ax_json="$(axe describe-ui --udid "${UDID}" 2>&1)" || return 1
  if printf '%s' "${ax_json}" | python3 "${ROOT}/scripts/axe/assert_ax_contains.py" "FuelNow ist offline" 2>/dev/null; then
    :
  elif printf '%s' "${ax_json}" | python3 "${ROOT}/scripts/axe/assert_ax_contains.py" "FuelNow is offline" 2>/dev/null; then
    :
  else
    echo "FuelNow: Offline-AX-Text nicht gefunden (weder DE- noch EN-Label im Baum)." >&2
    return 1
  fi
  echo "FuelNow: Offline-Splash im Accessibility-Baum erkannt."
  xcrun simctl terminate "${UDID}" "${BUNDLE_ID}" 2>/dev/null || true
  xcrun simctl launch "${UDID}" "${BUNDLE_ID}" >/dev/null
  sleep 3
  echo "FuelNow: App mit Standard-Netz/Proxy neu gestartet (ohne SIMCTL_CHILD-Override)."
}

if ! command -v axe >/dev/null 2>&1; then
  echo "FuelNow: AXe CLI fehlt. Install: brew tap cameroncooke/axe && brew install axe" >&2
  exit 1
fi

UDID="$(fuelnow_resolve_simulator_udid)"
if [[ -z "${UDID}" ]]; then
  echo "FuelNow: Kein Simulator „${SIMULATOR_NAME:-iPhone 17}“ gefunden." >&2
  exit 1
fi

if [[ "${FUELNOW_AXE_RESET_APP_DEFAULTS:-0}" == "1" ]]; then
  fuelnow_reset_app_defaults
  echo "FuelNow: Standort für Bundle erlauben (ohne System-Popup beim Onboarding) …"
  xcrun simctl privacy "${UDID}" grant location "${BUNDLE_ID}" 2>/dev/null || echo "FuelNow: Hinweis: simctl privacy grant location fehlgeschlagen (Xcode-Version?)." >&2
  export FUELNOW_BUILD_FIRST="${FUELNOW_BUILD_FIRST:-1}"
  export AXE_LAUNCH_WAIT_SECONDS="${AXE_LAUNCH_WAIT_SECONDS:-12}"
fi

if [[ "${FUELNOW_BUILD_FIRST:-0}" == "1" ]]; then
  # Nach frischem Install sind Live-Fetches + MapKit-AX oft verzögert; Mock liefert stabile Pins für AXe (abschaltbar).
  if [[ "${FUELNOW_AXE_MOCK_STATIONS_ON_BUILD:-1}" == "1" ]]; then
    export FUELNOW_USE_MOCK_STATIONS=1
    echo "FuelNow: FUELNOW_USE_MOCK_STATIONS=1 für diesen Build (AXe-Stabilität). Live: FUELNOW_AXE_MOCK_STATIONS_ON_BUILD=0 setzen."
  fi
  "${ROOT}/scripts/build-and-run-simulator.sh"
  unset FUELNOW_USE_MOCK_STATIONS || true
  FUELNOW_EXTENDED_DID_BUILD=1
  echo "FuelNow: Warte ${AXE_LAUNCH_WAIT_SECONDS:-8}s auf UI …"
  sleep "${AXE_LAUNCH_WAIT_SECONDS:-8}"
fi

if [[ "${FUELNOW_AXE_RESET_APP_DEFAULTS:-0}" == "1" ]]; then
  echo "FuelNow: axe batch (Onboarding) …"
  axe batch --file "${ROOT}/scripts/axe/fuelnow-onboarding.steps" --udid "${UDID}"
  echo "FuelNow: optional WhatsNew „Weiter“ (scheitert schmerzfrei, wenn Sheet nicht erscheint) …"
  axe tap --label "Weiter" --wait-timeout 10 --udid "${UDID}" 2>/dev/null || true
  sleep 2
  xcrun simctl location "${UDID}" set 52.520008,13.404954 2>/dev/null || true
  export FUELNOW_AXE_POST_PRELUDE_STATION_WAIT_SECONDS="${FUELNOW_AXE_POST_PRELUDE_STATION_WAIT_SECONDS:-28}"
fi

fuelnow_print_list_tab_hint
fuelnow_print_carplay_hint

export FUELNOW_AXE_INCLUDE_MAPS_NAV=1
export FUELNOW_BUILD_FIRST=0
export FUELNOW_AXE_ASSUME_FUELNOW_FOREGROUND="${FUELNOW_EXTENDED_DID_BUILD}"
"${ROOT}/scripts/run-fuelnow-functional-smoke.sh" "$@"

if [[ "${FUELNOW_AXE_SKIP_OFFLINE:-0}" != "1" ]]; then
  fuelnow_phase_offline_splash || exit 1
fi

echo "FuelNow: Erweiterter AXe-Lauf abgeschlossen."
