import { motion, useReducedMotion } from 'framer-motion'
import { MagneticButton } from '../components/MagneticButton'
import { MapPulse } from '../components/MapPulse'
import { PhoneTilt } from '../components/PhoneTilt'
import { PriceChip } from '../components/PriceChip'
import { RotatingWord } from '../components/RotatingWord'

const ROTATING_WORDS = ['schlauer', 'günstiger', 'schneller', 'näher']

const headlineLines: string[][] = [
  ['Tanke', '__rotator__'],
  ['—', 'mit', 'Live-Preisen'],
]

export function HeroSection() {
  const prefersReducedMotion = useReducedMotion()

  let runningIndex = 0

  return (
    <section id="home" className="heroSection section">
      <div className="container heroGrid">
        <div className="heroCopy">
          <motion.p
            className="eyebrow heroEyebrow"
            initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
          >
            <span className="eyebrowDot" aria-hidden="true" />
            Live-Daten · Tankerkönig API · iPhone &amp; CarPlay-bereit
          </motion.p>

          <h1 className="heroHeadline">
            {headlineLines.map((line, lineIndex) => (
              <span key={lineIndex} className="heroLine">
                {line.map((token) => {
                  const i = runningIndex++
                  if (token === '__rotator__') {
                    return (
                      <motion.span
                        key={`rot-${i}`}
                        className="heroWord heroRotatorSlot"
                        initial={{ y: prefersReducedMotion ? 0 : '90%', opacity: 0 }}
                        animate={{ y: '0%', opacity: 1 }}
                        transition={{
                          duration: prefersReducedMotion ? 0 : 0.7,
                          delay: prefersReducedMotion ? 0 : 0.15 + i * 0.07,
                          ease: [0.22, 1, 0.36, 1],
                        }}
                      >
                        <RotatingWord words={ROTATING_WORDS} accent="var(--accent-text)" />
                      </motion.span>
                    )
                  }
                  return (
                    <span key={`w-${i}`} className="heroWord">
                      <motion.span
                        initial={{ y: prefersReducedMotion ? 0 : '90%', opacity: 0 }}
                        animate={{ y: '0%', opacity: 1 }}
                        transition={{
                          duration: prefersReducedMotion ? 0 : 0.7,
                          delay: prefersReducedMotion ? 0 : 0.15 + i * 0.07,
                          ease: [0.22, 1, 0.36, 1],
                        }}
                      >
                        {token}
                      </motion.span>
                    </span>
                  )
                })}
              </span>
            ))}
          </h1>

          <motion.p
            className="heroLead"
            initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.65, ease: [0.22, 1, 0.36, 1] }}
          >
            FuelNow zeigt die nächstgünstige Tankstelle in deiner Nähe — Preise live auf der Karte,
            Detail mit einem Tap, direkter Start in Apple Maps.
          </motion.p>

          <motion.div
            className="buttonRow heroButtons"
            initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 0.85, ease: [0.22, 1, 0.36, 1] }}
          >
            <MagneticButton href="#features" variant="primary">
              Funktionen entdecken
            </MagneticButton>
            <MagneticButton href="#cta" variant="ghost" strength={0.18}>
              Im App Store
              <span className="magBtnArrow" aria-hidden="true">
                →
              </span>
            </MagneticButton>
          </motion.div>

          <motion.dl
            className="heroProof"
            initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay: 1.05, ease: [0.22, 1, 0.36, 1] }}
          >
            <div>
              <dt>Live-Default</dt>
              <dd>Tankerkönig API</dd>
            </div>
            <div>
              <dt>Karte</dt>
              <dd>Cluster &amp; Pins</dd>
            </div>
            <div>
              <dt>Navigation</dt>
              <dd>Apple Maps · Turn-by-turn</dd>
            </div>
          </motion.dl>
        </div>

        <motion.div
          className="heroVisual"
          initial={{
            opacity: 0,
            y: prefersReducedMotion ? 0 : 30,
            scale: prefersReducedMotion ? 1 : 0.96,
          }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          transition={{ duration: 0.9, delay: 0.4, ease: [0.22, 1, 0.36, 1] }}
        >
          <PhoneTilt className="heroPhone">
            <div className="heroPhoneFrame">
              <div className="heroPhoneNotch" />
              <div className="heroPhoneScreen">
                <MapPulse />
                <PriceChip className="heroPriceChip" />
                <motion.div
                  className="heroLocateBadge"
                  initial={{ opacity: 0, x: -8 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ duration: 0.5, delay: 1.4, ease: 'easeOut' }}
                >
                  <span className="heroLocateDot" />
                  Aktueller Standort
                </motion.div>
              </div>
            </div>
          </PhoneTilt>
          <motion.div
            className="heroFloatStat"
            initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.7, delay: 1.2, ease: [0.22, 1, 0.36, 1] }}
          >
            <span className="heroFloatStatValue">−4,3 ¢</span>
            <span className="heroFloatStatLabel">vs. Stadtmittel</span>
          </motion.div>
        </motion.div>

        <motion.a
          href="#proof"
          className="heroScrollCue"
          aria-label="Weiter scrollen"
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.7 }}
          transition={{ duration: 0.8, delay: 1.5 }}
        >
          <motion.span
            className="heroScrollCueLine"
            animate={prefersReducedMotion ? undefined : { y: [0, 12, 0] }}
            transition={{
              duration: 1.8,
              repeat: Number.POSITIVE_INFINITY,
              ease: 'easeInOut',
            }}
          />
          <span>scrollen</span>
        </motion.a>
      </div>
    </section>
  )
}
