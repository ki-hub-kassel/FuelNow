#!/usr/bin/env bash
# Aktiviert das CarPlay-Anzeige-Fenster im iOS Simulator (Companion-Fenster neben dem iPhone).
# Voraussetzung: Simulator.app läuft, Zielsimulator ist gebootet und die FuelNow-Erweiterung
# ist bereits am Gerät gestartet (z. B. `./scripts/build-and-run-simulator.sh`).
set -euo pipefail

open -a Simulator 2>/dev/null || true

osascript <<'APPLESCRIPT'
tell application "Simulator" to activate
delay 0.4
tell application "System Events"
  tell process "Simulator"
    set frontmost to true
    try
      click menu bar item "I/O" of menu bar 1
      delay 0.15
      click menu item "External Displays" of menu 1 of menu bar item "I/O" of menu bar 1
      delay 0.35
      click menu item "CarPlay" of menu 1 of menu item "External Displays" of menu 1 of menu bar item "I/O" of menu bar 1
    on errMsg number errNum
      error "Konnte Menü nicht steuern (Sprache/UI des Simulators?): " & errNum & " — " & errMsg
    end try
  end tell
end tell
APPLESCRIPT
