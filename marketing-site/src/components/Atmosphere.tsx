import { motion, useReducedMotion } from 'framer-motion'

export function Atmosphere() {
  const prefersReducedMotion = useReducedMotion()

  return (
    <div className="atmosphere" aria-hidden="true">
      <motion.div 
        className="orb orbPrimary"
        animate={prefersReducedMotion ? undefined : {
          scale: [1, 1.1, 1],
          opacity: [0.3, 0.5, 0.3],
        }}
        transition={{
          duration: 8,
          repeat: Number.POSITIVE_INFINITY,
          ease: "easeInOut"
        }}
      />
      <motion.div 
        className="orb orbSecondary"
        animate={prefersReducedMotion ? undefined : {
          scale: [1, 1.2, 1],
          opacity: [0.2, 0.4, 0.2],
        }}
        transition={{
          duration: 10,
          repeat: Number.POSITIVE_INFINITY,
          ease: "easeInOut",
          delay: 1
        }}
      />
      <div className="gridVeil" />
    </div>
  )
}