import { AnimatePresence, motion, useReducedMotion } from 'framer-motion'
import { useEffect, useState } from 'react'

type RotatingWordProps = {
  words: string[]
  intervalMs?: number
  accent?: string
}

export function RotatingWord({ words, intervalMs = 2200, accent }: RotatingWordProps) {
  const prefersReducedMotion = useReducedMotion()
  const [index, setIndex] = useState(0)

  useEffect(() => {
    if (prefersReducedMotion || words.length <= 1) return
    const id = window.setInterval(() => {
      setIndex((current) => (current + 1) % words.length)
    }, intervalMs)
    return () => window.clearInterval(id)
  }, [intervalMs, prefersReducedMotion, words.length])

  const longest = words.reduce((acc, word) => (word.length > acc.length ? word : acc), '')

  return (
    <span className="rotatingWord" style={accent ? { color: accent } : undefined}>
      <span className="rotatingWordSpacer" aria-hidden="true">
        {longest}
      </span>
      <span className="rotatingWordSlot">
        <AnimatePresence mode="wait" initial={false}>
          <motion.span
            key={words[index]}
            className="rotatingWordValue"
            initial={prefersReducedMotion ? { opacity: 0 } : { y: '70%', opacity: 0, rotate: 4 }}
            animate={prefersReducedMotion ? { opacity: 1 } : { y: '0%', opacity: 1, rotate: 0 }}
            exit={prefersReducedMotion ? { opacity: 0 } : { y: '-70%', opacity: 0, rotate: -4 }}
            transition={{ duration: prefersReducedMotion ? 0 : 0.55, ease: [0.22, 1, 0.36, 1] }}
          >
            {words[index]}
          </motion.span>
        </AnimatePresence>
      </span>
    </span>
  )
}
