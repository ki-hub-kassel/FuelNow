export function DatenschutzPage() {
  return (
    <article className="section legalPage" aria-labelledby="datenschutz-heading">
      <div className="container legalContainer">
        <p className="eyebrow">Rechtliches</p>
        <h1 id="datenschutz-heading" className="legalTitle">
          Datenschutzerklärung
        </h1>

        <section className="legalSection">
          <h2>1. Verantwortlicher</h2>
          <p>
            Verantwortlich im Sinne der Datenschutz-Grundverordnung (DSGVO) und
            anderer nationaler Datenschutzgesetze ist:
          </p>
          <p>
            <strong>[BITTE ERGÄNZEN: Name / Inhaber]</strong>
            <br />
            [Anschrift]
            <br />
            E-Mail: <a href="mailto:[BITTE-ERGAENZEN]@example.com">[BITTE ERGÄNZEN]</a>
          </p>
        </section>

        <section className="legalSection">
          <h2>2. Erhebung allgemeiner Daten beim Besuch dieser Website</h2>
          <p>
            Beim Aufruf dieser Website werden durch unseren Hosting-Provider
            automatisch Informationen in sogenannten Server-Logfiles
            gespeichert, die dein Browser übermittelt. Dies sind:
          </p>
          <ul>
            <li>Browsertyp und Browserversion</li>
            <li>verwendetes Betriebssystem</li>
            <li>Referrer-URL</li>
            <li>Hostname des zugreifenden Rechners</li>
            <li>Uhrzeit der Serveranfrage</li>
            <li>IP-Adresse (in gekürzter / pseudonymisierter Form)</li>
          </ul>
          <p>
            Eine Zusammenführung dieser Daten mit anderen Datenquellen wird
            nicht vorgenommen. Die Erfassung erfolgt auf Grundlage von Art. 6
            Abs. 1 lit. f DSGVO. Der Websitebetreiber hat ein berechtigtes
            Interesse an der technisch fehlerfreien Darstellung und der
            Optimierung seiner Website — hierzu müssen die Server-Logfiles
            erfasst werden.
          </p>
        </section>

        <section className="legalSection">
          <h2>3. Hosting</h2>
          <p>
            Diese Website wird bei einem externen Dienstleister gehostet
            (Hoster). Personenbezogene Daten, die auf dieser Website erfasst
            werden, werden auf den Servern des Hosters gespeichert. Hierbei kann
            es sich v. a. um IP-Adressen, Kontaktanfragen, Meta- und
            Kommunikationsdaten, Vertragsdaten, Kontaktdaten, Namen,
            Webseitenzugriffe und sonstige Daten, die über eine Website
            generiert werden, handeln.
          </p>
          <p>
            Der Einsatz des Hosters erfolgt zum Zwecke der Vertragserfüllung
            gegenüber unseren potenziellen und bestehenden Kunden (Art. 6 Abs. 1
            lit. b DSGVO) und im Interesse einer sicheren, schnellen und
            effizienten Bereitstellung unseres Online-Angebots durch einen
            professionellen Anbieter (Art. 6 Abs. 1 lit. f DSGVO).
          </p>
          <p>
            <em>[BITTE ERGÄNZEN: Hosting-Anbieter, Anschrift, Link zur DPA.]</em>
          </p>
        </section>

        <section className="legalSection">
          <h2>4. Cookies und Tracking</h2>
          <p>
            Diese Website verwendet <strong>keine</strong> Cookies, kein
            Web-Tracking, kein Analytics-Tool und keine Werbe-Pixel. Deine
            Bewegung auf dieser Seite wird nicht profilbildend ausgewertet.
          </p>
        </section>

        <section className="legalSection">
          <h2>5. Eingebundene externe Inhalte</h2>
          <h3>Google Fonts (extern eingebunden)</h3>
          <p>
            Diese Website lädt Schriften (Syne, Outfit) über die Google-Fonts-
            CDN. Beim Aufruf der Website wird eine Verbindung zu Servern von
            Google LLC hergestellt; dabei wird deine IP-Adresse an Google
            übertragen. Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO
            (berechtigtes Interesse an einer einheitlichen, performanten
            Darstellung). Mehr Informationen unter{' '}
            <a
              href="https://policies.google.com/privacy"
              target="_blank"
              rel="noreferrer noopener"
            >
              policies.google.com/privacy
            </a>
            .
          </p>
          <p>
            <em>
              [Optional / empfohlen: Schriften lokal hosten, dann entfällt diese
              Übertragung an Google vollständig.]
            </em>
          </p>

          <h3>App Store-Verlinkung</h3>
          <p>
            Diese Website verlinkt auf die FuelNow-Produktseite im Apple App
            Store. Erst beim aktiven Klick auf den Badge wird eine Verbindung zu
            Apple-Servern aufgebaut. Es findet keine automatische Übertragung
            von Daten an Apple beim bloßen Aufrufen dieser Website statt.
          </p>
        </section>

        <section className="legalSection">
          <h2>6. Datenübermittlung in Drittstaaten</h2>
          <p>
            Eingebundene Inhalte (siehe Abschnitt 5) können dazu führen, dass
            Daten an Server außerhalb der EU/des EWR übertragen werden,
            insbesondere in die USA. Soweit Anbieter Standardvertragsklauseln
            der EU-Kommission nutzen oder ein Angemessenheitsbeschluss vorliegt
            (z. B. EU-US Data Privacy Framework), erfolgt die Übermittlung auf
            Grundlage dieser Garantien.
          </p>
        </section>

        <section className="legalSection">
          <h2>7. Speicherdauer</h2>
          <p>
            Soweit innerhalb dieser Datenschutzerklärung keine speziellere
            Speicherdauer genannt wurde, verbleiben deine personenbezogenen
            Daten bei uns, bis der Zweck der Datenverarbeitung entfällt. Server-
            Logfiles werden in der Regel nach 14 Tagen automatisch gelöscht oder
            anonymisiert.
          </p>
        </section>

        <section className="legalSection">
          <h2>8. Deine Rechte</h2>
          <p>Du hast jederzeit folgende Rechte:</p>
          <ul>
            <li>
              Recht auf Auskunft über die zu deiner Person gespeicherten Daten
              (Art. 15 DSGVO)
            </li>
            <li>Recht auf Berichtigung unrichtiger Daten (Art. 16 DSGVO)</li>
            <li>Recht auf Löschung (Art. 17 DSGVO)</li>
            <li>Recht auf Einschränkung der Verarbeitung (Art. 18 DSGVO)</li>
            <li>Recht auf Datenübertragbarkeit (Art. 20 DSGVO)</li>
            <li>
              Widerspruchsrecht gegen die Verarbeitung (Art. 21 DSGVO), wenn
              Verarbeitung auf Art. 6 Abs. 1 lit. e oder f DSGVO beruht
            </li>
            <li>
              Beschwerderecht bei einer Datenschutz-Aufsichtsbehörde (Art. 77
              DSGVO) — z. B. an die für deinen Wohnort zuständige
              Landesdatenschutzbehörde
            </li>
          </ul>
        </section>

        <section className="legalSection">
          <h2>9. SSL/TLS-Verschlüsselung</h2>
          <p>
            Diese Seite nutzt aus Sicherheitsgründen und zum Schutz der
            Übertragung vertraulicher Inhalte eine SSL/TLS-Verschlüsselung. Eine
            verschlüsselte Verbindung erkennst du am „https://" und am
            Schloss-Symbol in der Adresszeile deines Browsers.
          </p>
        </section>

        <p className="legalUpdated">Stand: [BITTE ERGÄNZEN: Monat Jahr]</p>
      </div>
    </article>
  )
}
