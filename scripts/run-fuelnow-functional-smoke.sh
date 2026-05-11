#!/usr/bin/env bash
# FuelNow — AXe-Funktionstest: Karte, Einstellungen, Standort zentrieren, erster Karten-Pin, Detail schließen.
# Voraussetzung: Simulator booted, FuelNow auf der Karte (z. B. nach ./scripts/build-and-run-simulator.sh).
# Optional: FUELNOW_BUILD_FIRST=1 baut/startet vorher wie build-run-and-axe (ohne zweiten AXe-Lauf).
# Optional: FUELNOW_AXE_INCLUDE_MAPS_NAV=1 — im Detail „Navigation in Apple Maps“, dann FuelNow wieder in den Vordergrund (Sheet weg).
# Optional: FUELNOW_AXE_ASSUME_FUELNOW_FOREGROUND=1 — kein simctl-Relaunch vor AXe (setzt z. B. run-fuelnow-extended-axe-smoke nach Build).
#
# Install: brew tap cameroncooke/axe && brew install axe
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
# shellcheck source=simulator-env.sh
source "${ROOT}/scripts/simulator-env.sh"

if ! command -v axe >/dev/null 2>&1; then
  echo "FuelNow: AXe CLI fehlt. Install: brew tap cameroncooke/axe && brew install axe" >&2
  exit 1
fi

if [[ "${FUELNOW_BUILD_FIRST:-0}" == "1" ]]; then
  "${ROOT}/scripts/build-and-run-simulator.sh"
  echo "FuelNow: Warte ${AXE_LAUNCH_WAIT_SECONDS:-8}s auf UI …"
  sleep "${AXE_LAUNCH_WAIT_SECONDS:-8}"
fi

UDID="$(fuelnow_resolve_simulator_udid)"
if [[ -z "${UDID}" ]]; then
  echo "FuelNow: Kein Simulator „${SIMULATOR_NAME:-iPhone 17}“ gefunden." >&2
  exit 1
fi

# Zuerst Simulator-GPS, damit CoreLocation vor dem Prelude Updates sieht (besonders nach Build).
if [[ "${FUELNOW_AXE_SKIP_SIM_LOCATION:-0}" != "1" ]]; then
  xcrun simctl location "${UDID}" set 52.520008,13.404954 2>/dev/null || true
  sleep 1
fi

# Nach „Navigation in Apple Maps“ bleibt die Karten-App oft im Vordergrund — AXe trifft sonst nicht FuelNow.
xcrun simctl terminate "${UDID}" com.apple.Maps 2>/dev/null || true
if [[ "${FUELNOW_AXE_ASSUME_FUELNOW_FOREGROUND:-0}" != "1" ]]; then
  # Relaunch: nötig wenn FuelNow nach Maps im Hintergrund hing — nach frischem Build aber kontraproduktiv (Pins noch leer).
  xcrun simctl launch "${UDID}" com.vibecoding.fuelnow >/dev/null 2>&1 || true
  sleep 5
else
  sleep 2
fi

PRELUDE="${ROOT}/scripts/axe/fuelnow-functional-smoke-prelude.steps"
OUT_DIR="${ROOT}/scripts/axe/output"
mkdir -p "${OUT_DIR}"
SHOT="${AXE_SCREENSHOT_PATH:-${OUT_DIR}/fuelnow-launch.png}"

echo "FuelNow: axe batch (Prelude) --file ${PRELUDE} --udid ${UDID}"
set +e
axe batch --file "${PRELUDE}" --udid "${UDID}" "$@"
prelude_status=$?
set -e

if [[ "${prelude_status}" -eq 0 ]]; then
  echo "FuelNow: Warte ${FUELNOW_AXE_POST_PRELUDE_STATION_WAIT_SECONDS:-18}s auf Tankstellen in der Karten-AX …"
  sleep "${FUELNOW_AXE_POST_PRELUDE_STATION_WAIT_SECONDS:-18}"
fi

label=""
describe_json=""
for _attempt in 1 2 3 4 5; do
  if describe_json="$(axe describe-ui --udid "${UDID}" 2>&1)"; then
    if label="$(printf '%s' "${describe_json}" | python3 "${ROOT}/scripts/axe/extract_map_pin_label.py" 2>/dev/null)"; then
      break
    fi
    cluster_label=""
    if cluster_label="$(printf '%s' "${describe_json}" | python3 "${ROOT}/scripts/axe/extract_map_cluster_label.py" 2>/dev/null)"; then
      echo "FuelNow: Cluster-Pin „${cluster_label}“ antippen zum Hereinzoomen …"
      axe tap --label "${cluster_label}" --wait-timeout 15 --udid "${UDID}" 2>/dev/null || true
      sleep 3
    fi
  else
    echo "FuelNow: describe-ui fehlgeschlagen" >&2
    break
  fi
  sleep 3
done
if [[ -z "${label}" ]]; then
  echo "FuelNow: Kein Karten-Pin-Label gefunden (Karte laden / Standort?)." >&2
fi

pin_status=0
if [[ -n "${label}" ]]; then
  echo "FuelNow: tap map pin (AXLabel-Prefix: ${label:0:50}…)"
  if axe tap --label "${label}" --wait-timeout 20 --udid "${UDID}"; then
    sleep 2
    if [[ "${FUELNOW_AXE_INCLUDE_MAPS_NAV:-0}" == "1" ]]; then
      echo "FuelNow: Navigation in Apple Maps (Turn-by-turn) …"
      if axe tap --label "Navigation in Apple Maps" --wait-timeout 22 --udid "${UDID}"; then
        sleep 3
        xcrun simctl launch "${UDID}" com.vibecoding.fuelnow >/dev/null
        sleep 2
        xcrun simctl terminate "${UDID}" com.apple.Maps 2>/dev/null || true
        sleep 2
      else
        echo "FuelNow: Maps-Button nicht getroffen — Detail per Wisch schließen." >&2
        if ! axe swipe --start-x 200 --start-y 420 --end-x 200 --end-y 720 --duration 0.35 --post-delay 0.4 --udid "${UDID}"; then
          pin_status=1
          echo "FuelNow: Detail per Wischgeste schließen fehlgeschlagen" >&2
        fi
      fi
    else
      # Medium-Detent-Sheet: Schließen-Toolbar oft nicht per AX-Selektor treffbar — Wisch zuverlässiger.
      if ! axe swipe --start-x 200 --start-y 420 --end-x 200 --end-y 720 --duration 0.35 --post-delay 0.4 --udid "${UDID}"; then
        pin_status=1
        echo "FuelNow: Detail per Wischgeste schließen fehlgeschlagen" >&2
      fi
    fi
  else
    pin_status=1
    echo "FuelNow: Pin-Tap fehlgeschlagen" >&2
  fi
else
  pin_status=1
fi

if [[ "${AXE_SKIP_POST_SCREENSHOT:-0}" != "1" ]]; then
  mkdir -p "$(dirname "${SHOT}")"
  echo "FuelNow: axe screenshot → ${SHOT}"
  axe screenshot --udid "${UDID}" --output "${SHOT}" || true
fi

if [[ "${prelude_status}" -ne 0 ]] || [[ "${pin_status}" -ne 0 ]]; then
  exit 1
fi
exit 0
