import { motion, useReducedMotion } from 'framer-motion'

export function Hero() {
  const prefersReducedMotion = useReducedMotion()

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.15,
      },
    },
  }

  const itemVariants = {
    hidden: { opacity: 0, y: prefersReducedMotion ? 0 : 20 },
    visible: {
      opacity: 1,
      y: 0,
      transition: { duration: 0.6, ease: [0.22, 1, 0.36, 1] },
    },
  }

  return (
    <section id="top" className="section hero">
      <motion.div 
        className="container"
        variants={containerVariants}
        initial="hidden"
        animate="visible"
      >
        <motion.p className="eyebrow" variants={itemVariants}>
          Spritpreise. Schnell gefunden.
        </motion.p>
        <motion.h1 variants={itemVariants}>
          FuelNow zeigt dir die beste Tankstelle in deiner Nähe.
        </motion.h1>
        <motion.p className="lead" variants={itemVariants}>
          Ein klarer Flow für Endnutzer: Karte öffnen, Preis vergleichen, direkt navigieren.
        </motion.p>
        <motion.div className="actions" variants={itemVariants}>
          <motion.a 
            className="button buttonPrimary" 
            href="#features"
            whileHover={prefersReducedMotion ? {} : { scale: 1.02 }}
            whileTap={prefersReducedMotion ? {} : { scale: 0.98 }}
          >
            Features ansehen
          </motion.a>
          <motion.a 
            className="button buttonGhost" 
            href="#release"
            whileHover={prefersReducedMotion ? {} : { scale: 1.02 }}
            whileTap={prefersReducedMotion ? {} : { scale: 0.98 }}
          >
            Release-Status
          </motion.a>
        </motion.div>
      </motion.div>
    </section>
  )
}