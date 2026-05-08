import { motion, useReducedMotion } from 'framer-motion'

export function AmbientField() {
  const prefersReducedMotion = useReducedMotion()

  return (
    <div className="atmosphere" aria-hidden="true">
      <motion.span
        className="orb orbOne"
        animate={
          prefersReducedMotion
            ? undefined
            : {
                x: [0, 40, -10, 0],
                y: [0, -30, 20, 0],
                scale: [1, 1.08, 0.96, 1],
              }
        }
        transition={
          prefersReducedMotion
            ? undefined
            : {
                duration: 22,
                repeat: Number.POSITIVE_INFINITY,
                ease: 'easeInOut',
              }
        }
      />
      <motion.span
        className="orb orbTwo"
        animate={
          prefersReducedMotion
            ? undefined
            : {
                x: [0, -50, 30, 0],
                y: [0, 30, -20, 0],
                scale: [1, 0.94, 1.1, 1],
              }
        }
        transition={
          prefersReducedMotion
            ? undefined
            : {
                duration: 26,
                repeat: Number.POSITIVE_INFINITY,
                ease: 'easeInOut',
                delay: 1.5,
              }
        }
      />
      <motion.span
        className="orb orbThree"
        animate={
          prefersReducedMotion
            ? undefined
            : {
                x: [0, 30, -20, 0],
                y: [0, -40, 10, 0],
                scale: [1, 1.05, 0.97, 1],
              }
        }
        transition={
          prefersReducedMotion
            ? undefined
            : {
                duration: 30,
                repeat: Number.POSITIVE_INFINITY,
                ease: 'easeInOut',
                delay: 3,
              }
        }
      />
      <span className="gridVeil" />
      <span className="noiseVeil" />
    </div>
  )
}
