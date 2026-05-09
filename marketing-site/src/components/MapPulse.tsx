import { motion, useReducedMotion } from 'framer-motion'

type Pin = {
  id: string
  top: string
  left: string
  delay: number
  scale?: number
}

const pins: Pin[] = [
  { id: 'pin-1', top: '24%', left: '22%', delay: 0 },
  { id: 'pin-2', top: '38%', left: '60%', delay: 0.6, scale: 1.1 },
  { id: 'pin-3', top: '62%', left: '34%', delay: 1.2 },
  { id: 'pin-4', top: '70%', left: '74%', delay: 1.8, scale: 0.9 },
]

type MapPulseProps = {
  className?: string
}

export function MapPulse({ className }: MapPulseProps) {
  const prefersReducedMotion = useReducedMotion()

  return (
    <div className={`mapPulse ${className ?? ''}`} aria-hidden="true">
      <div className="mapPulseGrid" />
      <svg
        className="mapPulseRoute"
        viewBox="0 0 200 200"
        preserveAspectRatio="none"
      >
        <motion.path
          d="M 18 168 C 60 130, 90 150, 110 110 S 170 60, 188 32"
          fill="none"
          stroke="url(#routeGradient)"
          strokeWidth="2"
          strokeLinecap="round"
          strokeDasharray="6 6"
          initial={{ pathLength: 0, opacity: 0 }}
          animate={{ pathLength: 1, opacity: 0.7 }}
          transition={{ duration: prefersReducedMotion ? 0 : 2.4, ease: 'easeInOut' }}
        />
        <defs>
          <linearGradient id="routeGradient" x1="0" y1="1" x2="1" y2="0">
            <stop offset="0%" stopColor="#48E0D2" />
            <stop offset="100%" stopColor="#7DE4D9" />
          </linearGradient>
        </defs>
      </svg>
      {pins.map((pin) => (
        <span
          key={pin.id}
          className="mapPin"
          style={{ top: pin.top, left: pin.left }}
        >
          <motion.span
            className="mapPinRing"
            initial={{ scale: 0.6, opacity: 0.5 }}
            animate={
              prefersReducedMotion
                ? { opacity: 0.5 }
                : { scale: [0.6, 1.7, 0.6], opacity: [0.5, 0, 0.5] }
            }
            transition={{
              duration: 2.6,
              repeat: Number.POSITIVE_INFINITY,
              ease: 'easeInOut',
              delay: pin.delay,
            }}
          />
          <motion.span
            className="mapPinDot"
            initial={{ scale: 0 }}
            animate={{ scale: pin.scale ?? 1 }}
            transition={{ duration: 0.4, delay: pin.delay * 0.4, ease: [0.22, 1, 0.36, 1] }}
          />
        </span>
      ))}
    </div>
  )
}
