# FuelNow — Spec Constitution

Dieses Dokument ist der **Spec-Kit-Verfassungsrahmen** für das Repo. Detail-Spezifikation und Konstanten: **`docs/PRODUCT_SPEC.md`** (Single Source). Agent-Kurzfakten und Workflows: **`AGENTS.md`**. Abos / StoreKit / TestFlight: **`docs/SUBSCRIPTIONS.md`**. CarPlay-Modi: **`docs/CARPLAY.md`**.

## Kernprinzipien

### I. Produkt & Scope

- **FuelNow:** Native iOS-App — Karte mit Tankstellen (Tankerkönig, Deutschland), Öffnungsstatus, Preise; Kraftstoffsorte in den Einstellungen.
- **Vertrieb:** App Store **nur Deutschland** (ASC); technische Konstanten und UI-Konventionen siehe `docs/PRODUCT_SPEC.md`.
- **Repo-Pfad** historisch **TankRadar** — bewusster Mismatch zum Target **FuelNow**, nicht ohne Abstimmung „bereinigen“.

### II. Daten & API

- **Tankerkönig:** Default über **Vercel-Proxy** (`tankerkoenig-proxy/`); API-Key **nicht** in der Binary (TAN-92). Vor API-/Radius-/Preisfeld-Arbeit: **`.cursor/skills/tankerkoenig-api/SKILL.md`** lesen und Linear-Tickets bei API-Drift anpassen.
- **Caching:** Kein eigener DB-Mirror als Default — `docs/TANKERKOENIG_CACHING.md` (TAN-82).

### III. Qualität & UI

- **Swift / SwiftUI:** Starke Codequalität, Tests wo sinnvoll; **WCAG 2.2 AAA** für Kontrast — `docs/A11Y.md`.
- **Konventionen:** Öffnungsstatus als **farbiger Punkt**; Preise **Schilder-Stil** `1,58⁹` über `FuelPriceLabel` / `FuelPriceFormatting`; keine widersprüchlichen Marketing-Claims zu CarPlay — immer `FuelNowFeatureFlags.carPlayCapabilityMode` + `docs/CARPLAY.md` prüfen.
- **Dateigröße:** Quellcode-Dateien **≤ 300 Zeilen** (Repo-Regel); vor Erweiterung splitten.

### IV. Plus & StoreKit

- **StoreKit 2**, keine RevenueCat-Pflicht im Stack; Produkt-IDs: `com.vibecoding.fuelnow.subscription.year` und `.month` — `SubscriptionConstants`, `FuelNowPlus.storekit`.
- **Plus-UI** nur **opt-in** (Settings / Gates), kein Launch-Paywall-Nag; Entitlements aus **`Transaction.currentEntitlements`** (Sandbox/TestFlight/Production). Details: `docs/SUBSCRIPTIONS.md`.

### V. Tickets, Branches, Lieferung

- **Linear:** Scope und Akzeptanzkriterien pro Ticket; bei Ticket-Arbeit **Feature-Branch** `feature/TAN-XX-kurz-slug` von aktuellem **`main`**.
- **Nach Code:** `./scripts/lint.sh --strict`, `./scripts/format.sh --lint`, grüner **FuelNow**-Build (siehe `.cursor/rules/post-implementation-build-lint.mdc` und `AGENTS.md`).

## Governance

- Bei Konflikt zwischen Spec-Kit-Artefakten und **`docs/PRODUCT_SPEC.md`** / Linear **gewinnt** der Produktindex bzw. das vereinbarte Ticket.
- Änderungen an dieser Constitution bei **Richtlinien-Wechseln** (Produkt, Store, API-Policy) nachziehen; Versionszeile unten pflegen.

**Version:** 1.0.0 | **Ratifiziert:** 2026-05-11 | **Zuletzt geändert:** 2026-05-11
