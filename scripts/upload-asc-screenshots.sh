#!/usr/bin/env bash
# Lädt iPhone- und optional Watch-Screenshots nach App Store Connect hoch
# (`asc screenshots upload`). Capture-/Frame-Skripte rufen das nicht automatisch auf.
#
# Voraussetzung: `asc auth login` (Keychain) — API-Rolle muss Screenshot-Upload erlauben
# (nicht jeder eingeschränkte API-Key darf alle Metadaten ändern).
#
# Eine der beiden Varianten für die Version-Lokalisierung:
#   A) ASC_VERSION_LOCALIZATION_ID=<UUID>   (z. B. de-DE-Eintrag der App-Version)
#   B) ASC_APP_STORE_VERSION_ID=<UUID> und ASC_LOCALE=de-DE  (Skript löst die ID auf)
#
# Beispiel Auflösung der Lokalisierungs-ID:
#   asc localizations list --version "<VERSION_ID>" --output json
#
# Beispiel Upload (zuerst Dry-Run):
#   ASC_UPLOAD_DRY_RUN=1 ./scripts/upload-asc-screenshots.sh
#   ./scripts/upload-asc-screenshots.sh
#
# Umgebung (Auszug):
#   ASC_IPHONE_SCREENSHOT_PATH — Ordner oder Datei (Default: screenshots/asc-store/framed)
#   ASC_UPLOAD_DEVICE_TYPE_IPHONE — z. B. IPHONE_65 (Default aus APP_IPHONE_65 → IPHONE_65)
#   ASC_UPLOAD_WATCH=1 — Watch-Ordner zusätzlich hochladen
#   ASC_WATCH_SCREENSHOT_PATH — Default: screenshots/asc-watch/raw
#   ASC_UPLOAD_DEVICE_TYPE_WATCH — Default: WATCH_SERIES_10
#   ASC_UPLOAD_REPLACE=1 — bestehende Screenshots der Zielsets vorher löschen
#   ASC_UPLOAD_DRY_RUN=1 — nur anzeigen
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v asc >/dev/null 2>&1; then
  echo "FuelNow: asc CLI fehlt." >&2
  exit 1
fi

ASC_APP_ID="${ASC_APP_ID:-6766354442}"
ASC_LOCALE="${ASC_LOCALE:-de-DE}"
IPHONE_PATH="${ASC_IPHONE_SCREENSHOT_PATH:-$ROOT/screenshots/asc-store/framed}"
WATCH_PATH="${ASC_WATCH_SCREENSHOT_PATH:-$ROOT/screenshots/asc-watch/raw}"
DT_IPHONE="${ASC_UPLOAD_DEVICE_TYPE_IPHONE:-${ASC_SCREENSHOT_DEVICE_TYPE:-APP_IPHONE_65}}"
DT_WATCH="${ASC_UPLOAD_DEVICE_TYPE_WATCH:-${ASC_WATCH_DEVICE_TYPE:-APP_WATCH_SERIES_10}}"

fuelnow_strip_app_prefix() {
  local s="$1"
  echo "${s#APP_}"
}

fuelnow_resolve_version_localization_id() {
  local ver_id="$1" loc="$2"
  asc localizations list --version "${ver_id}" --output json | python3 -c "
import json, sys
loc = sys.argv[1]
data = json.load(sys.stdin)
for item in data.get('data', []):
    attrs = item.get('attributes') or {}
    if attrs.get('locale') == loc:
        print(item['id'])
        sys.exit(0)
sys.exit(2)
" "${loc}"
}

LOC_ID="${ASC_VERSION_LOCALIZATION_ID:-}"
if [[ -z "${LOC_ID}" ]]; then
  if [[ -z "${ASC_APP_STORE_VERSION_ID:-}" ]]; then
    echo "FuelNow: Setze ASC_VERSION_LOCALIZATION_ID oder ASC_APP_STORE_VERSION_ID+ASC_LOCALE." >&2
    echo "FuelNow: Version-IDs: asc versions list --app ${ASC_APP_ID}" >&2
    exit 1
  fi
  LOC_ID="$(fuelnow_resolve_version_localization_id "${ASC_APP_STORE_VERSION_ID}" "${ASC_LOCALE}")"
fi

fuelnow_run_screenshots_upload() {
  local path="$1" dtype="$2"
  local -a cmd=(asc screenshots upload --version-localization "${LOC_ID}" --path "${path}" --device-type "${dtype}" --output table)
  if [[ "${ASC_UPLOAD_DRY_RUN:-0}" == "1" ]]; then
    cmd+=(--dry-run)
  fi
  if [[ "${ASC_UPLOAD_REPLACE:-0}" == "1" ]]; then
    cmd+=(--replace)
  fi
  "${cmd[@]}"
}

DTI="$(fuelnow_strip_app_prefix "${DT_IPHONE}")"
echo "FuelNow: Upload iPhone-Screenshots → Lokalisierung ${LOC_ID}, device-type ${DTI}, Pfad ${IPHONE_PATH}"
if [[ ! -e "${IPHONE_PATH}" ]]; then
  echo "FuelNow: iPhone-Pfad fehlt: ${IPHONE_PATH} (zuerst capture/frame ausführen)." >&2
  exit 1
fi
fuelnow_run_screenshots_upload "${IPHONE_PATH}" "${DTI}"

if [[ "${ASC_UPLOAD_WATCH:-0}" == "1" ]]; then
  DTW="$(fuelnow_strip_app_prefix "${DT_WATCH}")"
  echo "FuelNow: Upload Watch-Screenshots → device-type ${DTW}, Pfad ${WATCH_PATH}"
  if [[ ! -d "${WATCH_PATH}" ]]; then
    echo "FuelNow: Watch-Pfad fehlt: ${WATCH_PATH}" >&2
    exit 1
  fi
  fuelnow_run_screenshots_upload "${WATCH_PATH}" "${DTW}"
fi

echo "FuelNow: Fertig. Hinweis: en-US ggf. zweites Mal mit anderer ASC_VERSION_LOCALIZATION_ID."
