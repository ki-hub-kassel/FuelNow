#!/usr/bin/env bash
# FuelNow — AXe-Funktionstest: Karte, Einstellungen, Standort zentrieren, erster Karten-Pin, Detail schließen.
# Voraussetzung: Simulator booted, FuelNow auf der Karte (z. B. nach ./scripts/build-and-run-simulator.sh).
# Optional: FUELNOW_BUILD_FIRST=1 baut/startet vorher wie build-run-and-axe (ohne zweiten AXe-Lauf).
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

PRELUDE="${ROOT}/scripts/axe/fuelnow-functional-smoke-prelude.steps"
OUT_DIR="${ROOT}/scripts/axe/output"
mkdir -p "${OUT_DIR}"
SHOT="${AXE_SCREENSHOT_PATH:-${OUT_DIR}/fuelnow-launch.png}"

echo "FuelNow: axe batch (Prelude) --file ${PRELUDE} --udid ${UDID}"
set +e
axe batch --file "${PRELUDE}" --udid "${UDID}" "$@"
prelude_status=$?
set -e

label=""
if describe_json="$(axe describe-ui --udid "${UDID}" 2>&1)"; then
  if label="$(printf '%s' "${describe_json}" | python3 "${ROOT}/scripts/axe/extract_map_pin_label.py" 2>/dev/null)"; then
    :
  else
    echo "FuelNow: Kein Karten-Pin-Label gefunden (Karte laden / Standort?)." >&2
  fi
else
  echo "FuelNow: describe-ui fehlgeschlagen" >&2
fi

pin_status=0
if [[ -n "${label}" ]]; then
  echo "FuelNow: tap map pin (AXLabel-Prefix: ${label:0:50}…)"
  if axe tap --label "${label}" --wait-timeout 20 --udid "${UDID}"; then
    sleep 2
    # Medium-Detent-Sheet: Schließen-Toolbar-Button hat im AX-Baum oft kein zuverlässiges --label/--id (SwiftUI).
    # Wischen nach unten schließt das Sheet stabil (iPhone-17-Referenzkoordinaten, Mitte → unten).
    if ! axe swipe --start-x 200 --start-y 420 --end-x 200 --end-y 720 --duration 0.35 --post-delay 0.4 --udid "${UDID}"; then
      pin_status=1
      echo "FuelNow: Detail per Wischgeste schließen fehlgeschlagen" >&2
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
