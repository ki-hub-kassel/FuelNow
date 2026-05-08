import { motion, useReducedMotion } from 'framer-motion'

export function FooterCTA() {
  const prefersReducedMotion = useReducedMotion()

  return (
    <section className="section finalCta">
      <motion.div 
        className="container"
        initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 30 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true, margin: "-100px" }}
        transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
      >
        <h2>FuelNow jetzt entdecken</h2>
        <motion.a
          className="button buttonPrimary"
          href="https://apps.apple.com/"
          target="_blank"
          rel="noreferrer"
          aria-label="FuelNow im App Store ansehen"
          whileHover={prefersReducedMotion ? {} : { scale: 1.05 }}
          whileTap={prefersReducedMotion ? {} : { scale: 0.95 }}
        >
          Im App Store ansehen
        </motion.a>
      </motion.div>
    </section>
  )
}