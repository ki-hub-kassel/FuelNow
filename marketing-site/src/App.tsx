import { useEffect } from 'react'

const keyBenefits = [
  {
    title: 'Live in deiner Nähe',
    text: 'Tankstellen inklusive Preise direkt auf der Karte.',
  },
  {
    title: 'Schneller zur günstigsten Station',
    text: 'Detailansicht und Apple-Maps-Navigation in einem Schritt.',
  },
  {
    title: 'Stabil bei schlechtem Netz',
    text: 'Offline-Hinweis mit automatischem Wiederanlauf.',
  },
]

const releaseChecklist = [
  'Klarer Nutzen + Feature-Highlights für Store und Landing Page',
  'Datenschutz-/Support-Infos direkt erreichbar',
  'App-Store-Call-to-Action inkl. Preview-Screens',
  'Technische SEO-Basis: Meta, OpenGraph, robots, sitemap, schema.org',
]

const faqItems = [
  {
    question: 'Welche Daten zeigt FuelNow?',
    answer: 'Aktuelle Kraftstoffpreise, Öffnungsstatus und Distanz zur Station.',
  },
  {
    question: 'Funktioniert die App nur in Deutschland?',
    answer: 'Aktuell ist FuelNow auf den deutschen Markt und Tankerkönig-Daten ausgelegt.',
  },
  {
    question: 'Wie starte ich die Navigation?',
    answer: 'In der Stations-Detailansicht tippen und direkt in Apple Maps starten.',
  },
]

function App() {
  useEffect(() => {
    document.title = 'FuelNow - Spritpreise App mit Live-Karte'
  }, [])

  return (
    <div className="siteRoot">
      <a className="skipLink" href="#content">
        Zum Inhalt springen
      </a>

      <header className="siteHeader">
        <a className="brand" href="#top" aria-label="FuelNow Startseite">
          FuelNow
        </a>
        <nav className="siteNav" aria-label="Hauptnavigation">
          <a href="#features">Features</a>
          <a href="#release">Release</a>
          <a href="#faq">FAQ</a>
        </nav>
      </header>

      <main id="content">
        <section id="top" className="section hero">
          <div className="container">
            <p className="eyebrow">Spritpreise. Schnell gefunden.</p>
            <h1>FuelNow zeigt dir die beste Tankstelle in deiner Nähe.</h1>
            <p className="lead">
              Ein klarer Flow für Endnutzer: Karte öffnen, Preis vergleichen, direkt
              navigieren.
            </p>
            <div className="actions">
              <a className="button buttonPrimary" href="#features">
                Features ansehen
              </a>
              <a className="button buttonGhost" href="#release">
                Release-Status
              </a>
            </div>
          </div>
        </section>

        <section id="features" className="section">
          <div className="container">
            <h2>Worauf Nutzer sofort achten</h2>
            <div className="cardGrid">
              {keyBenefits.map((item) => (
                <article key={item.title} className="card">
                  <h3>{item.title}</h3>
                  <p>{item.text}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section className="section">
          <div className="container">
            <h2>App-Einblick</h2>
            <div className="screenshotGrid">
              <figure className="shotCard">
                <img
                  src="/appshots/map-view.png"
                  alt="FuelNow Kartenansicht mit Preis-Pins"
                  width={390}
                  height={844}
                  loading="eager"
                  decoding="async"
                />
                <figcaption>Karte mit Live-Preisen</figcaption>
              </figure>
              <figure className="shotCard">
                <img
                  src="/appshots/station-detail.png"
                  alt="FuelNow Stationsdetail mit Preisen und Navigation"
                  width={390}
                  height={844}
                  loading="lazy"
                  decoding="async"
                />
                <figcaption>Detailansicht mit Navigation</figcaption>
              </figure>
              <figure className="shotCard">
                <img
                  src="/appshots/area-search.png"
                  alt="FuelNow Suche im aktuellen Kartengebiet"
                  width={390}
                  height={844}
                  loading="lazy"
                  decoding="async"
                />
                <figcaption>Gezielte Gebietssuche</figcaption>
              </figure>
            </div>
          </div>
        </section>

        <section id="release" className="section">
          <div className="container releaseBox">
            <h2>Release-ready Seite</h2>
            <ul>
              {releaseChecklist.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
            <p className="smallInfo">
              Kontakt: <a href="mailto:hello@fuelnow.app">hello@fuelnow.app</a> · Datenschutz:
              {' '}
              <a href="https://fuelnow.app/privacy" target="_blank" rel="noreferrer">
                fuelnow.app/privacy
              </a>
            </p>
          </div>
        </section>

        <section id="faq" className="section">
          <div className="container">
            <h2>FAQ</h2>
            <div className="faqList">
              {faqItems.map((item) => (
                <details key={item.question}>
                  <summary>{item.question}</summary>
                  <p>{item.answer}</p>
                </details>
              ))}
            </div>
          </div>
        </section>

        <section className="section finalCta">
          <div className="container">
            <h2>FuelNow jetzt entdecken</h2>
            <a
              className="button buttonPrimary"
              href="https://apps.apple.com/"
              target="_blank"
              rel="noreferrer"
              aria-label="FuelNow im App Store ansehen"
            >
              Im App Store ansehen
            </a>
          </div>
        </section>
      </main>
    </div>
  )
}

export default App
