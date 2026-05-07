export type Feature = {
  id: string
  eyebrow: string
  title: string
  description: string
  bullets: string[]
  accent: string
  gradient: string
  screenshot: string
}

export const tokens = {
  color: {
    pageBg: '#000000',
    surfacePrimary: '#0B1F33',
    surfaceSecondary: '#142A42',
    textPrimary: '#F5F7FA',
    textSecondary: '#A8B4C0',
    textTertiary: '#A2ACB6',
    accentBrand: '#48E0D2',
    accentText: '#7DE4D9',
    accentWarm: '#CA9978',
    accentWarmStrong: '#DB4E55',
    accentDeep: '#BF5E40',
    separator: '#6B7989',
    warning: '#CCA738',
  },
  spacing: {
    xs: 8,
    s: 12,
    m: 16,
    l: 24,
    xl: 32,
    xxl: 40,
    section: 52,
    hero: 120,
  },
  radius: {
    none: 0,
    soft: 8.33,
    full: 999,
  },
  shadow: {
    hover: '0 4px 12px rgba(0, 0, 0, 0.3)',
    elevated: '0 8px 24px rgba(0, 0, 0, 0.4)',
  },
  motion: {
    smooth: '360ms',
  },
  container: {
    maxWidth: 1200,
  },
} as const

export const productFeatures: Feature[] = [
  {
    id: 'map',
    eyebrow: '01 Live Karte',
    title: 'Preis-Pins auf der Karte',
    description: 'Live-Daten mit Status direkt in der Kartenansicht.',
    bullets: [],
    accent: '#48E0D2',
    gradient: 'linear-gradient(160deg, rgba(72,224,210,0.72), rgba(56,91,147,0.45))',
    screenshot: '/appshots/map-view.png',
  },
  {
    id: 'search',
    eyebrow: '02 Gebietssuche',
    title: 'Search im Kartenausschnitt',
    description: 'Neuer Kartenausschnitt, gezielter Abruf, klarer Fokus.',
    bullets: [],
    accent: '#7DE4D9',
    gradient: 'linear-gradient(160deg, rgba(125,228,217,0.78), rgba(56,91,147,0.42))',
    screenshot: '/appshots/area-search.png',
  },
  {
    id: 'detail',
    eyebrow: '03 Detailansicht',
    title: 'Detail mit Navigation',
    description: 'Preise, Distanz und direkter Start in Apple Maps.',
    bullets: [],
    accent: '#48E0D2',
    gradient: 'linear-gradient(160deg, rgba(56,91,147,0.84), rgba(72,224,210,0.46))',
    screenshot: '/appshots/station-detail.png',
  },
  {
    id: 'settings',
    eyebrow: '04 Einstellungen & Robustheit',
    title: 'Settings & Offline-Handling',
    description: 'FuelType-Auswahl und robuster Betrieb bei Netzproblemen.',
    bullets: [],
    accent: '#7DE4D9',
    gradient: 'linear-gradient(160deg, rgba(20,42,66,0.92), rgba(72,224,210,0.42))',
    screenshot: '/appshots/settings-plus.png',
  },
]
