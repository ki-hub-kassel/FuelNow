# FuelNow Marketing Site

Kompakte Release-Landingpage für FuelNow auf Basis von React + Vite.

## Stack

- React 19
- Vite 8
- TypeScript 6

## Lokal starten

```bash
npm install
npm run dev
```

## Build + Checks

```bash
npm run lint
npm run build
npm run preview
```

## SEO & Release-Basis

- SEO-Meta in `index.html` (Title, Description, OpenGraph, Twitter, Canonical)
- Strukturierte Daten via JSON-LD (`MobileApplication`)
- Favicon + Manifest (`public/favicon.svg`, `public/site.webmanifest`)
- Crawl-Hinweise (`public/robots.txt`, `public/sitemap.xml`)

## Wichtige Dateien

- `src/App.tsx`: Seitenstruktur und Content (Hero, Features, App-Einblick, Release, FAQ)
- `src/theme/site.css`: Styling
- `public/appshots/*`: App-Screenshots
