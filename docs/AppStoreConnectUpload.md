# App Store Connect — IPA & TestFlight

Das Repo bietet **zwei** Upload-Pfade nach App Store Connect, beide mit demselben **API-Key (JWT)**:

| Pfad | Wrapper | Status | Wann |
| --- | --- | --- | --- |
| **`asc` CLI** ([asccli.sh](https://asccli.sh)) | `./scripts/asc-upload.sh` | **bevorzugt seit TAN-95** | Standard-Releases, automatisierbar, keine Ruby-Toolchain. |
| **Fastlane** | `./scripts/asc.sh ios …` | Legacy/Fallback | Builds 1, 5, 7, 8 liefen darüber; bleibt funktionsfähig. |

Beide Pfade sprechen dieselbe Bundle-ID **`com.vibecoding.fuelnow`** und dasselbe Apple-Team **`FNXU97S3QK`** an.

## Nur Deutschland (App Store Verfügbarkeit)

**Ziel:** FuelNow soll im App Store **nur in Deutschland** gelistet und herunterladbar sein (kein weltweiter oder EU-weiter Release).

1. **App Store Connect** → **Apps** → **FuelNow** → **App Store** (bzw. **Distribution** je nach ASC-Oberfläche).
2. Öffne **Preise und Verfügbarkeit** / **Pricing and Availability** (oder die Verfügbarkeitsverwaltung für die App).
3. Unter **Verfügbarkeit** / **App Availability** nur **Deutschland** auswählen (alle anderen Regionen abwählen bzw. „Verfügbar in neuen Regionen“ deaktivieren, falls angeboten).
4. **Speichern.** Änderungen können etwas brauchen, bis sie in allen Storefronts konsistent sind.

**Hinweise:**

- Das ist **unabhängig** von der App-Sprache: `Localizable.xcstrings` kann weiter **Deutsch und Englisch** enthalten (z. B. für Nutzer in Deutschland mit englischer Systemsprache).
- **In-App-Käufe / Abos (FuelNow Plus):** Preise und ggf. Angebote pro Territorium weiter in **Abonnements** pflegen; wenn die App nur in **DEU** verkauft wird, reicht in der Praxis oft die deutsche Preisstaffel — prüfe in ASC trotzdem die Abo-Territorienliste auf ungewollte zusätzliche Länder.
- **CLI:** Territorien lassen sich mit `asc` pflegen, sobald ihr den passenden Workflow im Team nutzt (z. B. `asc pricing availability` / App-Setup — siehe [asc CLI](https://asccli.sh) und eure interne Doku). Für einmalige Korrektur reicht die ASC-Web-Oberfläche meist.

## `asc` CLI (TAN-95) — Standard-Pfad

### Einmal einrichten

```bash
# 1. CLI installieren
brew install asc

# 2. API-Key in der Keychain hinterlegen
#    (Key-ID = Suffix des AuthKey_<KEYID>.p8 Dateinamens; Issuer-ID steht
#     auf https://appstoreconnect.apple.com/access/integrations/api)
asc auth login \
  --name "FuelNow CLI" \
  --key-id "JDM5T6H3UH" \
  --issuer-id "<DEINE_ISSUER_ID>" \
  --private-key "$HOME/.appstoreconnect/private_keys/AuthKey_JDM5T6H3UH.p8" \
  --network

# 3. Verifizieren
asc auth status
asc apps list
```

Die `.p8`-Datei lebt auf der Mac-Seite unter `~/.appstoreconnect/private_keys/` (Mode `600`); Repo-Pfade `AuthKey_*.p8`, `.asc/config.json`, `.asc/artifacts/` sind in `.gitignore`.

### Build & Upload

```bash
./scripts/asc-upload.sh
```

Das Skript führt vollständig aus:

1. `asc builds next-build-number` → kollisionsfreie `CFBundleVersion` (heute z. B. **9**, weil ASC bereits Build 8 kennt).
2. `asc xcode version edit` → setzt diese Build-Nummer im `.xcodeproj`.
3. `asc xcode archive` → Release-Archive nach `.asc/artifacts/FuelNow.xcarchive`.
4. `asc xcode export` → IPA mit `scripts/asc/ExportOptions.appstore.plist` (`signingStyle = automatic`, `teamID = FNXU97S3QK`) nach `.asc/artifacts/FuelNow.ipa`.
5. `asc builds upload --wait` → Upload und Polling bis ASC den Build verarbeitet hat.

### Optionale ENV-Variablen

| Variable | Wirkung |
| --- | --- |
| `BUILD_NUMBER` | erzwingt eine konkrete Nummer (überspringt `next-build-number`) |
| `APP_VERSION` | hebt die Marketing-Version (`CFBundleShortVersionString`) an |
| `SCHEME` / `CONFIGURATION` | überschreiben Defaults `FuelNow` / `Release` |
| `SKIP_UPLOAD=1` | nur Archive + Export, IPA bleibt unter `.asc/artifacts/` |
| `SKIP_PROCESS_WAIT=1` | Upload ohne `--wait` (nicht auf Processing warten) |
| `APP_ID` | überschreibt die FuelNow-App-ID `6766354442` (z. B. für andere Apps) |

### Nach dem Upload

- ASC-Web → FuelNow → TestFlight: Build erscheint zuerst als „Processing", danach mit grünem Status. Verschlüsselungs-/Export-Compliance-Antwort kann pro Build gefragt werden.
- TestFlight-Verteilung an Gruppen läuft über `asc publish testflight --app 6766354442 --ipa … --group <GROUP_ID>` oder via ASC-Web.

### Automatisch nach Push auf `main`

Wenn du nach jedem Push auf `main` automatisch eine neue Version in TestFlight hochladen willst:

```bash
git config core.hooksPath scripts/git-hooks
```

Dann triggert `scripts/git-hooks/post-push` bei `refs/heads/main` automatisch:

1. Patch-Bump der Marketing-Version (z. B. `1.0` → `1.0.1`)
2. `./scripts/asc-upload.sh` (inkl. nächster Build-Nummer via `asc builds next-build-number`)

Temporär deaktivieren:

```bash
FUELNOW_SKIP_POST_PUSH_RELEASE=1 git push origin main
```

## Fastlane — Legacy / Fallback

Wird beibehalten, falls der `asc`-Pfad blockiert ist (z. B. wenn Xcode-Provisioning aus dem Cache fällt). Funktional identisch zum Apple-Team **`FNXU97S3QK`**.

### Voraussetzungen

1. App-Eintrag in App Store Connect für **`com.vibecoding.fuelnow`** (einmalig in der Web-UI; Schreibweise wie in ASC).
2. API Key unter *Users and Access → Integrations → App Store Connect API* mit ausreichender Rolle für Builds.
3. **Signing:** Xcode *Release* mit Automatic Signing auf dem Mac, der archiviert. **`fastlane/Appfile`** → `team_id` muss dieselbe **Apple Team ID** sein wie unter *Signing & Capabilities* / `DEVELOPMENT_TEAM` im Xcode-Projekt (Mitgliedschaft: [developer.apple.com/account](https://developer.apple.com/account) → Membership details).

### Konfiguration

Vorbild: `fastlane/asc-env.template`. Datei **`.env.asc.local`** im Repo-Root anlegen (gitignored).

```bash
export ASC_KEY_ID="XXXXXXXXXX"
export ASC_ISSUER_ID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export ASC_KEY_PATH="$HOME/AuthKey_XXXXXXXXXX.p8"
```

Prüfen:

```bash
./scripts/asc.sh ios asc_verify
```

### Build & Upload

Ein Befehl (Release-Archive, Export, Upload zu TestFlight):

```bash
./scripts/asc.sh ios asc_ship_testflight
```

Nur IPA bauen:

```bash
./scripts/asc.sh ios asc_build_appstore_ipa
# → build/FuelNow.ipa
```

Nur Upload:

```bash
IPA_PATH="$PWD/build/FuelNow.ipa" ./scripts/asc.sh ios asc_upload_ipa
```

Vor dem ersten Lauf: `bundle install` im Repo-Root.

### Optional

| Variable | Bedeutung |
| --- | --- |
| `ASC_SKIP_WAIT=1` | Nicht auf Processing in ASC warten |
| `ASC_WHATS_NEW` | „What to Test“ für TestFlight |
| `ASC_EXPORT_TEAM_ID` | Optional: 10-stellige Team-ID, falls `gym` beim Export das Team nicht eindeutig zuordnet |

## Fehler: „No profiles for 'com.vibecoding.fuelnow' were found" (Export)

Das **Archiv** kann erfolgreich sein, der Schritt **`exportArchive`** scheitert trotzdem: für die Bundle-ID fehlt ein **Distribution-/App-Store-Provisioning-Profil** (oder Xcode hat es noch nicht geladen).

**Checkliste:**

1. **[Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)**  
   - Identifier **`com.vibecoding.fuelnow`** existiert (exakt wie im Xcode-Projekt).  
   - Unter *Profiles* gibt es ein **App Store**-Profil für genau diese App-ID — oder du nutzt **Automatic Signing** und lässt Xcode das erzeugen.

2. **Xcode** → Target **FuelNow** → **Signing & Capabilities**  
   - Gleiches **Team** wie im Projekt / `fastlane/Appfile`.  
   - Keine roten Signing-Warnungen; ggf. **„Try Again“** oder Team kurz wechseln und zurück.  
   - **Product → Clean Build Folder**, dann erneut `./scripts/asc.sh ios asc_build_appstore_ipa`.

3. **Xcode → Settings → Accounts** → dein Team → **Download Manual Profiles** (hilft manchmal nach neuem Bundle-ID).

4. Wenn du mehrere Teams hast: in `.env.asc.local` z. B.  
   `export ASC_EXPORT_TEAM_ID="XXXXXXXXXX"`  
   (Team-ID aus der Mitgliedschaftsseite).

Hinweis: Ein Archiv, das mit **„Apple Development“** signiert wurde, reicht für den App-Store-Export nicht — nach korrekter Einrichtung sollte der Export **„Apple Distribution“** / App-Store-Profil verwenden (bei Automatic Signing in der Regel automatisch nach Schritt 2).
