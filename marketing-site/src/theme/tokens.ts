export type Feature = {
  id: string
  eyebrow: string
  title: string
  description: string
  bullets: string[]
  accent: string
  gradient: string
  screenshot: string
  alt: string
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
    section: 96,
    hero: 96,
  },
  radius: {
    none: 0,
    soft: 14,
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
    maxWidth: 1240,
  },
} as const

export const productFeatures: Feature[] = [
  {
    id: 'map',
    eyebrow: '01 · Live-Karte',
    title: 'Preise direkt am Pin',
    description:
      'Tankstellen mit aktuellem Preis, Status und Cluster-Logik je Zoomstufe — eine Karte, die den schnellsten Vergleich zeigt.',
    bullets: ['Zoom-Cluster', 'Geöffnet/geschlossen', 'Schilder-Preisformat'],
    accent: '#48E0D2',
    gradient: 'linear-gradient(160deg, rgba(72,224,210,0.72), rgba(56,91,147,0.45))',
    screenshot: '/appshots/map-view.png',
    alt: 'FuelNow Kartenansicht mit Preis-Pins',
  },
  {
    id: 'search',
    eyebrow: '02 · Gebietssuche',
    title: '„In diesem Gebiet suchen“',
    description:
      'Karte verschoben? Ein Tap auf den Glas-Chip lädt Stationen für den neuen Ausschnitt — gezielt, ohne Auto-Refresh-Spam.',
    bullets: ['Manueller Refresh', 'API-konform', 'Spar an Requests'],
    accent: '#7DE4D9',
    gradient: 'linear-gradient(160deg, rgba(125,228,217,0.78), rgba(56,91,147,0.42))',
    screenshot: '/appshots/area-search.png',
    alt: 'FuelNow Suche im aktuellen Kartengebiet',
  },
  {
    id: 'detail',
    eyebrow: '03 · Detailansicht',
    title: 'Detail mit Navigation',
    description:
      'Marke, Status, Distanz, alle Sorten im Schilder-Format — und ein fixer Apple-Maps-Button für direkte Turn-by-turn-Navigation.',
    bullets: ['Marke als Toolbar', 'Status-Punkt', 'Apple-Maps-Start'],
    accent: '#48E0D2',
    gradient: 'linear-gradient(160deg, rgba(56,91,147,0.84), rgba(72,224,210,0.46))',
    screenshot: '/appshots/station-detail.png',
    alt: 'FuelNow Stationsdetail mit Preisen und Navigation',
  },
  {
    id: 'settings',
    eyebrow: '04 · Robust & persönlich',
    title: 'FuelType & Offline-Modus',
    description:
      'Wähl deinen Standard-Sprit. Verbindung weg? Splash blendet sanft ein und löst beim ersten erfolgreichen Refresh wieder aus.',
    bullets: ['FuelType-Auswahl', 'Offline-Splash', 'Auto-Recover'],
    accent: '#7DE4D9',
    gradient: 'linear-gradient(160deg, rgba(20,42,66,0.92), rgba(72,224,210,0.42))',
    screenshot: '/appshots/settings-sheet.png',
    alt: 'FuelNow Einstellungen mit FuelType-Auswahl',
  },
]
