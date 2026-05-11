#!/usr/bin/env bash
# ASC: zwei Apple-Watch-Screenshots (FuelNowWatch) mit Demo-Snapshot (JSON), ohne iPhone-Pflicht.
#
# Standard: Apple Watch Series 11 (46mm) → 416×496 (APP_WATCH_SERIES_10).
# Ultra: WATCH_SIMULATOR_NAME="Apple Watch Ultra 3 (49mm)" und ASC_WATCH_DEVICE_TYPE=APP_WATCH_ULTRA.
#
# Ausgabe: screenshots/asc-watch/raw/
# Fixtures: scripts/fixtures/asc-watch-store-01.json / 02.json (WatchWidgetSnapshot)
#
# Voraussetzungen: Xcode, Simulator; optional asc für validate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=watch-simulator-env.sh
source "${ROOT}/scripts/watch-simulator-env.sh"

SCHEME="${SCHEME:-FuelNowWatch}"
WATCH_BUNDLE_ID="${WATCH_BUNDLE_ID:-com.vibecoding.fuelnow.watchkitapp}"
DERIVED="${DERIVED_DATA_PATH_WATCH:-$ROOT/.derived-data-watch}"
OUT="${ASC_WATCH_SCREENSHOT_DIR:-$ROOT/screenshots/asc-watch/raw}"
ASC_WATCH_DEVICE_TYPE="${ASC_WATCH_DEVICE_TYPE:-APP_WATCH_SERIES_10}"

FIX1="${ROOT}/scripts/fixtures/asc-watch-store-01.json"
FIX2="${ROOT}/scripts/fixtures/asc-watch-store-02.json"

mkdir -p "${DERIVED}" "${OUT}"
LOCK_DIR="${DERIVED}/.build-lock-dir"
while ! mkdir "${LOCK_DIR}" 2>/dev/null; do sleep 0.25; done
trap 'rmdir "${LOCK_DIR}" 2>/dev/null || true' EXIT

WUDID="$(fuelnow_resolve_watch_simulator_udid)"
if [[ -z "${WUDID}" ]]; then
  echo "FuelNow: Kein Watch-Simulator „${WATCH_SIMULATOR_NAME:-Apple Watch Series 11 (46mm)}“." >&2
  exit 1
fi

if [[ ! -f "${FIX1}" || ! -f "${FIX2}" ]]; then
  echo "FuelNow: Fixtures fehlen unter scripts/fixtures/." >&2
  exit 1
fi

if ! xcrun simctl list devices booted 2>/dev/null | grep -q "${WUDID}"; then
  xcrun simctl boot "${WUDID}" 2>/dev/null || true
fi
open -a Simulator 2>/dev/null || true

echo "FuelNow: Build ${SCHEME} → Watch ${WATCH_SIMULATOR_NAME:-Apple Watch Series 11 (46mm)} (${WUDID})"

xcodebuild \
  -scheme "${SCHEME}" \
  -destination "platform=watchOS Simulator,id=${WUDID}" \
  -derivedDataPath "${DERIVED}" \
  -quiet \
  build

WATCH_APP="$(find "${DERIVED}/Build/Products" -path '*watchsimulator/FuelNowWatch.app' -type d | head -1)"
if [[ -z "${WATCH_APP}" || ! -d "${WATCH_APP}" ]]; then
  echo "FuelNow: FuelNowWatch.app nicht gefunden unter ${DERIVED}." >&2
  exit 1
fi

xcrun simctl install "${WUDID}" "${WATCH_APP}"

fuelnow_watch_write_snapshot_cache() {
  local fixture="$1"
  local base
  base="$(xcrun simctl get_app_container "${WUDID}" "${WATCH_BUNDLE_ID}" data 2>/dev/null)" || return 1
  mkdir -p "${base}/Library/Application Support"
  cp "${fixture}" "${base}/Library/Application Support/watch-snapshot-v1.json"
}

fuelnow_watch_capture_round() {
  local fixture="$1" outpng="$2"
  fuelnow_watch_write_snapshot_cache "${fixture}"
  xcrun simctl terminate "${WUDID}" "${WATCH_BUNDLE_ID}" 2>/dev/null || true
  xcrun simctl launch "${WUDID}" "${WATCH_BUNDLE_ID}" >/dev/null
  sleep 2.5
  echo "FuelNow: Screenshot → ${outpng}"
  xcrun simctl io "${WUDID}" screenshot "${outpng}"
}

fuelnow_watch_capture_round "${FIX1}" "${OUT}/asc-watch-01-list.png"
fuelnow_watch_capture_round "${FIX2}" "${OUT}/asc-watch-02-list.png"

if command -v sips >/dev/null 2>&1; then
  echo "FuelNow: Bildmaße:"
  sips -g pixelWidth -g pixelHeight "${OUT}/asc-watch-01-list.png" 2>/dev/null | grep pixel || true
  sips -g pixelWidth -g pixelHeight "${OUT}/asc-watch-02-list.png" 2>/dev/null | grep pixel || true
fi

if command -v asc >/dev/null 2>&1; then
  echo "FuelNow: asc validate (${ASC_WATCH_DEVICE_TYPE}) …"
  asc screenshots validate --path "${OUT}" --device-type "${ASC_WATCH_DEVICE_TYPE}" --output table || true
fi

echo "FuelNow: Watch-Screenshots fertig unter ${OUT}. Upload: ASC_UPLOAD_WATCH=1 ./scripts/upload-asc-screenshots.sh"
