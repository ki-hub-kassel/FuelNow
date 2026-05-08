import { motion, useReducedMotion } from 'framer-motion'

const faqItems = [
  {
    question: 'Welche Daten zeigt FuelNow?',
    answer: 'Aktuelle Kraftstoffpreise, Öffnungsstatus und Distanz zur Station.',
  },
  {
    question: 'Funktioniert die App nur in Deutschland?',
    answer: 'Aktuell ist FuelNow auf den deutschen Markt und Tankerkönig-Daten ausgelegt.',
  },
  {
    question: 'Wie starte ich die Navigation?',
    answer: 'In der Stations-Detailansicht tippen und direkt in Apple Maps starten.',
  },
]

export function FAQ() {
  const prefersReducedMotion = useReducedMotion()

  return (
    <section id="faq" className="section">
      <div className="container">
        <motion.h2
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        >
          FAQ
        </motion.h2>
        <div className="faqList">
          {faqItems.map((item, i) => (
            <motion.details 
              key={item.question}
              initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.4, delay: prefersReducedMotion ? 0 : i * 0.1, ease: [0.22, 1, 0.36, 1] }}
            >
              <summary>{item.question}</summary>
              <p>{item.answer}</p>
            </motion.details>
          ))}
        </div>
      </div>
    </section>
  )
}