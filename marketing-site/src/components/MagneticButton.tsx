import {
  motion,
  useMotionValue,
  useReducedMotion,
  useSpring,
  type HTMLMotionProps,
} from 'framer-motion'
import { useRef, type ReactNode } from 'react'

type MagneticButtonProps = Omit<HTMLMotionProps<'a'>, 'children'> & {
  children: ReactNode
  href: string
  variant?: 'primary' | 'ghost' | 'appstore'
  strength?: number
}

export function MagneticButton({
  children,
  href,
  variant = 'primary',
  strength = 0.35,
  className,
  ...rest
}: MagneticButtonProps) {
  const prefersReducedMotion = useReducedMotion()
  const ref = useRef<HTMLAnchorElement | null>(null)
  const x = useMotionValue(0)
  const y = useMotionValue(0)
  const sx = useSpring(x, { stiffness: 280, damping: 22, mass: 0.45 })
  const sy = useSpring(y, { stiffness: 280, damping: 22, mass: 0.45 })

  const handleMove = (event: React.MouseEvent<HTMLAnchorElement>) => {
    if (prefersReducedMotion || !ref.current) return
    const rect = ref.current.getBoundingClientRect()
    const dx = event.clientX - (rect.left + rect.width / 2)
    const dy = event.clientY - (rect.top + rect.height / 2)
    x.set(dx * strength)
    y.set(dy * strength)
  }

  const handleLeave = () => {
    x.set(0)
    y.set(0)
  }

  const variantClass =
    variant === 'primary' ? 'magBtn magBtnPrimary' : variant === 'ghost' ? 'magBtn magBtnGhost' : 'magBtn magBtnAppStore'

  return (
    <motion.a
      ref={ref}
      href={href}
      className={`${variantClass}${className ? ` ${className}` : ''}`}
      onMouseMove={handleMove}
      onMouseLeave={handleLeave}
      style={prefersReducedMotion ? undefined : { x: sx, y: sy }}
      whileTap={prefersReducedMotion ? undefined : { scale: 0.97 }}
      {...rest}
    >
      <span className="magBtnInner">{children}</span>
      {variant === 'primary' && <span className="magBtnShimmer" aria-hidden="true" />}
    </motion.a>
  )
}
