import { motion, useReducedMotion } from 'framer-motion'

const repeatProps = {
  repeat: Number.POSITIVE_INFINITY,
  ease: 'easeInOut',
} as const

export function LiveMapIllustration() {
  const prefersReducedMotion = useReducedMotion()
  const ringAnim = prefersReducedMotion
    ? undefined
    : { scale: [0.6, 1.6, 0.6], opacity: [0.6, 0, 0.6] }

  return (
    <div className="bentoArt bentoArtMap" aria-hidden="true">
      <svg viewBox="0 0 200 140" preserveAspectRatio="xMidYMid slice">
        <defs>
          <linearGradient id="bentoMapBg" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#0e2a44" />
            <stop offset="100%" stopColor="#091a2a" />
          </linearGradient>
        </defs>
        <rect width="200" height="140" fill="url(#bentoMapBg)" />
        <g stroke="rgba(125, 228, 217, 0.16)" strokeWidth="0.6" fill="none">
          <path d="M0 30 L200 60" />
          <path d="M0 70 L200 40" />
          <path d="M40 0 L80 140" />
          <path d="M120 0 L160 140" />
        </g>
      </svg>

      {[
        { id: 'a', cx: '24%', cy: '40%', delay: 0 },
        { id: 'b', cx: '58%', cy: '32%', delay: 0.6 },
        { id: 'c', cx: '76%', cy: '64%', delay: 1.2 },
        { id: 'd', cx: '38%', cy: '72%', delay: 1.8 },
      ].map((p) => (
        <span key={p.id} className="bentoMapPin" style={{ left: p.cx, top: p.cy }}>
          <motion.span
            className="bentoMapPinRing"
            initial={{ scale: 0.6, opacity: 0 }}
            animate={ringAnim}
            transition={{ duration: 2.4, delay: p.delay, ...repeatProps }}
          />
          <span className="bentoMapPinDot" />
        </span>
      ))}
    </div>
  )
}

export function PriceTickerIllustration() {
  const prefersReducedMotion = useReducedMotion()
  const bars = [56, 72, 48, 64, 80, 58, 90, 70]

  return (
    <div className="bentoArt bentoArtPrice" aria-hidden="true">
      <div className="bentoPriceLine">
        <span className="bentoPriceMain">
          1<span className="bentoPriceComma">,</span>58
          <sup>9</sup>
        </span>
        <motion.span
          className="bentoPriceTrend"
          initial={{ rotate: 0 }}
          animate={prefersReducedMotion ? undefined : { rotate: [0, -10, 0, 10, 0] }}
          transition={{ duration: 4.5, ...repeatProps }}
        >
          ▲
        </motion.span>
      </div>
      <div className="bentoPriceBars">
        {bars.map((h, i) => (
          <motion.span
            key={i}
            className="bentoPriceBar"
            style={{ height: `${h}%` }}
            initial={{ scaleY: 0.3 }}
            animate={
              prefersReducedMotion
                ? { scaleY: 1 }
                : { scaleY: [0.4, 1, 0.6, 1, 0.5] }
            }
            transition={{
              duration: 3.6,
              delay: i * 0.18,
              ...repeatProps,
            }}
          />
        ))}
      </div>
      <div className="bentoPriceLabels">
        <span>E10</span>
        <span>Diesel</span>
        <span>Super</span>
      </div>
    </div>
  )
}

export function NavigationIllustration() {
  const prefersReducedMotion = useReducedMotion()

  return (
    <div className="bentoArt bentoArtNav" aria-hidden="true">
      <svg viewBox="0 0 200 140" preserveAspectRatio="xMidYMid meet">
        <defs>
          <linearGradient id="bentoNavRoute" x1="0" y1="1" x2="1" y2="0">
            <stop offset="0%" stopColor="#48E0D2" />
            <stop offset="100%" stopColor="#7DE4D9" />
          </linearGradient>
        </defs>
        <motion.path
          d="M 16 120 C 50 90, 70 70, 100 80 S 160 50, 184 18"
          fill="none"
          stroke="url(#bentoNavRoute)"
          strokeWidth="3"
          strokeLinecap="round"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: 1 }}
          transition={{
            duration: prefersReducedMotion ? 0 : 2.6,
            ease: 'easeInOut',
            ...(prefersReducedMotion ? {} : repeatProps),
            repeatType: 'reverse',
          }}
        />
        <circle cx="16" cy="120" r="5" fill="#7DE4D9" />
        <circle cx="184" cy="18" r="6" fill="#48E0D2" />
      </svg>
      <motion.span
        className="bentoNavBadge"
        initial={{ y: 0 }}
        animate={prefersReducedMotion ? undefined : { y: [0, -4, 0] }}
        transition={{ duration: 2.4, ...repeatProps }}
      >
        <span className="bentoNavBadgeArrow">↑</span>
        <span>
          <strong>2,1 km</strong>
          <small>in 4 min</small>
        </span>
      </motion.span>
    </div>
  )
}

export function OfflineIllustration() {
  const prefersReducedMotion = useReducedMotion()
  const dots = [0, 0.18, 0.36]

  return (
    <div className="bentoArt bentoArtOffline" aria-hidden="true">
      <div className="bentoOfflineCard">
        <div className="bentoOfflineGlyph">
          <motion.span
            initial={{ opacity: 0.5 }}
            animate={
              prefersReducedMotion
                ? { opacity: 1 }
                : { opacity: [0.4, 1, 0.4], scale: [0.96, 1.04, 0.96] }
            }
            transition={{ duration: 2.4, ...repeatProps }}
          >
            ⚡
          </motion.span>
        </div>
        <div className="bentoOfflineTitle">Verbindung wieder da</div>
        <div className="bentoOfflineDots">
          {dots.map((delay, i) => (
            <motion.span
              key={i}
              className="bentoOfflineDot"
              animate={
                prefersReducedMotion
                  ? { opacity: 1 }
                  : { opacity: [0.3, 1, 0.3], y: [0, -4, 0] }
              }
              transition={{ duration: 1.4, delay, ...repeatProps }}
            />
          ))}
        </div>
      </div>
    </div>
  )
}
