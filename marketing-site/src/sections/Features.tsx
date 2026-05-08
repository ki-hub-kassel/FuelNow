import { motion, useReducedMotion } from 'framer-motion'

const keyBenefits = [
  {
    title: 'Live in deiner Nähe',
    text: 'Tankstellen inklusive Preise direkt auf der Karte.',
  },
  {
    title: 'Schneller zur günstigsten Station',
    text: 'Detailansicht und Apple-Maps-Navigation in einem Schritt.',
  },
  {
    title: 'Stabil bei schlechtem Netz',
    text: 'Offline-Hinweis mit automatischem Wiederanlauf.',
  },
]

export function Features() {
  const prefersReducedMotion = useReducedMotion()

  return (
    <section id="features" className="section">
      <div className="container">
        <motion.h2
          initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-100px" }}
          transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
        >
          Worauf Nutzer sofort achten
        </motion.h2>
        <div className="cardGrid">
          {keyBenefits.map((item, i) => (
            <motion.article 
              key={item.title} 
              className="card"
              initial={{ opacity: 0, y: prefersReducedMotion ? 0 : 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-50px" }}
              transition={{ duration: 0.5, delay: prefersReducedMotion ? 0 : i * 0.1, ease: [0.22, 1, 0.36, 1] }}
              whileHover={prefersReducedMotion ? {} : { y: -4, transition: { duration: 0.2 } }}
            >
              <h3>{item.title}</h3>
              <p>{item.text}</p>
            </motion.article>
          ))}
        </div>
      </div>
    </section>
  )
}