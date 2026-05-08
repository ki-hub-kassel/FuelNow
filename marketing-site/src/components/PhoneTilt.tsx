import {
  motion,
  useMotionValue,
  useReducedMotion,
  useSpring,
  useTransform,
} from 'framer-motion'
import { useRef, type ReactNode } from 'react'

type PhoneTiltProps = {
  children: ReactNode
  className?: string
  /** Maximum tilt in degrees */
  intensity?: number
}

export function PhoneTilt({ children, className, intensity = 8 }: PhoneTiltProps) {
  const prefersReducedMotion = useReducedMotion()
  const ref = useRef<HTMLDivElement | null>(null)
  const x = useMotionValue(0)
  const y = useMotionValue(0)
  const sx = useSpring(x, { stiffness: 180, damping: 18, mass: 0.6 })
  const sy = useSpring(y, { stiffness: 180, damping: 18, mass: 0.6 })
  const rotateY = useTransform(sx, [-0.5, 0.5], [-intensity, intensity])
  const rotateX = useTransform(sy, [-0.5, 0.5], [intensity, -intensity])

  const handleMove = (event: React.MouseEvent<HTMLDivElement>) => {
    if (prefersReducedMotion || !ref.current) return
    const rect = ref.current.getBoundingClientRect()
    const px = (event.clientX - rect.left) / rect.width - 0.5
    const py = (event.clientY - rect.top) / rect.height - 0.5
    x.set(px)
    y.set(py)
  }

  const handleLeave = () => {
    x.set(0)
    y.set(0)
  }

  return (
    <motion.div
      ref={ref}
      className={`phoneTilt ${className ?? ''}`}
      onMouseMove={handleMove}
      onMouseLeave={handleLeave}
      style={prefersReducedMotion ? undefined : { rotateX, rotateY, transformStyle: 'preserve-3d' }}
    >
      {children}
    </motion.div>
  )
}
