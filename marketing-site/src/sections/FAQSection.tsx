import { AnimatePresence, motion, useReducedMotion } from 'framer-motion'
import { useState } from 'react'

type FAQItem = {
  q: string
  a: string
}

const faqItems: FAQItem[] = [
  {
    q: 'Welche Daten zeigt FuelNow?',
    a: 'Live-Daten der Tankerkönig API: aktuelle Preise, Öffnungsstatus und Distanz für jede Station im Suchradius (bis 25 km).',
  },
  {
    q: 'Funktioniert die App nur in Deutschland?',
    a: 'Aktuell ja — FuelNow ist auf den deutschen Markt und die Tankerkönig-Datenquelle ausgelegt. Weitere Länder sind möglich, sobald passende offene Datenquellen verfügbar sind.',
  },
  {
    q: 'Wie starte ich die Navigation?',
    a: 'In der Stations-Detailansicht auf den primären Button tippen — FuelNow übergibt direkt an Apple Maps und startet die Turn-by-turn-Navigation.',
  },
  {
    q: 'Ist FuelNow kostenlos?',
    a: 'Die Kernnutzung ist gratis und ohne Account. Plus-Features sind optional und werden über StoreKit angeboten.',
  },
  {
    q: 'Was passiert bei schlechter Verbindung?',
    a: 'Bei Netzproblemen erscheint ein Offline-Splash. Sobald die Verbindung zurück ist, wird automatisch frisch geladen — manuelles Zutun nicht nötig.',
  },
]

export function FAQSection() {
  const prefersReducedMotion = useReducedMotion()
  const [openIndex, setOpenIndex] = useState<number | null>(0)

  return (
    <section id="faq" className="section faqSection">
      <div className="container faqContainer">
        <motion.p
          className="eyebrow"
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 12 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-20%' }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        >
          Häufig gefragt
        </motion.p>
        <motion.h2
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 18 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: '-20%' }}
          transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
        >
          Kurz beantwortet.
        </motion.h2>

        <div className="faqList">
          {faqItems.map((item, index) => {
            const isOpen = openIndex === index
            return (
              <motion.div
                key={item.q}
                className={`faqItem ${isOpen ? 'isOpen' : ''}`}
                initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 16 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-15%' }}
                transition={{
                  duration: 0.55,
                  delay: prefersReducedMotion ? 0 : index * 0.06,
                  ease: [0.22, 1, 0.36, 1],
                }}
              >
                <button
                  className="faqQuestion"
                  type="button"
                  aria-expanded={isOpen}
                  onClick={() => setOpenIndex(isOpen ? null : index)}
                >
                  <span>{item.q}</span>
                  <span className="faqIcon" aria-hidden="true">
                    <motion.span
                      className="faqIconBar faqIconBarH"
                      animate={isOpen ? { scaleX: 1 } : { scaleX: 1 }}
                    />
                    <motion.span
                      className="faqIconBar faqIconBarV"
                      animate={{ scaleY: isOpen ? 0 : 1 }}
                      transition={{ duration: 0.25, ease: 'easeOut' }}
                    />
                  </span>
                </button>
                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      key="content"
                      className="faqAnswer"
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{
                        duration: prefersReducedMotion ? 0 : 0.35,
                        ease: [0.22, 1, 0.36, 1],
                      }}
                    >
                      <p>{item.a}</p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </motion.div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
