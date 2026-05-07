# FuelNow Marketing Site

High-impact product landing page built with React, Vite and TypeScript.
The page follows a dark premium visual system and includes a scroll-driven iPhone
feature walkthrough.

## Stack

- React 19
- Vite 7
- TypeScript 5

## Run locally

```bash
npm install
npm run dev
```

The app is then available under the local Vite URL shown in the terminal.

## Build

```bash
npm run build
npm run preview
```

## Structure

- `src/theme/tokens.ts`: design token mapping and feature content data
- `src/theme/global.css`: global styles, typography, spacing, responsive behavior
- `src/components/PhoneMockup.tsx`: rendered iPhone shell and animated screen
- `src/components/ScrollFeatureTimeline.tsx`: scroll-synced timeline interaction
- `src/sections/*`: hero, feature showcase, value section, and CTA section

## Design notes

- Dark background with high-contrast typography by default
- Accent colors used mainly for interactivity and emphasis
- 8px-based spacing rhythm
- Mobile fallback for the feature walkthrough without sticky complexity
- Reduced-motion support via `prefers-reduced-motion`
