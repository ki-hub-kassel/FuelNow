# FuelNow — Produktspezifikation (Index)

Diese Datei ist die **zentrale Einstiegs-Spezifikation** im Repo: Kurzfassung von Produkt, Konventionen und Verweisen. Sie ersetzt keine Detail-Specs in Linear oder Code — bei Abweichungen gilt **Linear-Issue + Implementierung**, und dieser Index soll angepasst werden.

## Produktüberblick

- **FuelNow** ist eine native iOS-App: Tankstellen in der Nähe auf der Karte, Öffnungsstatus und Preise; Kraftstoffsorte (z. B. Super, Super95, Diesel) in den Einstellungen.
- **Vertrieb:** Die App ist für den **deutschen App Store** vorgesehen (**Verfügbarkeit nur Deutschland**). Technische Umsetzung: App Store Connect (nicht im Binary); Schritte: [`docs/AppStoreConnectUpload.md`](AppStoreConnectUpload.md) → Abschnitt *Nur Deutschland*. In-App-Daten (Tankerkönig) sind ohnehin auf Deutschland bezogen.
- **Daten:** Tankerkönig (Deutschland); API-Details und Decoding-Fallen: [`.cursor/skills/tankerkoenig-api/SKILL.md`](../.cursor/skills/tankerkoenig-api/SKILL.md). **Caching-Strategie (kein eigener DB-Mirror, On-Demand bleibt Default):** [`docs/TANKERKOENIG_CACHING.md`](TANKERKOENIG_CACHING.md) ([TAN-82](https://linear.app/tankradar-app/issue/TAN-82)). **Anschluss an Tankerkönig (TAN-92):** Vercel-Edge-Function-Proxy [`tankerkoenig-proxy/`](../tankerkoenig-proxy/README.md) hängt `apikey` serverseitig dran — der Key landet nicht in der App-Binary. App-seitige URL: `FuelNow/Info.plist` → `TankerkoenigProxyBaseURL`; Direct-Modus mit lokalem Key bleibt als Notnagel.
- **Geplant / Roadmap:** Siri (nächste/günstigste Station), CarPlay-kartenlastig, Abo-Gate (CarPlay u. a. für Abonnenten; Preisrichtung z. B. ~6 €/Jahr — finale Preise über StoreKit, nicht hardcodieren).
- **Backend-Richtung:** Appwrite (Swift SDK) — siehe Architektur-/Ticket-Kontext in Linear.

## Naming / Repo

- Produkt-Target: **FuelNow**. Historisch heißen Repo-Pfad und Remote weiter **TankRadar** — bewusster Mismatch, nicht „bereinigen“ ohne Abstimmung.

## Technische Konstanten

| Thema | Wert / Ort |
| --- | --- |
| Bundle-ID | `com.vibecoding.fuelnow` |
| App Store Verfügbarkeit | **Nur Deutschland (DEU)** — siehe [`docs/AppStoreConnectUpload.md`](AppStoreConnectUpload.md) |
| Tankerkönig-Anschluss (Default) | Vercel-Proxy in [`tankerkoenig-proxy/`](../tankerkoenig-proxy/README.md); URL via `FuelNow/Info.plist` → `TankerkoenigProxyBaseURL` (TAN-92) |
| Tankerkönig-Key (Direct-Notnagel) | `README.md`, `FuelNow/Support/APIKeys.example.swift` — nie Key committen |
| Plus-Abo Product-IDs | **Jahr:** `com.vibecoding.fuelnow.subscription.year` · **Monat:** `com.vibecoding.fuelnow.subscription.month` (`SubscriptionConstants`, `FuelNowPlus.storekit`; Details [`docs/SUBSCRIPTIONS.md`](SUBSCRIPTIONS.md)) |

## Kernflows (Nutzer)

1. Karte öffnen → Standort → Stationen laden → Annotation auswählen → Details (Preis, Status).
2. Einstellungen → Kraftstoffsorte (und weitere App-Einstellungen).
3. (Roadmap) Siri / Kurzbefehle, CarPlay, Subscription.

## UI-Konventionen (FuelNow)

- Öffnungsstatus: **farbiger Punkt** (grün offen / rot zu), kein separates Status-Icon.
- Preise: **Tankstellen-Schilder-Stil** `1,58⁹` (TAN-93) — drei Nachkommastellen, die dritte als hochgestellte Zehntel-Ziffer; **ohne** „€/l“-Label und ohne `€`-Suffix in der Anzeige. Zentrale Komponente: `FuelPriceLabel` (SwiftUI) bzw. `FuelPriceFormatting.pumpStyleString` für reine Strings (CarPlay-`detailText`). VoiceOver/Siri-Voice nutzen weiterhin die volle Zahl natürlichsprachlich (`„1 Euro 58,9 Cent“` via `FuelPriceFormatting.voiceOverString`), nicht das Schilder-Format.
- „In Apple Maps öffnen“: **Turn-by-turn-Navigation** zur Station, nicht nur Kartenansicht.
- Sheets: **Schließen-Icon**, kein „Fertig“-Button als Standard.

## Nicht-Ziele dieses Dokuments

- Keine vollständige API-Referenz (Tankerkönig-Skill + offizielle Doku).
- Keine Release- oder ASC-Schrittfolge (siehe `README.md` und `docs/AppStoreConnectUpload.md`).
- Keine testbare Akzeptanzkriterien pro Feature — die stehen in **Linear** mit DoD und Checkboxen.

## Verweise (Specs verteilt)

| Bereich | Dokument / Ort |
| --- | --- |
| Betrieb, Keys, StoreKit, AXe | [README.md](../README.md) |
| Agent-/Team-Workflow, Backlog-Reihenfolge, Kurzfakten | [AGENTS.md](../AGENTS.md) |
| Siri & Kurzbefehle QA | [docs/SiriShortcutsQA.md](SiriShortcutsQA.md) |
| WidgetKit MVP | [docs/WIDGETS.md](WIDGETS.md) |
| App Store Connect Upload | [docs/AppStoreConnectUpload.md](AppStoreConnectUpload.md) |
| Light/Dark & Linear-Tickets | [docs/LightDarkModeLinearTickets.md](LightDarkModeLinearTickets.md) |
| Tankerkönig API | [`.cursor/skills/tankerkoenig-api/SKILL.md`](../.cursor/skills/tankerkoenig-api/SKILL.md) |
| Tankerkönig Caching-ADR | [`docs/TANKERKOENIG_CACHING.md`](TANKERKOENIG_CACHING.md) ([TAN-82](https://linear.app/tankradar-app/issue/TAN-82)) |
| Tankerkönig Vercel-Proxy | [`tankerkoenig-proxy/README.md`](../tankerkoenig-proxy/README.md) ([TAN-92](https://linear.app/tankradar-app/issue/TAN-92)) |
| SDD-Arbeitsweise (Planung/Umsetzung/Audit) | [`.cursor/skills/sdd-*.md`](../.cursor/skills/) |
| Spec-Kit (GitHub) / Cursor-Integration | [`.spec-kit.md`](../.spec-kit.md), [`docs/SPECKIT.md`](SPECKIT.md) |
| Feature-Scope, Akzeptanzkriterien, Epics | [Linear — FuelNow App](https://linear.app/tankradar-app) |

## Pflege

Nach größeren Produkt- oder Branding-Änderungen: dieses Index-Dokument und ggf. erste Absätze in `README.md` / `AGENTS.md` abstimmen. Detailed Specs bleiben in Linear pro Ticket nachziehbar.
