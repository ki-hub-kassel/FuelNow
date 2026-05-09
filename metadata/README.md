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

## API-Keys (Status)

- `FuelNow CLI` (`JDM5T6H3UH`) — Build-Upload-Rolle (Developer/App Manager-light), reicht **nicht** für Listing-Writes.
- `FuelNow App Manager` (`45DX4AC669`) — **App-Manager-Rolle**, derzeit Default. Damit wurden die Listing-Texte und TestFlight-Localizations am 2026-05-09 erstmals nach ASC gepusht.

`asc auth switch --name "FuelNow App Manager"` macht ihn zum Default; `asc auth status` zeigt den aktiven Key.

## Apple-Eigenheiten beim 1.0-Push (gelernt)

- **App-Name pro Locale ist pro Account eindeutig:** „FuelNow" war in `en-US` schon woanders belegt. Lösung war ein abweichender Name `FuelNow — Fuel Prices` für `en-US`. Sobald der echte App-Name finalisiert wird, bei Trademark-Konflikt entweder Trademark-Claim oder Locale-spezifischen Namen behalten.
- **`whatsNew` für Erstveröffentlichung 1.0 ist gesperrt:** Apple liefert „Attribute 'whatsNew' cannot be edited at this time" — das Feld ist erst ab 1.0.1+ relevant. Lokale JSONs enthalten daher kein `whatsNew` mehr.
- **Bekannte Ablehnungsgründe** treten oft erst beim Push auf. Validate ist nur ein Schema-Check, kein Apple-seitiger Vorab-Check.

## Was ist Platzhalter?

- E-Mail-Adressen `support@fuelnow.app`, `privacy@fuelnow.app`, `beta@fuelnow.app`
- Marketing-Site-Inhalte (`Impressum`, `Datenschutz`) zeigen einen sichtbaren
  „Platzhalter-Daten"-Banner — `marketing-site/src/sections/{Impressum,Datenschutz}Page.tsx`
- Telefonnummer und Anschrift im Impressum
- Inhabername („FuelNow Team")

Vor Submission durch echte Werte ersetzen, dann den Banner aus den beiden Pages entfernen.
