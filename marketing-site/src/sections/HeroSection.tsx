export function HeroSection() {
  return (
    <section id="home" className="heroSection section">
      <div className="container">
        <p className="eyebrow">FuelNow Performance Edition</p>
        <h1>Der Moment, in dem jeder merkt: Ohne FuelNow tankst du zu teuer.</h1>
        <p className="heroLead">
          Gebaut fuer Menschen, die nicht suchen wollen, sondern in Sekunden entscheiden. FuelNow
          kombiniert Live-Daten, ikonische Klarheit und ein Erlebnis, das sofort Vertrauen schafft.
        </p>
        <ul className="heroHighlights" aria-label="Key benefits">
          <li>Live Preisvorsprung statt veralteter Listen</li>
          <li>Map Storytelling statt Informations-Chaos</li>
          <li>Design, das nach Premium aussieht und sich so anfuehlt</li>
        </ul>
        <div className="buttonRow">
          <a className="btnPrimary" href="#features">
            Jetzt den Vorteil sehen
          </a>
          <a className="btnSecondary" href="#cta">
            FuelNow sichern
          </a>
        </div>
      </div>
    </section>
  )
}
