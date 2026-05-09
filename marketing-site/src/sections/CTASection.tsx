const APP_STORE_URL = 'https://apps.apple.com/de/app/id6766354442'

export function CTASection() {
  return (
    <section id="cta" className="section ctaSection">
      <div className="container ctaContainer">
        <p className="eyebrow">Nächster Schritt</p>
        <h2>FuelNow im echten App-Flow ansehen.</h2>
        <div className="buttonRow">
          <a className="btnPrimary" href="#home">
            Zu den Funktionen oben
          </a>
          <a className="btnSecondary" href="#features">
            Walkthrough erneut öffnen
          </a>
        </div>
        <a
          className="appStoreBadgeLink"
          href={APP_STORE_URL}
          target="_blank"
          rel="noreferrer"
          aria-label="FuelNow im App Store laden"
        >
          <img
            className="appStoreBadgeImg"
            src="/app-store-badge-de.svg"
            alt="Laden im App Store"
            width="180"
            height="60"
            loading="lazy"
            decoding="async"
          />
        </a>
      </div>
    </section>
  )
}
