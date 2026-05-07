# tankerkoenig-proxy

Schlanker HTTPS-Proxy für die [Tankerkönig-API](https://creativecommons.tankerkoenig.de/?page=info), gehostet als **Vercel Edge Functions** (Hobby-Plan, kostenlos, keine Kreditkarte). Hängt den Tankerkönig-API-Key serverseitig an jede Anfrage — die FuelNow-iOS-App kommt ohne Key in der App-Binary aus, was den Tankerkönig-AGB entspricht (Verbreitung des Keys ist dort ausdrücklich untersagt).

## Verhalten

- Whitelist auf genau drei Pfade (Edge Functions direkt, ohne `vercel.json`-Rewrites):
  - `GET /api/json/list`   → upstream `list.php`
  - `GET /api/json/prices` → upstream `prices.php`
  - `GET /api/json/detail` → upstream `detail.php`
- Alles andere → 404 (über fehlende Vercel-Routen) oder 405 (falsche Methode).
- Edge Runtime, `regions: ["fra1"]` → niedrige Latenz für DE-User.
- **Kein** Cache (`cache-control: no-store`). Tankerkönig erlaubt nur on-demand-Pass-through; siehe `docs/TANKERKOENIG_CACHING.md` im FuelNow-Repo.
- API-Key liegt nur als verschlüsselte **Vercel Production Environment Variable** `TANKERKOENIG_API_KEY` vor. Niemals committen.

> **Warum kein `/json/*.php`?** Vercel Firewall mitigiert `.php`-Pfade als typische
> WordPress-Bot-Scans (Antwort: `HTTP 403`, `x-vercel-mitigated: deny`) — nicht
> abschaltbar im Hobby-Plan. Der iOS-Client (`TankerkoenigClient`) ruft daher im
> Proxy-Modus direkt `<base>/api/json/list?…` auf; im Direct-Modus gegen
> `creativecommons.tankerkoenig.de` bleibt es wie gehabt `/json/list.php?…`.

## Setup (einmalig)

```bash
# 1) Vercel CLI
npm i -g vercel
# (oder npx vercel statt globaler Install)

# 2) Vom FuelNow-Repo aus in den Proxy-Folder
cd tankerkoenig-proxy

# 3) Mit Vercel verbinden — neues Hobby-Projekt (KEINE Kreditkarte)
vercel link

# 4) Tankerkönig-Key als Production-Secret hinterlegen
#    (CLI fragt interaktiv nach dem Wert)
vercel env add TANKERKOENIG_API_KEY production

# 5) Erstes Deployment
vercel deploy --prod
```

Die CLI gibt am Ende eine URL der Form `https://<projekt>.vercel.app` aus — diese URL kommt anschließend in `FuelNow/Info.plist` (Schlüssel `TankerkoenigProxyBaseURL`).

## Lokal entwickeln

```bash
cd tankerkoenig-proxy
vercel env pull .env.development.local      # holt das Secret lokal (gitignored)
vercel dev                                  # startet auf http://localhost:3000
```

Smoke-Test (Berlin Mitte, 5 km):

```bash
curl 'http://localhost:3000/api/json/list?lat=52.52&lng=13.405&rad=5&type=all&sort=dist'
# Production-Alias:
curl 'https://fuel-now-ki-hub-kassels-projects.vercel.app/api/json/list?lat=52.52&lng=13.405&rad=5&type=all&sort=dist'
```

## Updates / Deploys

```bash
cd tankerkoenig-proxy
vercel deploy --prod      # neues Deployment auf der bestehenden URL
```

Bei Key-Rotation:

```bash
vercel env rm TANKERKOENIG_API_KEY production
vercel env add TANKERKOENIG_API_KEY production
vercel deploy --prod
```

## Kosten

Vercel Hobby ist dauerhaft kostenlos und verlangt **keine** Kreditkarte. Aktuelle Limits (2026):

- 100 GB Bandwidth/Monat
- 100 k Function Invocations/Monat
- Edge Functions in `fra1` und anderen Regionen verfügbar

Bei FuelNow-Defaults (StationStore-Debounce ca. 30 s + 500 m, kein Massen-Mirror) bleibt das mit deutlichem Puffer unter den Limits. Bei Überschreitung **drosselt** Vercel die Functions, ein automatisches Upgrade auf Pro findet **nicht** statt — entsprechend kein Kostenrisiko.

## App-seitige Integration

Auf der iOS-Seite genügt ein neuer Eintrag in `FuelNow/Info.plist`:

```xml
<key>TankerkoenigProxyBaseURL</key>
<string>https://<projekt>.vercel.app</string>
```

`TankerkoenigAPIConfiguration.resolved()` liest diesen Schlüssel und schaltet automatisch in den Proxy-Modus — die App ruft `<base>/api/json/list?…` ohne `apikey` auf. Der Direct-Modus (`APIKeys.tankerkoenig`) bleibt als Fallback im Code, wird im Default-Workflow aber nicht mehr genutzt.

## Deployment Protection

Beim erstmaligen Deploy aktiviert Vercel für Team-Projekte automatisch **Vercel Authentication** (Settings → **Deployment Protection**). Das blockt anonyme Anfragen mit `HTTP 401` — also **deaktivieren**, damit die iOS-App den Proxy aufrufen kann (oder „Only Preview Deployments", dann bleibt nur Production öffentlich).

## Stabiler Production-Alias

Vercel deploys hängen an Hash-URLs (`fuel-<hash>-…vercel.app`), die sich bei jedem Build ändern. Der iOS-`Info.plist`-Eintrag muss aber stabil bleiben — nutze daher den **Project-Alias** `https://<projekt>-<team>.vercel.app`. Falls ein fehlerhafter Deploy den Alias auf einen kaputten Build umlenkt:

```bash
vercel alias set <healthy-deployment-url> <projekt>-<team>.vercel.app
```

## Linear

- [TAN-92 — Tankerkönig HTTPS-Proxy via Vercel Edge Function](https://linear.app/tankradar-app/issue/TAN-92/tankerkonig-https-proxy-via-vercel-edge-function)
- Vorarbeit App-Seite: TAN-91 (Live-Default + Offline-Splash).
