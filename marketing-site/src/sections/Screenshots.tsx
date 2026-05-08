import { motion, useReducedMotion } from 'framer-motion'

const screenshots = [
  {
    src: '/appshots/map-view.png',
    alt: 'FuelNow Kartenansicht mit Preis-Pins',
    caption: 'Karte mit Live-Preisen',
    loading: 'eager' as const,
  },
  {
    src: '/appshots/station-detail.png',
    alt: 'FuelNow Stationsdetail mit Preisen und Navigation',
    caption: 'Detailansicht mit Navigation',
    loading: 'lazy' as const,
  },
  {
    src: '/appshots/area-search.png',
    alt: 'FuelNow Suche im aktuellen Kartengebiet',
    caption: 'Gezielte Gebietssuche',
    loading: 'lazy' as const,
  },
]

export function Screenshots() {
  const prefersReducedMotion = useReducedMotion()

  return (
    <section className="section">
      <div className="container">
        <motion.h2
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        >
          App-Einblick
        </motion.h2>
        <div className="screenshotGrid">
          {screenshots.map((shot, i) => (
            <motion.figure 
              key={shot.src} 
              className="shotCard"
              initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.6, delay: prefersReducedMotion ? 0 : i * 0.15, ease: [0.22, 1, 0.36, 1] }}
              whileHover={prefersReducedMotion ? {} : { y: -6, transition: { duration: 0.3 } }}
            >
              <img
                src={shot.src}
                alt={shot.alt}
                width={390}
                height={844}
                loading={shot.loading}
                decoding="async"
              />
              <figcaption>{shot.caption}</figcaption>
            </motion.figure>
          ))}
        </div>
      </div>
    </section>
  )
}