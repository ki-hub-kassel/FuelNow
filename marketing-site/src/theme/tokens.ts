export type Feature = {
  id: string
  eyebrow: string
  title: string
  description: string
  bullets: string[]
  accent: string
  gradient: string
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
    title: 'Finde sofort guenstige Tankstellen in deiner Umgebung',
    description:
      'FuelNow zeigt dir verifizierte Preise auf einer klaren Karte mit fokussierten Pins und schneller Orientierung.',
    bullets: [
      'Status auf einen Blick: geoeffnet oder geschlossen.',
      'Preisfokus im Kartenpin fuer schnelle Entscheidungen.',
      'Saubere Cluster-Aufloesung beim Zoomen.',
    ],
    accent: '#CA9978',
    gradient: 'linear-gradient(160deg, rgba(202,153,120,0.8), rgba(56,91,147,0.45))',
  },
  {
    id: 'search',
    eyebrow: '02 Gebietssuche',
    title: 'Scrolle, verschiebe, entdecke neue Preis-Hotspots',
    description:
      'Mit gezielter Gebietssuche vergleichst du Regionen effizient und findest den besten Stopp entlang deiner Route.',
    bullets: [
      'Optimiert fuer 25 km Datenqualitaet.',
      'Klarer Suchimpuls statt permanentem Neuladen.',
      'Hohe Lesbarkeit auch waehrend Bewegung.',
    ],
    accent: '#DB4E55',
    gradient: 'linear-gradient(160deg, rgba(219,78,85,0.8), rgba(99,68,184,0.4))',
  },
  {
    id: 'detail',
    eyebrow: '03 Detailansicht',
    title: 'Alle relevanten Infos ohne visuelle Unruhe',
    description:
      'Im Detail-Sheet stehen Preis, Distanz und Navigation im Fokus, damit der naechste Tankstopp in Sekunden klar ist.',
    bullets: [
      'Markenfokus im Header fuer Wiedererkennbarkeit.',
      'Bottom-Action fuer direkte Navigation.',
      'Kontraststark und klar strukturiert.',
    ],
    accent: '#BF5E40',
    gradient: 'linear-gradient(160deg, rgba(191,94,64,0.8), rgba(130,61,61,0.45))',
  },
  {
    id: 'plus',
    eyebrow: '04 Plus Experience',
    title: 'Premium Features, reduzierte Ablenkung, schnellere Entscheidungen',
    description:
      'FuelNow Plus setzt auf einen ruhigen, hochwertigen Look und priorisiert Informationen, die dich schneller ans Ziel bringen.',
    bullets: [
      'Elegante, moderne UI mit fokussierten Akzenten.',
      'Schneller Zugriff auf relevante Preisinfos.',
      'Konsistente Experience auf allen Groessen.',
    ],
    accent: '#385B93',
    gradient: 'linear-gradient(160deg, rgba(56,91,147,0.8), rgba(15,86,80,0.45))',
  },
]
