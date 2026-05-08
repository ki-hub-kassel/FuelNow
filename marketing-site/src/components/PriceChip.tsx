import { motion, useReducedMotion } from 'framer-motion'
import { useEffect, useState } from 'react'

type Sample = {
  brand: string
  fuel: string
  euros: number
  cents: number
  tenth: number
}

const samples: Sample[] = [
  { brand: 'Aral', fuel: 'E10', euros: 1, cents: 58, tenth: 9 },
  { brand: 'Shell', fuel: 'Diesel', euros: 1, cents: 64, tenth: 9 },
  { brand: 'Star', fuel: 'Super', euros: 1, cents: 61, tenth: 9 },
  { brand: 'Esso', fuel: 'E10', euros: 1, cents: 57, tenth: 9 },
  { brand: 'Total', fuel: 'Diesel', euros: 1, cents: 63, tenth: 4 },
]

type PriceChipProps = {
  className?: string
  intervalMs?: number
}

export function PriceChip({ className, intervalMs = 2600 }: PriceChipProps) {
  const prefersReducedMotion = useReducedMotion()
  const [index, setIndex] = useState(0)

  useEffect(() => {
    if (prefersReducedMotion) return
    const id = window.setInterval(() => {
      setIndex((current) => (current + 1) % samples.length)
    }, intervalMs)
    return () => window.clearInterval(id)
  }, [intervalMs, prefersReducedMotion])

  const sample = samples[index]

  return (
    <motion.div
      className={`priceChip ${className ?? ''}`}
      initial={{ opacity: 0, y: 14, scale: 0.96 }}
      animate={{ opacity: 1, y: 0, scale: 1 }}
      transition={{ duration: 0.6, delay: 0.25, ease: [0.22, 1, 0.36, 1] }}
      role="figure"
      aria-label={`Live-Beispiel: ${sample.brand} ${sample.fuel}`}
    >
      <div className="priceChipHeader">
        <span className="priceChipDot" aria-hidden="true" />
        <span className="priceChipBrand">{sample.brand}</span>
        <span className="priceChipFuel">{sample.fuel}</span>
      </div>
      <motion.div
        key={`${sample.brand}-${sample.fuel}-${sample.cents}-${sample.tenth}`}
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, ease: 'easeOut' }}
        className="priceChipValue"
      >
        <span className="priceChipEuros">
          {sample.euros}
          <span className="priceChipComma">,</span>
          {sample.cents.toString().padStart(2, '0')}
        </span>
        <sup className="priceChipTenth">{sample.tenth}</sup>
      </motion.div>
      <p className="priceChipMeta">Live · 2,1 km</p>
    </motion.div>
  )
}
