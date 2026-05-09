export function ImpressumPage() {
  return (
    <article className="section legalPage" aria-labelledby="impressum-heading">
      <div className="container legalContainer">
        <p className="eyebrow">Rechtliches</p>
        <h1 id="impressum-heading" className="legalTitle">
          Impressum
        </h1>

        <aside className="legalNotice" role="note">
          <strong>Hinweis:</strong> Diese Seite enthält derzeit
          <strong> Platzhalter-Daten</strong> für TestFlight-Vorbereitung. Vor
          App-Store-Submission werden alle § 5 TMG-Pflichtangaben durch die
          finalen Werte ersetzt.
        </aside>

        <section className="legalSection">
          <h2>Angaben gemäß § 5 TMG</h2>
          <p>
            <strong>FuelNow Team (Platzhalter)</strong>
            <br />
            Musterstraße 1
            <br />
            12345 Berlin
            <br />
            Deutschland
          </p>
        </section>

        <section className="legalSection">
          <h2>Kontakt</h2>
          <p>
            E-Mail: <a href="mailto:support@fuelnow.app">support@fuelnow.app</a>
            <br />
            Telefon: +49 30 1234567 (Platzhalter)
          </p>
        </section>

        <section className="legalSection">
          <h2>Verantwortlich für den Inhalt nach § 18 Abs. 2 MStV</h2>
          <p>
            FuelNow Team (Platzhalter)
            <br />
            Anschrift wie oben
          </p>
        </section>

        <section className="legalSection">
          <h2>EU-Streitschlichtung</h2>
          <p>
            Die Europäische Kommission stellt eine Plattform zur
            Online-Streitbeilegung (OS) bereit:{' '}
            <a
              href="https://ec.europa.eu/consumers/odr/"
              target="_blank"
              rel="noreferrer noopener"
            >
              https://ec.europa.eu/consumers/odr/
            </a>
            . Unsere E-Mail-Adresse findest du oben im Impressum.
          </p>
          <p>
            Wir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren
            vor einer Verbraucherschlichtungsstelle teilzunehmen.
          </p>
        </section>

        <section className="legalSection">
          <h2>Haftung für Inhalte</h2>
          <p>
            Als Diensteanbieter sind wir gemäß § 7 Abs. 1 TMG für eigene Inhalte
            auf dieser Website nach den allgemeinen Gesetzen verantwortlich. Nach
            §§ 8 bis 10 TMG sind wir als Diensteanbieter jedoch nicht
            verpflichtet, übermittelte oder gespeicherte fremde Informationen zu
            überwachen oder nach Umständen zu forschen, die auf eine
            rechtswidrige Tätigkeit hinweisen. Verpflichtungen zur Entfernung
            oder Sperrung der Nutzung von Informationen nach den allgemeinen
            Gesetzen bleiben hiervon unberührt. Eine diesbezügliche Haftung ist
            jedoch erst ab dem Zeitpunkt der Kenntnis einer konkreten
            Rechtsverletzung möglich.
          </p>
        </section>

        <section className="legalSection">
          <h2>Haftung für Links</h2>
          <p>
            Unser Angebot enthält Links zu externen Websites Dritter, auf deren
            Inhalte wir keinen Einfluss haben. Deshalb können wir für diese
            fremden Inhalte auch keine Gewähr übernehmen. Für die Inhalte der
            verlinkten Seiten ist stets der jeweilige Anbieter oder Betreiber
            der Seiten verantwortlich. Bei Bekanntwerden von Rechtsverletzungen
            werden wir derartige Links umgehend entfernen.
          </p>
        </section>

        <section className="legalSection">
          <h2>Urheberrecht</h2>
          <p>
            Die durch die Seitenbetreiber erstellten Inhalte und Werke auf
            dieser Website unterliegen dem deutschen Urheberrecht. Beiträge
            Dritter sind als solche gekennzeichnet. Die Vervielfältigung,
            Bearbeitung, Verbreitung und jede Art der Verwertung außerhalb der
            Grenzen des Urheberrechts bedürfen der schriftlichen Zustimmung des
            jeweiligen Autors bzw. Erstellers.
          </p>
        </section>

        <section className="legalSection">
          <h2>Markenhinweise</h2>
          <p>
            Apple, das Apple Logo und App Store sind Marken von Apple Inc.,
            eingetragen in den USA und anderen Ländern und Regionen.
          </p>
          <p>
            Tankstellen- und Preisdaten stammen von der Tankerkönig-API
            (creativecommons.tankerkoenig.de) und stehen unter der{' '}
            <a
              href="https://creativecommons.org/licenses/by/4.0/deed.de"
              target="_blank"
              rel="noreferrer noopener"
            >
              CC BY 4.0
            </a>{' '}
            Lizenz. Quelle: Tankerkönig-Spritpreis-API; Daten der MTS-K
            (Markttransparenzstelle für Kraftstoffe).
          </p>
        </section>

        <p className="legalUpdated">Stand: Mai 2026 (Platzhalter-Version)</p>
      </div>
    </article>
  )
}
