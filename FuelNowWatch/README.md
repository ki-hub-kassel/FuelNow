# FuelNowWatch (Roadmap Phase 6 — Watch-Companion)

Apple-Watch-Companion-App. Sie ist bewusst **lese-orientiert**: ruft **keine Tankerkönig-API**
selbst auf, sondern bekommt den vom iPhone gebauten `WidgetDataSnapshot` per **`WatchConnectivity`**
geliefert. Damit gibt es genau eine Quelle der Wahrheit (das iPhone, das den Snapshot via
`WidgetSnapshotBuilder` baut), und die Watch hängt nicht am Tankerkönig-Quota.

## Status

- ✅ **Watch-Target ist im Xcode-Projekt verdrahtet** (`scripts/xcode-add-watch-target.rb`,
  einmalig ausgeführt). watchOS-App `FuelNowWatch`, Bundle-ID `com.vibecoding.fuelnow.watchkitapp`,
  Deployment-Target watchOS 26.0, Swift 6.0 strict concurrency, App-Group-Entitlement
  `group.com.vibecoding.fuelnow` (für künftige Watch-Widgets/Complications relevant — der
  Daten-Transport selbst geht über WCSession).
- ✅ **iOS-App embeddet die Watch-App automatisch** über die `Embed Watch Content`-CopyFiles-Phase
  (`$(CONTENTS_FOLDER_PATH)/Watch`). `FuelNow.app/Watch/FuelNowWatch.app` taucht im Build-Produkt auf.
- ✅ **Companion-Pairing** läuft über `WKCompanionAppBundleIdentifier = com.vibecoding.fuelnow` in
  `FuelNowWatch/Info.plist` — sobald die Watch mit dem iPhone gepaart ist, installiert iOS die
  Watch-App automatisch mit.
- ✅ **App Icon** liegt unter `FuelNowWatch/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
  (universal `1024×1024`, watchOS-26-Stil — Single-Size-Asset, watchOS rendert daraus alle
  benötigten Größen automatisch).
- ✅ **WCSession-Bridge:** `FuelNow/Services/WatchConnectivityCoordinator.swift` (iPhone-Seite)
  publisht den Snapshot über `WCSession.updateApplicationContext`, sobald `syncWidgetSnapshot()`
  in `FuelNowApp` läuft. `FuelNowWatchSnapshotProvider` (Watch-Seite) ist `WCSessionDelegate`,
  empfängt `didReceiveApplicationContext`, dekodiert die JSON-Bytes und persistiert die letzte
  Payload im Application-Support-Verzeichnis als Cold-Start-Cache.
- ⚠️ **App-Group-Provisioning auf einem echten Apple-Watch-Gerät** bleibt ein einmaliger Xcode-
  Schritt — wird heute nur für künftige Watch-Widgets/Complications gebraucht (siehe TAN-110).
  Auf dem **Watch-Simulator** ist das _nicht_ nötig (ad-hoc-Signing).
- ⚠️ **Komplikations-Widget-Extension** (`FuelNowWatchComplications.swift`) ist _Code-Skelett_,
  hat aber **kein eigenes Xcode-Target**. Folge-Ticket **TAN-110**.

## Datenfluss

```
iPhone (FuelNowApp.syncWidgetSnapshot)
  ├─ WidgetSnapshotStore.write(snapshot)            (App-Group → iOS Widgets)
  └─ WatchConnectivityCoordinator.shared.publish()  (WCSession → Watch)
       ↓
Watch (FuelNowWatchSnapshotProvider)
  ├─ session(_:didReceiveApplicationContext:)        (Live-Update)
  └─ Application-Support/watch-snapshot-v1.json     (Cold-Start-Cache)
```

`updateApplicationContext` ist idempotent (jeder neue Stand überschreibt den vorigen) und
wird auch dann ausgeliefert, wenn die Watch beim Senden gerade schläft — iOS puffert bis zur
nächsten Aktivierung. Das ist für genau einen aktuellen Snapshot perfekt; `transferUserInfo`
wäre queue-basiert und würde alte Snapshots stapeln.

## So bringst du die App auf den Apple-Watch-Simulator

Komfort-Skript `./scripts/build-and-run-watch-simulator.sh`:

1. Findet iPhone-Sim (`iPhone 17`) + Watch-Sim (`Apple Watch Ultra 3 (49mm)`),
2. bootet beide + paart sie (idempotent),
3. baut FuelNow für den iOS-Sim (Watch-App ist als `Embed Watch Content` mit drin),
4. installiert das iPhone-Bundle UND das eingebettete Watch-Bundle separat auf den jeweiligen Sim,
5. startet beide Apps (iPhone + Watch).

Eine kurze Wartezeit (Tankerkönig-Fetch) und der Snapshot kommt automatisch via WCSession an.

ENV-Override-Beispiele:

```bash
IPHONE_SIM_NAME="iPhone 17 Pro" WATCH_SIM_NAME="Apple Watch Ultra 3 (49mm)" \
  ./scripts/build-and-run-watch-simulator.sh
```

## So bringst du die App auf eine **echte** Apple Watch

1. Xcode öffnen, in der Project-Navigator-Leiste das `FuelNow`-Projekt wählen → Tab
   **Signing & Capabilities** → Target **FuelNowWatch** → Team `FNXU97S3QK` (Maurice Pfurr)
   sollte schon eingetragen sein.
2. Provisioning automatisch von Xcode erzeugen lassen — die Bundle-ID
   `com.vibecoding.fuelnow.watchkitapp` wird im Developer-Portal registriert.
3. iPhone + gepaarte Watch als Run-Destination wählen, **Run**. Die Watch-App wird mit dem
   iPhone-App-Paket übertragen, die WCSession-Brücke greift sofort.

## Bewusst nicht in dieser Phase

- **`FuelNowCore`-SPM-Refactor** — `Station`, `WidgetSnapshotStore`, `FuelPriceFormatting`
  in ein internes Swift Package extrahieren. Folge-Ticket **TAN-108**.
- **Komplikations-Widget-Extension** als eigenes Target — separates Watch-WidgetBundle,
  Folge-Ticket **TAN-110**.
- **Reichhaltigere Watch-UI** (Detail-Sheet, App-Intents, Map-Snippet) — heute nur eine
  scrollbare Liste mit „Nächste" / „Günstigste" / „Top-2 in der Nähe".
