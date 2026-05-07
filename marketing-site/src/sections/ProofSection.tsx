const proofStats = [
  { label: 'Durchschnittliche Ersparnis', value: '17,80 EUR / Monat' },
  { label: 'Gefundene Stationen pro Session', value: '40+' },
  { label: 'Zeit bis zur Entscheidung', value: '< 10 Sekunden' },
]

const trustSignals = [
  'Live Preisdaten',
  'Map-first UX',
  'WCAG orientiertes Design',
  'iOS-native Performance',
  'Klare Entscheidung in Sekunden',
]

export function ProofSection() {
  return (
    <section className="section proofSection" aria-labelledby="proof-heading">
      <div className="container">
        <p className="eyebrow">Warum Menschen sofort umsteigen</p>
        <h2 id="proof-heading">FuelNow fuehlt sich nicht wie eine App an, sondern wie ein Vorteil.</h2>
        <div className="proofGrid">
          {proofStats.map((item) => (
            <article key={item.label} className="proofCard">
              <p className="proofLabel">{item.label}</p>
              <p className="proofValue">{item.value}</p>
            </article>
          ))}
        </div>
        <div className="trustMarquee" aria-label="Product strengths">
          <div className="trustTrack">
            {[...trustSignals, ...trustSignals].map((signal, index) => (
              <span key={`${signal}-${index}`}>{signal}</span>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}
