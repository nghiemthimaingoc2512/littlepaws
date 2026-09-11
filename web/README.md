# Little Paws — web

```bash
npm install
npm run dev          # http://localhost:5173
```

| Command | What it does |
| --- | --- |
| `npm run dev` | Development server with hot reload |
| `npm run build` | Production build — one self-contained `dist/index.html` |
| `npm run preview` | Serves the production build on port 4173 |
| `npm test` | Plays the Sprint 1 loop in Chromium |
| `npm run artifact` | Builds, then emits `dist/artifact.html` with the art inlined |

## Layout

| Path | What lives there |
| --- | --- |
| `src/state.js` | The whole save and every rule |
| `src/content.js` | The five pets |
| `src/art.js` | Artwork lookup — the only module that touches images |
| `src/screens/` | One file per screen: onboarding, home, play, park, pets, memories |
| `src/fonts.css` | Baloo 2 + Nunito, inlined so the game needs no network |
| `tests/interaction.test.mjs` | The Definition of Done, checked in a browser |

## Artwork

Every character, pet and background is the uploaded artwork in `../assets`,
processed into `public/art` by `tools/prepare_art.py`.

```bash
pip install pillow numpy scipy
python3 ../tools/prepare_art.py     # after changing anything in ../assets
```

The output is committed, so a normal build and CI need no Python.

## Tests

```bash
npx playwright install chromium   # once
npm run dev &
npm test                          # against the dev server
GAME_URL=http://localhost:4173/ npm test   # against the production build
```

Set `CHROMIUM_PATH` to use a Chromium you already have instead of Playwright's.
