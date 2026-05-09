#!/usr/bin/env bash
# Baut FuelNow + FuelNowWatch fuer die iOS- und watchOS-Simulatoren, paart die beiden
# Simulatoren (falls noetig) und installiert beide App-Bundles. Anschliessend startet
# das Skript die FuelNow-Watch-App auf der gepairten Watch.
#
# Verwendung:
#   ./scripts/build-and-run-watch-simulator.sh
#
# Optional ueber ENV ueberschreibbar:
#   IPHONE_SIM_NAME       (Default: "iPhone 17")
#   WATCH_SIM_NAME        (Default: "Apple Watch Ultra 3 (49mm)")
#   DERIVED_DATA_PATH     (Default: .derived-data-ios)
#
# Hinweis: iPhone-Sim und Watch-Sim haben *separate* App-Group-Container — auch
# auf realen Geraeten ist die App-Group nicht ueber das iPhone↔Watch-Pair geteilt.
# Daten kommen via `WatchConnectivityCoordinator` (WCSession.updateApplicationContext)
# vom iPhone auf die Watch.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

IPHONE_SIM_NAME="${IPHONE_SIM_NAME:-iPhone 17}"
WATCH_SIM_NAME="${WATCH_SIM_NAME:-Apple Watch Ultra 3 (49mm)}"
DERIVED="${DERIVED_DATA_PATH:-$ROOT/.derived-data-ios}"

device_udid_in_section() {
  # $1 = section header pattern (e.g. "^-- iOS"), $2 = exact device name (e.g. "iPhone 17"
  # or "Apple Watch Ultra 3 (49mm)"). Uses literal substring matching to avoid awk
  # treating parentheses in $2 as regex metacharacters.
  local needle="    $2 ("
  local result
  result="$(xcrun simctl list devices available 2>/dev/null \
    | awk -v section="$1" -v needle="$needle" '
        $0 ~ section { in_section=1; next }
        /^-- / { in_section=0; next }
        in_section && index($0, needle) == 1 { print; exit }
      ')"
  printf '%s' "$result" | grep -Eo '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -1
}

iphone_udid() { device_udid_in_section '^-- iOS' "${IPHONE_SIM_NAME}"; }
watch_udid() { device_udid_in_section '^-- watchOS' "${WATCH_SIM_NAME}"; }

IPHONE_UDID="$(iphone_udid)"
WATCH_UDID="$(watch_udid)"
if [[ -z "${IPHONE_UDID}" ]]; then
  echo "build-and-run-watch-simulator: kein iPhone-Sim '${IPHONE_SIM_NAME}' gefunden." >&2
  exit 1
fi
if [[ -z "${WATCH_UDID}" ]]; then
  echo "build-and-run-watch-simulator: keine Apple Watch '${WATCH_SIM_NAME}' gefunden." >&2
  exit 1
fi

echo "build-and-run-watch-simulator: iPhone=${IPHONE_UDID} (${IPHONE_SIM_NAME}), Watch=${WATCH_UDID} (${WATCH_SIM_NAME})"

xcrun simctl boot "${IPHONE_UDID}" 2>/dev/null || true
xcrun simctl boot "${WATCH_UDID}" 2>/dev/null || true
open -a Simulator 2>/dev/null || true

# Pair if not already paired.
if ! xcrun simctl list pairs 2>/dev/null | grep -q "${IPHONE_UDID}"; then
  echo "build-and-run-watch-simulator: pairing iPhone <-> Watch …"
  xcrun simctl pair "${IPHONE_UDID}" "${WATCH_UDID}" >/dev/null
fi

echo "build-and-run-watch-simulator: building FuelNow scheme (iOS sim) …"
xcodebuild \
  -scheme FuelNow \
  -destination "platform=iOS Simulator,id=${IPHONE_UDID}" \
  -derivedDataPath "${DERIVED}" \
  -quiet \
  build

IOS_APP="${DERIVED}/Build/Products/Debug-iphonesimulator/FuelNow.app"
# Die Watch-App liegt als Embedded-Companion im iOS-Bundle (Embed-Watch-Content-Phase).
# Wir installieren beide Bundles separat: iPhone bekommt FuelNow.app, Watch bekommt
# FuelNow.app/Watch/FuelNowWatch.app — das ist der Pfad, den auch Xcode beim Run nimmt.
WATCH_APP="${IOS_APP}/Watch/FuelNowWatch.app"

if [[ ! -d "${IOS_APP}" ]]; then
  echo "build-and-run-watch-simulator: iOS Build-Produkt fehlt: ${IOS_APP}" >&2
  exit 1
fi
if [[ ! -d "${WATCH_APP}" ]]; then
  echo "build-and-run-watch-simulator: Embedded Watch-App fehlt: ${WATCH_APP}" >&2
  echo "  Pruefe Embed-Watch-Content-Phase in FuelNow.xcodeproj (siehe FuelNowWatch/README.md)." >&2
  exit 1
fi

xcrun simctl install "${IPHONE_UDID}" "${IOS_APP}"
xcrun simctl install "${WATCH_UDID}" "${WATCH_APP}"
xcrun simctl launch "${IPHONE_UDID}" com.vibecoding.fuelnow >/dev/null
xcrun simctl launch "${WATCH_UDID}" com.vibecoding.fuelnow.watchkitapp

echo "build-and-run-watch-simulator: FuelNow auf iPhone + Watch installiert + gestartet."
