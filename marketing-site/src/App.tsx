import type { CSSProperties } from 'react'
import { useEffect } from 'react'
import { motion, useReducedMotion } from 'framer-motion'
import { AmbientField } from './components/AmbientField'
import { ScrollProgress } from './components/ScrollProgress'
import { CTASection } from './sections/CTASection'
import { FAQSection } from './sections/FAQSection'
import { FeatureShowcaseSection } from './sections/FeatureShowcaseSection'
import { HeroSection } from './sections/HeroSection'
import { ProofSection } from './sections/ProofSection'
import { ValueSection } from './sections/ValueSection'
import { tokens } from './theme/tokens'

function App() {
  const prefersReducedMotion = useReducedMotion()

  useEffect(() => {
    document.title = 'FuelNow — Spritpreise live auf der Karte'
  }, [])

  const style = {
    '--bg-primary': tokens.color.pageBg,
    '--bg-surface': tokens.color.surfacePrimary,
    '--bg-surface-alt': tokens.color.surfaceSecondary,
    '--text-primary': tokens.color.textPrimary,
    '--text-secondary': tokens.color.textSecondary,
    '--text-tertiary': tokens.color.textTertiary,
    '--accent-brand': tokens.color.accentBrand,
    '--accent-text': tokens.color.accentText,
    '--accent-warm': tokens.color.accentWarm,
    '--accent-warm-strong': tokens.color.accentWarmStrong,
    '--accent-deep': tokens.color.accentDeep,
    '--separator': tokens.color.separator,
    '--warning': tokens.color.warning,
    '--space-1': `${tokens.spacing.xs}px`,
    '--space-2': `${tokens.spacing.s}px`,
    '--space-3': `${tokens.spacing.m}px`,
    '--space-4': `${tokens.spacing.l}px`,
    '--space-5': `${tokens.spacing.xl}px`,
    '--space-6': `${tokens.spacing.xxl}px`,
    '--section-space': `${tokens.spacing.section}px`,
    '--hero-space': `${tokens.spacing.hero}px`,
    '--radius-0': `${tokens.radius.none}px`,
    '--radius-soft': `${tokens.radius.soft}px`,
    '--shadow-hover': tokens.shadow.hover,
    '--shadow-elevated': tokens.shadow.elevated,
    '--transition-smooth': tokens.motion.smooth,
    '--container-max': `${tokens.container.maxWidth}px`,
  } as CSSProperties

  return (
    <div className="pageShell" style={style}>
      <a className="skipLink" href="#main-content">
        Zum Inhalt springen
      </a>

      <ScrollProgress />
      <AmbientField />

      <motion.header
        className="topNav"
        initial={{ y: prefersReducedMotion ? 0 : -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
      >
        <a className="brandMark" href="#home" aria-label="FuelNow Startseite">
          <span className="brandMarkDot" aria-hidden="true" />
          FuelNow
        </a>
        <nav className="menuLinks" aria-label="Hauptnavigation">
          <a href="#features">Features</a>
          <a href="#why">Warum FuelNow</a>
          <a href="#faq">FAQ</a>
          <a className="menuLinkCta" href="#cta">
            App holen
          </a>
        </nav>
      </motion.header>

      <main id="main-content">
        <HeroSection />
        <ProofSection />
        <FeatureShowcaseSection />
        <ValueSection />
        <FAQSection />
        <CTASection />
      </main>
    </div>
  )
}

export default App
