import { motion, useReducedMotion } from 'framer-motion'
import { AnimatedCounter } from '../components/AnimatedCounter'

const stats = [
  { value: 16000, suffix: '+', label: 'Tankstellen Live abrufbar', sub: 'via Tankerkönig API' },
  { value: 5, suffix: ' min', label: 'Datenfrische', sub: 'aktualisiert dauernd' },
  { value: 0, suffix: ' €', label: 'Abo-Pflicht', sub: 'kein Account nötig' },
  { value: 25, suffix: ' km', label: 'Suchradius', sub: 'API-Maximum' },
]

const marqueeItems = [
  'Live-Karte',
  'E10',
  'Diesel',
  'Super',
  'Cluster · Pins',
  'Apple Maps',
  'Turn-by-turn',
  'Offline-Splash',
  'Schilder-Format',
  'Voice-Output',
  'CarPlay-bereit',
  'iOS 26+',
]

export function ProofSection() {
  const prefersReducedMotion = useReducedMotion()

  return (
    <section id="proof" className="section proofSection" aria-labelledby="proof-heading">
      <div className="container proofContainer">
        <motion.p
          className="eyebrow"
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-20%' }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        >
          Verifizierbare Produktbasis
        </motion.p>
        <motion.h2
          id="proof-heading"
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 18 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-20%' }}
          transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
        >
          Echte Daten. Klare Zahlen. Kein Marketing-Blabla.
        </motion.h2>

        <div className="proofGrid">
          {stats.map((stat, index) => (
            <motion.article
              key={stat.label}
              className="proofCard"
              initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: '-15%' }}
              transition={{
                duration: 0.6,
                delay: prefersReducedMotion ? 0 : index * 0.08,
                ease: [0.22, 1, 0.36, 1],
              }}
              whileHover={
                prefersReducedMotion
                  ? undefined
                  : { y: -4, transition: { duration: 0.25, ease: 'easeOut' } }
              }
            >
              <p className="proofValue">
                <AnimatedCounter to={stat.value} suffix={stat.suffix} />
              </p>
              <p className="proofLabel">{stat.label}</p>
              <p className="proofSub">{stat.sub}</p>
              <span className="proofGlow" aria-hidden="true" />
            </motion.article>
          ))}
        </div>
      </div>

      <div className="marqueeContainer" aria-hidden="true">
        <div className={`marqueeTrack${prefersReducedMotion ? ' isStill' : ''}`}>
          {[...marqueeItems, ...marqueeItems].map((item, i) => (
            <span key={`${item}-${i}`} className="marqueeItem">
              <span className="marqueeDot" /> {item}
            </span>
          ))}
        </div>
      </div>
    </section>
  )
}
