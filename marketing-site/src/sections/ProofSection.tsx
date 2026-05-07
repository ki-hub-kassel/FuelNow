const proofStats = [
  { label: 'Datenquelle', value: 'Tankerkönig API (Live-Default)' },
  { label: 'Kartendarstellung', value: 'Zoom-abhaengige Cluster + Pins' },
  { label: 'Navigation', value: 'Turn-by-turn in Apple Maps' },
]

const trustSignals = [
  'Gebietssuche mit Search-Chip',
  'Offline-Splash bei Verbindungsproblemen',
  'FuelType Auswahl in Einstellungen',
  'Preisformat im Schilder-Stil',
]

export function ProofSection() {
  return (
    <section className="section proofSection" aria-labelledby="proof-heading">
      <div className="container">
        <p className="eyebrow">Verifizierbare Produktbasis</p>
        <h2 id="proof-heading">Das kann FuelNow heute.</h2>
        <div className="proofGrid">
          {proofStats.map((item) => (
            <article key={item.label} className="proofCard">
              <p className="proofLabel">{item.label}</p>
              <p className="proofValue">{item.value}</p>
            </article>
          ))}
        </div>
        <div className="trustPills" aria-label="Product strengths">
          {trustSignals.map((signal) => (
            <span key={signal}>{signal}</span>
          ))}
        </div>
      </div>
    </section>
  )
}
