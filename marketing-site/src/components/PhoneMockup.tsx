import { AnimatePresence, motion, useReducedMotion } from 'framer-motion'
import type { Feature } from '../theme/tokens'

type PhoneMockupProps = {
  feature: Feature
  index: number
  count: number
}

export function PhoneMockup({ feature, index, count }: PhoneMockupProps) {
  const prefersReducedMotion = useReducedMotion()

  return (
    <motion.div
      className="phoneFrame"
      aria-live="polite"
      animate={
        prefersReducedMotion
          ? undefined
          : {
              y: [0, -6, 0],
            }
      }
      transition={
        prefersReducedMotion
          ? undefined
          : {
              duration: 5.2,
              ease: 'easeInOut',
              repeat: Number.POSITIVE_INFINITY,
            }
      }
    >
      <span
        className="phoneAura"
        aria-hidden="true"
        style={{ background: feature.gradient }}
      />
      <div className="phoneNotch" aria-hidden="true" />
      <div className="phoneScreen">
        <AnimatePresence mode="wait" initial={false}>
          <motion.img
            key={feature.id}
            src={feature.screenshot}
            alt={feature.alt}
            className="phoneScreenShot"
            initial={prefersReducedMotion ? { opacity: 0 } : { opacity: 0, scale: 1.02 }}
            animate={prefersReducedMotion ? { opacity: 1 } : { opacity: 1, scale: 1 }}
            exit={prefersReducedMotion ? { opacity: 0 } : { opacity: 0, scale: 0.99 }}
            transition={{
              duration: prefersReducedMotion ? 0 : 0.55,
              ease: [0.22, 1, 0.36, 1],
            }}
            loading="lazy"
            decoding="async"
          />
        </AnimatePresence>

        <AnimatePresence mode="wait" initial={false}>
          <motion.div
            key={`${feature.id}-overlay`}
            className="phoneOverlay"
            initial={prefersReducedMotion ? { opacity: 0 } : { opacity: 0, y: 12 }}
            animate={prefersReducedMotion ? { opacity: 1 } : { opacity: 1, y: 0 }}
            exit={prefersReducedMotion ? { opacity: 0 } : { opacity: 0, y: -8 }}
            transition={{ duration: prefersReducedMotion ? 0 : 0.45, ease: 'easeOut' }}
          >
            <p className="phoneOverlayEyebrow" style={{ color: feature.accent }}>
              {feature.eyebrow}
            </p>
            <h3 className="phoneOverlayTitle">{feature.title}</h3>
          </motion.div>
        </AnimatePresence>

        <div className="phoneProgress">
          <motion.span
            className="phoneProgressFill"
            animate={{ width: `${((index + 1) / count) * 100}%` }}
            transition={{ duration: prefersReducedMotion ? 0 : 0.5, ease: 'easeOut' }}
          />
        </div>
      </div>
    </motion.div>
  )
}
