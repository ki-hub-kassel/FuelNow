import { motion, useReducedMotion } from 'framer-motion'
import { ScrollFeatureTimeline } from '../components/ScrollFeatureTimeline'
import { productFeatures } from '../theme/tokens'

export function FeatureShowcaseSection() {
  const prefersReducedMotion = useReducedMotion()

  return (
    <section id="features" className="section featureSection">
      <div className="container featureHeader">
        <motion.p
          className="eyebrow"
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-20%' }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        >
          Funktions-Walkthrough
        </motion.p>
        <motion.h2
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 18 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-20%' }}
          transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
        >
          Vier Schritte. Ein flüssiger Flow.
        </motion.h2>
        <motion.p
          className="sectionLead"
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-20%' }}
          transition={{ duration: 0.7, delay: 0.1, ease: [0.22, 1, 0.36, 1] }}
        >
          Beim Scrollen wechselt das iPhone live mit. Karte → Gebietssuche → Detail → Einstellungen — so wie es in der App passiert.
        </motion.p>
      </div>

      <div className="container timelineContainer">
        <ScrollFeatureTimeline features={productFeatures} />
      </div>
    </section>
  )
}
