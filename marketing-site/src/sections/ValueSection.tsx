const valuePoints = [
  {
    title: 'Preisfokus ohne Ablenkung',
    text: 'Alles im Interface dient genau einem Ziel: den besten Preis sofort sichtbar zu machen.',
  },
  {
    title: 'Momentum statt Zaudern',
    text: 'Die Experience fuehrt den Blick bewusst. Von Karte zu Detail zu Navigation ohne Reibung.',
  },
  {
    title: 'Premium, das Leistung kommuniziert',
    text: 'Dunkle Flaechen, warme Highlights und starke Typografie geben dem Produkt eine klare Haltung.',
  },
]

export function ValueSection() {
  return (
    <section id="why" className="section">
      <div className="container">
        <p className="eyebrow">Positionierung</p>
        <h2>FuelNow wirkt wie ein Upgrade fuer jeden, der regelmaessig tankt.</h2>
        <div className="valueGrid">
          {valuePoints.map((item) => (
            <article key={item.title} className="valueCard">
              <h3>{item.title}</h3>
              <p>{item.text}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  )
}
