export function Footer() {
  const year = new Date().getFullYear()

  return (
    <footer className="siteFooter" role="contentinfo">
      <div className="container siteFooterInner">
        <div className="siteFooterBrand">
          <span className="siteFooterMark">FuelNow</span>
          <span className="siteFooterClaim">
            Spritpreise live auf der Karte — gebaut in Deutschland.
          </span>
        </div>
        <nav className="siteFooterLinks" aria-label="Rechtliche Hinweise">
          <a href="#/impressum">Impressum</a>
          <a href="#/datenschutz">Datenschutz</a>
        </nav>
      </div>
      <div className="container siteFooterMeta">
        <p>© {year} FuelNow. Alle Rechte vorbehalten.</p>
        <p className="siteFooterCredits">
          Apple, das Apple Logo und App Store sind Marken von Apple Inc.,
          eingetragen in den USA und anderen Ländern und Regionen.
          Tankstellen- und Preisdaten via Tankerkönig-API
          (CC&nbsp;BY&nbsp;4.0).
        </p>
      </div>
    </footer>
  )
}
