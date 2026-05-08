# FuelNow Widgets (MVP)

Dieses Dokument beschreibt die WidgetKit-MVP-Architektur fuer FuelNow.

## Umfang

- Home Screen: `systemSmall`, `systemMedium`
- Lock Screen: `accessoryInline`, `accessoryRectangular`
- Ein konfigurierbares Widget (`AppIntentConfiguration`) mit Modus:
  - `nearest` (naechste Tankstelle)
  - `cheapest` (guenstigste Tankstelle fuer bevorzugte Sorte)

## Architektur

1. Die App schreibt nach jedem relevanten Daten-Update ein Snapshot-JSON in den App-Group-Container.
2. Die Widget-Extension liest dieses Snapshot-JSON ueber `WidgetSnapshotStore`.
3. Das Widget rendert nur Snapshot-Daten, startet keine eigenen Netzwerkabfragen.
4. Interaktionen laufen ueber Deep Links (`fuelnow://station/<uuid>`) oder Apple-Maps-Link.
5. Das Medium-Widget bietet zusaetzlich einen interaktiven Refresh-Button (`FuelNowWidgetRefreshIntent`).

## Shared Storage

- App Group: `group.com.vibecoding.fuelnow`
- Snapshot-Datei: `widget-snapshot-v1.json`
- Shared Model:
  - `WidgetDataSnapshot`
  - `WidgetStationSnapshot`
  - `WidgetSnapshotLoadState`

## Datenaufbereitung

- Snapshot-Building in der App via `WidgetSnapshotBuilder`.
- Bevorzugte Kraftstoffsorte wird aus den App-Settings gespiegelt.
- Preis-/Distanzformatierung folgt den bestehenden App-Konventionen:
  - Pump-Style (z. B. `1,58⁹`)
  - Distanz als Meter/Kilometer

## Build- und Signatur-Setup

- Neues Extension-Target: `FuelNowWidgets`
- Bundle-ID: `com.vibecoding.fuelnow.widgets`
- Entitlements:
  - App: `FuelNow/FuelNow.entitlements` (inkl. App Group)
  - Extension: `FuelNowWidgets/FuelNowWidgets.entitlements`

## Verifikation (MVP)

- `xcodebuild -scheme "FuelNowWidgets" -project "FuelNow.xcodeproj" -destination 'generic/platform=iOS' build`
- `./scripts/build-and-run-simulator.sh`
- Optional manuell:
  - Widget auf Home-/Lock-Screen hinzufuegen
  - beide Varianten pruefen (naechste/guenstigste)
  - Tap auf Widget oeffnet App/Navigation korrekt
