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
      <div className="phoneNotch" aria-hidden="true" />
      <div className="phoneScreen" style={{ backgroundImage: feature.gradient }}>
        <div className="screenHeader">
          <span className="screenTime">9:41</span>
          <span className="screenSignal">5G</span>
        </div>
        <AnimatePresence mode="wait" initial={false}>
          <motion.div
            key={feature.id}
            className="screenBody"
            initial={prefersReducedMotion ? undefined : { opacity: 0, y: 18, scale: 0.985 }}
            animate={prefersReducedMotion ? undefined : { opacity: 1, y: 0, scale: 1 }}
            exit={prefersReducedMotion ? undefined : { opacity: 0, y: -14, scale: 0.985 }}
            transition={{
              duration: prefersReducedMotion ? 0 : 0.45,
              ease: [0.22, 1, 0.36, 1],
            }}
          >
            <p className="screenEyebrow">{feature.eyebrow}</p>
            <div className="screenShotWrap">
              <img
                src={feature.screenshot}
                alt={`${feature.title} App Screenshot`}
                width={880}
                height={1850}
                loading="eager"
                fetchPriority="high"
              />
            </div>
            <h3 className="screenTitle">{feature.title}</h3>
          </motion.div>
        </AnimatePresence>
        <div className="screenFooter">
          <div className="progressTrack">
            <motion.span
              animate={{ width: `${((index + 1) / count) * 100}%` }}
              transition={{ duration: prefersReducedMotion ? 0 : 0.5, ease: 'easeOut' }}
            />
          </div>
          <p>
            Schritt {index + 1} von {count}
          </p>
        </div>
      </div>
    </motion.div>
  )
}
