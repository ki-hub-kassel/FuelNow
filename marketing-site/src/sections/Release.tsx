import { motion, useReducedMotion } from 'framer-motion'

const releaseChecklist = [
  'Klarer Nutzen + Feature-Highlights für Store und Landing Page',
  'Datenschutz-/Support-Infos direkt erreichbar',
  'App-Store-Call-to-Action inkl. Preview-Screens',
  'Technische SEO-Basis: Meta, OpenGraph, robots, sitemap, schema.org',
]

export function Release() {
  const prefersReducedMotion = useReducedMotion()

  return (
    <section id="release" className="section">
      <motion.div 
        className="container releaseBox"
        initial={{ opacity: 0, scale: prefersReducedMotion ? 1 : 0.95 }}
        whileInView={{ opacity: 1, scale: 1 }}
        viewport={{ once: true, margin: "-100px" }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
      >
        <h2>Release-ready Seite</h2>
        <ul>
          {releaseChecklist.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
        <p className="smallInfo">
          Kontakt: <a href="mailto:hello@fuelnow.app">hello@fuelnow.app</a> · Datenschutz:
          {' '}
          <a href="https://fuelnow.app/privacy" target="_blank" rel="noreferrer">
            fuelnow.app/privacy
          </a>
        </p>
      </motion.div>
    </section>
  )
}