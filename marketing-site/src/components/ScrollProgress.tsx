import { motion, useScroll, useSpring } from 'framer-motion'

export function ScrollProgress() {
  const { scrollYProgress } = useScroll()
  const scaleX = useSpring(scrollYProgress, {
    stiffness: 220,
    damping: 32,
    restDelta: 0.001,
  })

  return (
    <motion.div
      className="scrollProgress"
      style={{ scaleX }}
      aria-hidden="true"
    />
  )
}
