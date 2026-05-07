const valuePoints = [
  {
    title: 'Kartenfokus',
    text: 'Preise und Status direkt auf der Karte.',
  },
  {
    title: 'Schneller Flow',
    text: 'Karte, Detail, Navigation in einem kurzen Ablauf.',
  },
  {
    title: 'Robustes Verhalten',
    text: 'Offline-Hinweis bei Netzproblemen mit Auto-Refresh.',
  },
]

export function ValueSection() {
  return (
    <section id="why" className="section">
      <div className="container">
        <p className="eyebrow">Funktionaler Mehrwert</p>
        <h2>Kurz gesagt: klar, schnell, robust.</h2>
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
