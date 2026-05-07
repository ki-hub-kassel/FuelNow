import type { CSSProperties } from 'react'
import { CTASection } from './sections/CTASection'
import { FeatureShowcaseSection } from './sections/FeatureShowcaseSection'
import { HeroSection } from './sections/HeroSection'
import { ProofSection } from './sections/ProofSection'
import { ValueSection } from './sections/ValueSection'
import { tokens } from './theme/tokens'

function App() {
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
        Skip to content
      </a>
      <div className="atmosphere" aria-hidden="true">
        <span className="orb orbOne" />
        <span className="orb orbTwo" />
        <span className="orb orbThree" />
        <span className="gridVeil" />
      </div>
      <header className="topNav">
        <a className="brandMark" href="#home" aria-label="FuelNow Home">
          FuelNow
        </a>
        <nav className="menuLinks" aria-label="Primary">
          <a href="#features">Features</a>
          <a href="#why">Warum FuelNow</a>
          <a href="#cta">Starten</a>
        </nav>
      </header>

      <main id="main-content">
        <HeroSection />
        <ProofSection />
        <FeatureShowcaseSection />
        <ValueSection />
        <CTASection />
      </main>
    </div>
  )
}

export default App
