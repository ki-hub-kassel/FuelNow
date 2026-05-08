import { motion, useReducedMotion } from 'framer-motion'
import type { ComponentType } from 'react'
import {
  LiveMapIllustration,
  NavigationIllustration,
  OfflineIllustration,
  PriceTickerIllustration,
} from '../components/BentoIllustrations'

type Bento = {
  id: string
  title: string
  body: string
  size: 'wide' | 'tall' | 'square'
  art: 'map' | 'price' | 'nav' | 'offline'
  accent?: string
}

const bentoItems: Bento[] = [
  {
    id: 'map',
    title: 'Karte mit Live-Pins',
    body: 'Tankstellen, Status und Preise auf einer Karte — Cluster-Logik je Zoom, damit nichts flackert.',
    size: 'wide',
    art: 'map',
  },
  {
    id: 'price',
    title: 'Preise im Schilder-Format',
    body: '1,58⁹ — genau wie an der Tankstelle. Mit Voice-Output, der die Zahl wieder natürlich vorliest.',
    size: 'tall',
    art: 'price',
  },
  {
    id: 'nav',
    title: 'Ein Tap zur Navigation',
    body: 'Stationsdetail mit Apple-Maps-Button: Turn-by-turn startet sofort, ohne Umweg.',
    size: 'square',
    art: 'nav',
  },
  {
    id: 'offline',
    title: 'Stabil bei schlechtem Netz',
    body: 'Splash erscheint sanft, sobald die Verbindung wackelt — und blendet sich beim ersten erfolgreichen Refresh wieder aus.',
    size: 'square',
    art: 'offline',
  },
]

const artComponent: Record<Bento['art'], ComponentType> = {
  map: LiveMapIllustration,
  price: PriceTickerIllustration,
  nav: NavigationIllustration,
  offline: OfflineIllustration,
}

export function ValueSection() {
  const prefersReducedMotion = useReducedMotion()

  return (
    <section id="why" className="section bentoSection">
      <div className="container">
        <motion.p
          className="eyebrow"
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-20%' }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        >
          Warum FuelNow
        </motion.p>
        <motion.h2
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 18 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-20%' }}
          transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
        >
          Klar, schnell, robust.
        </motion.h2>

        <div className="bentoGrid">
          {bentoItems.map((item, index) => {
            const Art = artComponent[item.art]
            return (
              <motion.article
                key={item.id}
                className={`bentoCard bento-${item.size}`}
                initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 30 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-12%' }}
                transition={{
                  duration: 0.7,
                  delay: prefersReducedMotion ? 0 : index * 0.08,
                  ease: [0.22, 1, 0.36, 1],
                }}
                whileHover={
                  prefersReducedMotion
                    ? undefined
                    : { y: -6, transition: { duration: 0.3, ease: 'easeOut' } }
                }
              >
                <div className="bentoArtWrapper">
                  <Art />
                </div>
                <div className="bentoCopy">
                  <h3>{item.title}</h3>
                  <p>{item.body}</p>
                </div>
                <span className="bentoCardGlow" aria-hidden="true" />
              </motion.article>
            )
          })}
        </div>
      </div>
    </section>
  )
}
