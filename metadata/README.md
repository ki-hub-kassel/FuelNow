# App Store Connect — Metadata-Vorlagen

Dieses Verzeichnis ist die kanonische Quelle für Listing- und TestFlight-Texte.
Alle Werte sind **vorab als Platzhalter gefüllt** und sollen vor App-Store-Submission
durch die finalen Daten ersetzt werden.

## Layout

```
metadata/
  app-info/
    de-DE.json          # Name, Subtitle, Privacy Policy URL
    en-US.json
  version/1.0/
    de-DE.json          # Description, Keywords, Promotional Text, What's New, Marketing/Support URL
    en-US.json
  testflight/
    de-DE.json          # Beta-App-Localization (Description, Feedback-E-Mail, URLs)
    en-US.json
    build-21-whatsnew.json   # „What to Test" je Locale für Build 21
```

## Push nach App Store Connect

```bash
# 1. Validieren
asc metadata validate --dir ./metadata --output table

# 2. Dry-Run anschauen
asc metadata push --app 6766354442 --version 1.0 --platform IOS --dir ./metadata --dry-run --output table

# 3. Anwenden (nur app-info + version-Localizations)
asc metadata push --app 6766354442 --version 1.0 --platform IOS --dir ./metadata
```

## TestFlight (manuell)

```bash
asc testflight app-localizations create --app 6766354442 --locale de-DE \
  --description "$(jq -r .description metadata/testflight/de-DE.json)" \
  --feedback-email "$(jq -r .feedbackEmail metadata/testflight/de-DE.json)" \
  --marketing-url  "$(jq -r .marketingUrl metadata/testflight/de-DE.json)" \
  --privacy-policy-url "$(jq -r .privacyPolicyUrl metadata/testflight/de-DE.json)"

# What-to-Test für Build 21:
asc builds test-notes create --app 6766354442 --build-number 21 --version 1.0 --platform IOS \
  --locale de-DE \
  --whats-new "$(jq -r '.locales["de-DE"]' metadata/testflight/build-21-whatsnew.json)"
```

(jeweils analog für `en-US`)

## Permission-Hinweis (wichtig)

Der aktuell hinterlegte API-Key `FuelNow CLI` (`JDM5T6H3UH`) hat **nur Lese-/Build-Upload-Rechte**.
Alle obigen Schreib-Operationen für Listing- oder TestFlight-Localizations brechen mit
„This request is forbidden for security reasons" ab, bis dem Key in
**App Store Connect → Users and Access → Integrations → Team Keys**
mindestens die Rolle **App Manager** zugewiesen ist (oder ein zweiter Key mit dieser
Rolle angelegt und via `asc auth login` registriert wird).

Sobald die Berechtigung steht, werden die `metadata/`-Files 1:1 nach ASC übernommen.

## Was ist Platzhalter?

- E-Mail-Adressen `support@fuelnow.app`, `privacy@fuelnow.app`, `beta@fuelnow.app`
- Marketing-Site-Inhalte (`Impressum`, `Datenschutz`) zeigen einen sichtbaren
  „Platzhalter-Daten"-Banner — `marketing-site/src/sections/{Impressum,Datenschutz}Page.tsx`
- Telefonnummer und Anschrift im Impressum
- Inhabername („FuelNow Team")

Vor Submission durch echte Werte ersetzen, dann den Banner aus den beiden Pages entfernen.
