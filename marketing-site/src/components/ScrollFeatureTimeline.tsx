import { motion, useReducedMotion, useScroll, useTransform } from 'framer-motion'
import { useEffect, useMemo, useRef, useState } from 'react'
import { PhoneMockup } from './PhoneMockup'
import type { Feature } from '../theme/tokens'

type ScrollFeatureTimelineProps = {
  features: Feature[]
}

export function ScrollFeatureTimeline({ features }: ScrollFeatureTimelineProps) {
  const [activeIndex, setActiveIndex] = useState(0)
  const timelineRef = useRef<HTMLDivElement | null>(null)
  const cardRefs = useRef<Array<HTMLElement | null>>([])
  const prefersReducedMotion = useReducedMotion()
  const { scrollYProgress } = useScroll({
    target: timelineRef,
    offset: ['start end', 'end start'],
  })
  const phoneY = useTransform(scrollYProgress, [0, 0.5, 1], [40, 0, -40])
  const phoneRotate = useTransform(scrollYProgress, [0, 0.5, 1], [-1.6, 0, 1.6])

  const safeFeatures = useMemo(() => features.filter(Boolean), [features])

  useEffect(() => {
    if (safeFeatures.length === 0) {
      return undefined
    }

    const onScroll = () => {
      const viewportCenter = window.innerHeight * 0.45
      let nearest = activeIndex
      let smallestDistance = Number.POSITIVE_INFINITY

      cardRefs.current.forEach((card, index) => {
        if (!card) {
          return
        }

        const rect = card.getBoundingClientRect()
        const cardCenter = rect.top + rect.height / 2
        const distance = Math.abs(cardCenter - viewportCenter)

        if (distance < smallestDistance) {
          smallestDistance = distance
          nearest = index
        }
      })

      if (nearest !== activeIndex) {
        setActiveIndex(nearest)
      }
    }

    onScroll()
    window.addEventListener('scroll', onScroll, { passive: true })
    window.addEventListener('resize', onScroll)

    return () => {
      window.removeEventListener('scroll', onScroll)
      window.removeEventListener('resize', onScroll)
    }
  }, [activeIndex, safeFeatures.length])

  if (safeFeatures.length === 0) {
    return null
  }

  return (
    <div className="timelineGrid" ref={timelineRef}>
      <aside className="phoneColumn">
        <motion.div
          className="phoneSticky"
          style={
            prefersReducedMotion
              ? undefined
              : {
                  y: phoneY,
                  rotate: phoneRotate,
                }
          }
        >
          <PhoneMockup
            feature={safeFeatures[activeIndex]}
            index={activeIndex}
            count={safeFeatures.length}
          />
        </motion.div>
      </aside>

      <div className="timelineCards" aria-label="Feature timeline">
        {safeFeatures.map((feature, index) => (
          <motion.article
            key={feature.id}
            className={`featureCard ${index === activeIndex ? 'isActive' : ''}`}
            ref={(node: HTMLElement | null) => {
              cardRefs.current[index] = node
            }}
            aria-current={index === activeIndex ? 'step' : undefined}
            initial={prefersReducedMotion ? undefined : { opacity: 0, y: 24 }}
            whileInView={prefersReducedMotion ? undefined : { opacity: 1, y: 0 }}
            viewport={{ once: true, amount: 0.3 }}
            transition={{ duration: prefersReducedMotion ? 0 : 0.55, ease: [0.22, 1, 0.36, 1] }}
            onClick={() => setActiveIndex(index)}
            onKeyDown={(event) => {
              if (event.key === 'Enter' || event.key === ' ') {
                event.preventDefault()
                setActiveIndex(index)
              }
            }}
            role="button"
            tabIndex={0}
            aria-label={`Schritt ${index + 1}: ${feature.title}`}
          >
            <p className="featureNumber" style={{ color: feature.accent }}>
              0{index + 1}
            </p>
            <h3>{feature.title}</h3>
            <p>{feature.description}</p>
            <ul className="featureBullets">
              {feature.bullets.map((bullet) => (
                <li key={bullet}>
                  <span className="featureBulletDot" style={{ background: feature.accent }} />
                  {bullet}
                </li>
              ))}
            </ul>
          </motion.article>
        ))}
      </div>
    </div>
  )
}
