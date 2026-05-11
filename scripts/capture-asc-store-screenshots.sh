#!/usr/bin/env bash
# ASC/App-Store: PNGs vom Launch-Overlay (Logo) und von der Karte mit Tankstellen.
# Voraussetzungen: Xcode, Simulator, AXe (`brew install axe`), optional `asc` für `validate`.
#
# Ausgabe: ./screenshots/asc-store/raw/ (gitignored empfohlen; siehe unten)
#
# Umgebung:
#   SIMULATOR_NAME — Standard: iPhone 17 Pro Max (Roh-Screenshot; s. ASC_SCREENSHOT_DEVICE_TYPE)
#   ASC_SCREENSHOT_DEVICE_TYPE — Standard: APP_IPHONE_65 (ASC „iPhone 6,5"“, 1284×2778 nach sips)
#     APP_IPHONE_67 = keine Skalierung (Simulator liefert i. d. R. 1320×2868)
#   ASC_SCREENSHOT_SKIP_RESIZE=1 — kein sips (z. B. eigener Simulator schon 1242×2688)
#   SCHEME, DERIVED_DATA_PATH, BUNDLE_ID — wie build-and-run-simulator.sh
#
# Beispiel:
#   ./scripts/capture-asc-store-screenshots.sh
# Apple Watch: ./scripts/capture-asc-watch-screenshots.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=simulator-env.sh
source "${ROOT}/scripts/simulator-env.sh"

ASC_SCREENSHOT_DEVICE_TYPE="${ASC_SCREENSHOT_DEVICE_TYPE:-APP_IPHONE_65}"

SCHEME="${SCHEME:-FuelNow}"
SIMULATOR_NAME="${SIMULATOR_NAME:-iPhone 17 Pro Max}"
BUNDLE_ID="${BUNDLE_ID:-com.vibecoding.fuelnow}"
DERIVED="${DERIVED_DATA_PATH:-$ROOT/.derived-data-ios}"
OUT="${ASC_STORE_SCREENSHOT_DIR:-$ROOT/screenshots/asc-store/raw}"

fuelnow_asc_normalize_pngs() {
  [[ "${ASC_SCREENSHOT_SKIP_RESIZE:-0}" == "1" ]] && return 0
  if ! command -v sips >/dev/null 2>&1; then
    echo "FuelNow: sips nicht gefunden — Skalierung für ${ASC_SCREENSHOT_DEVICE_TYPE} übersprungen." >&2
    return 0
  fi
  local f tmp
  for f in "$@"; do
    case "${ASC_SCREENSHOT_DEVICE_TYPE}" in
      APP_IPHONE_65)
        w="$(sips -g pixelWidth "${f}" 2>/dev/null | awk '/pixelWidth:/{print $2}')"
        h="$(sips -g pixelHeight "${f}" 2>/dev/null | awk '/pixelHeight:/{print $2}')"
        if [[ "${w}" == "1284" && "${h}" == "2778" ]] || [[ "${w}" == "1242" && "${h}" == "2688" ]]; then
          continue
        fi
        tmp="${f}.asc-resize.$$.$RANDOM.png"
        if sips -z 2778 1284 "${f}" --out "${tmp}" >/dev/null 2>&1; then
          mv "${tmp}" "${f}"
        else
          rm -f "${tmp}"
          echo "FuelNow: sips-Resize nach 1284×2778 fehlgeschlagen: ${f}" >&2
          return 1
        fi
        ;;
      APP_IPHONE_67) ;;
      *)
        echo "FuelNow: Unbekannter ASC_SCREENSHOT_DEVICE_TYPE=${ASC_SCREENSHOT_DEVICE_TYPE} — keine Skalierung." >&2
        ;;
    esac
  done
}

if ! command -v axe >/dev/null 2>&1; then
  echo "FuelNow: AXe fehlt (brew tap cameroncooke/axe && brew install axe)." >&2
  exit 1
fi

mkdir -p "$DERIVED" "$OUT"
LOCK_DIR="$DERIVED/.build-run-lock-dir"
while ! mkdir "$LOCK_DIR" 2>/dev/null; do sleep 0.25; done
trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT

UDID="$(fuelnow_resolve_simulator_udid)"
if [[ -z "${UDID}" ]]; then
  echo "FuelNow: Kein Simulator „${SIMULATOR_NAME}“ gefunden." >&2
  exit 1
fi

if ! xcrun simctl list devices booted 2>/dev/null | grep -q "${UDID}"; then
  xcrun simctl boot "${UDID}" 2>/dev/null || true
fi
open -a Simulator 2>/dev/null || true

echo "FuelNow: Build → ${SIMULATOR_NAME} (${UDID}), Ausgabe ${OUT}"

xcodebuild \
  -scheme "${SCHEME}" \
  -destination "platform=iOS Simulator,id=${UDID}" \
  -derivedDataPath "${DERIVED}" \
  -quiet \
  build

APP="${DERIVED}/Build/Products/Debug-iphonesimulator/FuelNow.app"
if [[ ! -d "${APP}" ]]; then
  echo "FuelNow: Build-Produkt fehlt: ${APP}" >&2
  exit 1
fi

xcrun simctl install "${UDID}" "${APP}"

# Direkt zur Karte (ohne Onboarding); Bool wie bei manueller Prüfung mit `defaults read`.
xcrun simctl spawn "${UDID}" defaults write "${BUNDLE_ID}" tr.hasCompletedOnboarding -bool true

TANKERKOENIG_KEY_FILE="${TANKERKOENIG_KEY_FILE:-${HOME}/.fuelnow/tankerkoenig-api-key}"
if [[ -f "${TANKERKOENIG_KEY_FILE}" ]]; then
  TANKERKOENIG_KEY="$(tr -d '[:space:]' < "${TANKERKOENIG_KEY_FILE}")"
  if [[ -n "${TANKERKOENIG_KEY}" ]]; then
    export SIMCTL_CHILD_TANKERKOENIG_API_KEY="${TANKERKOENIG_KEY}"
  fi
fi
if [[ "${FUELNOW_USE_MOCK_STATIONS:-0}" == "1" ]]; then
  export SIMCTL_CHILD_FUELNOW_USE_MOCK_STATIONS=1
fi

xcrun simctl terminate "${UDID}" "${BUNDLE_ID}" 2>/dev/null || true
xcrun simctl launch "${UDID}" "${BUNDLE_ID}"

# Launch-Branding (Logo + Karten-Hintergrund): im Simulator typisch sichtbar um ~1,0 s nach `simctl launch`
# (davor oft kurzes Weiß/System-Launch).
sleep 1.02
LAUNCH_PNG="${OUT}/asc-01-launch-overlay.png"
echo "FuelNow: Screenshot Launch → ${LAUNCH_PNG}"
axe screenshot --udid "${UDID}" --output "${LAUNCH_PNG}"

# Karte + Tankstellen: Standort/WhatsNew schließen, dann Pins laden lassen.
sleep 6
axe batch --file "${ROOT}/scripts/axe/fuelnow-asc-whatsnew-dismiss.steps" --udid "${UDID}" --continue-on-error 2>/dev/null || true
echo "FuelNow: Standort/WhatsNew-Taps ausgeführt (fehlende Dialoge sind unkritisch)."
sleep 10

MAP_PNG="${OUT}/asc-02-map-stations.png"
echo "FuelNow: Screenshot Karte → ${MAP_PNG}"
axe screenshot --udid "${UDID}" --output "${MAP_PNG}"

echo "FuelNow: ASC-Ziel ${ASC_SCREENSHOT_DEVICE_TYPE} (sips-Normalisierung, optional) …"
fuelnow_asc_normalize_pngs "${LAUNCH_PNG}" "${MAP_PNG}"
if command -v sips >/dev/null 2>&1; then
  echo "FuelNow: Bildmaße:"
  sips -g pixelWidth -g pixelHeight "${LAUNCH_PNG}" 2>/dev/null | grep pixel || true
  sips -g pixelWidth -g pixelHeight "${MAP_PNG}" 2>/dev/null | grep pixel || true
fi

if command -v asc >/dev/null 2>&1; then
  echo "FuelNow: asc validate (${ASC_SCREENSHOT_DEVICE_TYPE}) …"
  asc screenshots validate --path "${OUT}" --device-type "${ASC_SCREENSHOT_DEVICE_TYPE}" --output table || true
fi

echo "FuelNow: Fertig. Rahmen: ./scripts/frame-asc-store-screenshots.sh · Upload ASC: ./scripts/upload-asc-screenshots.sh (nicht automatisch)"
