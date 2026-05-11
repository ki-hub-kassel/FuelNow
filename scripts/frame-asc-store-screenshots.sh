#!/usr/bin/env bash
# ASC-Ausgabeordner: bevorzugt `asc screenshots frame` (Koubou), sonst Roh-PNGs (= gleiche
# Dateien wie nach capture — für `asc screenshots validate` / `upload` ohne Geräterahmen).
#
# Optional (nur für Rahmen):
#   pip install koubou==0.18.1 && kou setup-frames
#   Python 3.12+ für kou setup-frames empfohlen (siehe ASC_FRAME_PYTHON).
#
# Umgebung:
#   ASC_STORE_RAW_DIR, ASC_STORE_FRAMED_DIR, ASC_FRAME_DEVICE
#   ASC_SCREENSHOT_DEVICE_TYPE — validate/upload-Ziel (Standard: APP_IPHONE_65)
#   ASC_FRAME_PYTHON — Python, dessen user-base/bin `kou` enthält
#   ASC_SCREENSHOTS_NO_FRAME=1 — Rahmen überspringen, nur kopieren
#
# Beispiel:
#   ./scripts/frame-asc-store-screenshots.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -n "${ASC_FRAME_PYTHON:-}" ]]; then
  if [[ ! -x "${ASC_FRAME_PYTHON}" ]]; then
    echo "FuelNow: ASC_FRAME_PYTHON ist nicht ausführbar: ${ASC_FRAME_PYTHON}" >&2
    exit 1
  fi
  export PATH="$("${ASC_FRAME_PYTHON}" -m site --user-base)/bin:${PATH}"
fi

RAW="${ASC_STORE_RAW_DIR:-$ROOT/screenshots/asc-store/raw}"
FRAMED="${ASC_STORE_FRAMED_DIR:-$ROOT/screenshots/asc-store/framed}"
ASC_SCREENSHOT_DEVICE_TYPE="${ASC_SCREENSHOT_DEVICE_TYPE:-APP_IPHONE_65}"
DEVICE="${ASC_FRAME_DEVICE:-iphone-air}"
PY="${ASC_FRAME_PYTHON:-python3}"

if ! command -v asc >/dev/null 2>&1; then
  echo "FuelNow: asc CLI fehlt (brew install asc)." >&2
  exit 1
fi

PNGS=()
while IFS= read -r f; do
  [[ -n "${f}" ]] && PNGS+=("${f}")
done < <(find "${RAW}" -maxdepth 1 -name '*.png' -type f | LC_ALL=C sort)

if [[ ${#PNGS[@]} -eq 0 ]]; then
  echo "FuelNow: Keine PNGs in ${RAW}. Zuerst ./scripts/capture-asc-store-screenshots.sh ausführen." >&2
  exit 1
fi

mkdir -p "${FRAMED}"

try_kou_frame=false
if [[ "${ASC_SCREENSHOTS_NO_FRAME:-0}" != "1" ]]; then
  if "${PY}" -c "import koubou" >/dev/null 2>&1; then
    PY_USER_BIN="$("${PY}" -m site --user-base 2>/dev/null)/bin"
    if [[ -n "${PY_USER_BIN}" && -d "${PY_USER_BIN}" && -x "${PY_USER_BIN}/kou" ]]; then
      export PATH="${PY_USER_BIN}:${PATH}"
    fi
    if command -v kou >/dev/null 2>&1; then
      try_kou_frame=true
    fi
  fi
fi

# Koubou-Frame-Extrakt braucht i.d.R. Python 3.12+ (tarfile.filter); sonst nur teurer Download + Fehler.
if [[ "${try_kou_frame}" == true ]] \
  && ! "${PY}" -c "import sys; sys.exit(0 if sys.version_info >= (3, 12) else 1)" 2>/dev/null \
  && [[ "${ASC_ALLOW_KOU_ON_OLD_PYTHON:-0}" != "1" ]]; then
  echo "FuelNow: ${PY} ist < 3.12 — Rahmen-Versuch übersprungen (Roh-PNG). Für Rahmen: z. B. ASC_FRAME_PYTHON=/opt/homebrew/bin/python3.12" >&2
  try_kou_frame=false
fi

if [[ "${try_kou_frame}" == true ]]; then
  echo "FuelNow: asc screenshots frame → ${FRAMED} (--device ${DEVICE})"
  frame_ok=true
  set +e
  for png in "${PNGS[@]}"; do
    base="$(basename "${png}" .png)"
    echo "FuelNow:   ${base}.png"
    if ! asc screenshots frame \
      --input "${png}" \
      --output-dir "${FRAMED}" \
      --device "${DEVICE}" \
      --name "${base}" \
      --output json; then
      frame_ok=false
      break
    fi
  done
  set -e
  if [[ "${frame_ok}" == true ]]; then
    echo "FuelNow: Geräterahmen (Koubou) fertig."
  else
    echo "FuelNow: asc screenshots frame fehlgeschlagen — Fallback: Rohbilder (asc-Pfad ohne Rahmen)." >&2
    rm -f "${FRAMED}"/*.png 2>/dev/null || true
    try_kou_frame=false
  fi
fi

if [[ "${try_kou_frame}" != true ]]; then
  if [[ "${ASC_SCREENSHOTS_NO_FRAME:-0}" == "1" ]]; then
    echo "FuelNow: ASC_SCREENSHOTS_NO_FRAME=1 — kopiere Roh-PNGs nach ${FRAMED}."
  elif ! "${PY}" -c "import koubou" >/dev/null 2>&1; then
    echo "FuelNow: Kein Koubou für ${PY} — kopiere Roh-PNGs (pip install koubou==0.18.1 optional für Rahmen)."
  elif ! command -v kou >/dev/null 2>&1; then
    echo "FuelNow: \`kou\` nicht im PATH — kopiere Roh-PNGs."
  fi
  for png in "${PNGS[@]}"; do
    cp -f "${png}" "${FRAMED}/"
  done
  echo "FuelNow: Ausgabe = Rohscreenshots → ${FRAMED} (tauglich für asc screenshots validate/upload)."
fi

echo "FuelNow: asc validate (${ASC_SCREENSHOT_DEVICE_TYPE}) …"
asc screenshots validate --path "${FRAMED}" --device-type "${ASC_SCREENSHOT_DEVICE_TYPE}" --output table || true

echo "FuelNow: Fertig. Upload: ./scripts/upload-asc-screenshots.sh (ASC_VERSION_LOCALIZATION_ID oder ASC_APP_STORE_VERSION_ID+ASC_LOCALE)"
