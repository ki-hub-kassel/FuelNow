import { useEffect, useState } from 'react'

export type LegalRoute = 'home' | 'impressum' | 'datenschutz'

function readLegalRoute(): LegalRoute {
  if (typeof window === 'undefined') return 'home'
  const hash = window.location.hash
  if (hash === '#/impressum') return 'impressum'
  if (hash === '#/datenschutz') return 'datenschutz'
  return 'home'
}

export function useHashRoute(): LegalRoute {
  const [route, setRoute] = useState<LegalRoute>(() => readLegalRoute())

  useEffect(() => {
    const onHashChange = () => setRoute(readLegalRoute())
    window.addEventListener('hashchange', onHashChange)
    return () => window.removeEventListener('hashchange', onHashChange)
  }, [])

  return route
}
