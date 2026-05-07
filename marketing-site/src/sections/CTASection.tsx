export function CTASection() {
  return (
    <section id="cta" className="section ctaSection">
      <div className="container ctaContainer">
        <p className="eyebrow">Naechster Schritt</p>
        <h2>FuelNow im echten App-Flow ansehen.</h2>
        <div className="buttonRow">
          <a className="btnPrimary" href="#home">
            Zu den Funktionen oben
          </a>
          <a className="btnSecondary" href="#features">
            Walkthrough erneut oeffnen
          </a>
        </div>
        <a
          className="appStoreButton"
          href="https://apps.apple.com/"
          target="_blank"
          rel="noreferrer"
          aria-label="Open Apple App Store"
        >
          <span aria-hidden="true"></span>
          <span>Im App Store</span>
        </a>
      </div>
    </section>
  )
}
