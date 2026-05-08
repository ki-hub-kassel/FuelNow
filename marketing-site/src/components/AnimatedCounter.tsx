import { animate, useInView, useReducedMotion } from 'framer-motion'
import { useEffect, useRef, useState } from 'react'

type AnimatedCounterProps = {
  to: number
  durationSeconds?: number
  suffix?: string
  prefix?: string
  decimals?: number
  locale?: string
}

export function AnimatedCounter({
  to,
  durationSeconds = 1.6,
  suffix = '',
  prefix = '',
  decimals = 0,
  locale = 'de-DE',
}: AnimatedCounterProps) {
  const ref = useRef<HTMLSpanElement | null>(null)
  const inView = useInView(ref, { once: true, margin: '-15% 0px' })
  const prefersReducedMotion = useReducedMotion()
  const [value, setValue] = useState(0)

  useEffect(() => {
    if (!inView) return
    const controls = animate(0, to, {
      duration: prefersReducedMotion ? 0 : durationSeconds,
      ease: [0.16, 1, 0.3, 1],
      onUpdate: (latest) => setValue(latest),
    })
    return () => controls.stop()
  }, [inView, to, durationSeconds, prefersReducedMotion])

  const formatted = value.toLocaleString(locale, {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  })

  return (
    <span ref={ref} className="counterValue">
      {prefix}
      {formatted}
      {suffix}
    </span>
  )
}
