import { motion, useReducedMotion } from 'framer-motion'
import { AnimatedCounter } from '../components/AnimatedCounter'

type Stat = {
  value: number
  suffix: string
  label: string
  sub?: string
}

const stats: Stat[] = [
  { value: 16000, suffix: '+', label: 'Tankstellen Live abrufbar', sub: 'via Tankerkönig API' },
  { value: 5, suffix: ' min', label: 'Datenfrische', sub: 'aktualisiert dauernd' },
  { value: 0, suffix: ' €', label: 'Abo-Pflicht' },
  { value: 25, suffix: ' km', label: 'Suchradius' },
]

const marqueeItems = [
  'Live-Karte',
  'E10',
  'Diesel',
  'Super',
  'Cluster · Pins',
  '„Hier suchen“-Chip',
  'Apple Maps',
  'Turn-by-turn',
  'Siri & Shortcuts',
  'Offline-Splash',
  'Schilder-Format',
  'VoiceOver',
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
              {stat.sub ? <p className="proofSub">{stat.sub}</p> : null}
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
