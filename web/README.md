# Little Paws — web build

The playable build. Open it in a browser, no engine required.

```bash
cd web
npm install
npm run dev          # http://localhost:5173
```

| Command | What it does |
| --- | --- |
| `npm run dev` | Development server with hot reload |
| `npm run build` | Production build — one self-contained `dist/index.html` |
| `npm run preview` | Serves the production build on port 4173 |
| `npm run test` | Drives the running game in Chromium and asserts it is interactive |
| `npm run artifact` | Builds, then emits `dist/artifact.html` for publishing |

## Layout

| Path | What lives there |
| --- | --- |
| `src/state.js` | Every game rule and the save file. Ported from the Godot build's `GameState.gd`, so both behave identically. |
| `src/data.js` | Loads `../data/*.json` — the same content files the Godot build reads. One source of truth. |
| `src/art.js` | Looks up the uploaded artwork. The only module that touches images. |
| `src/icons.js` | The icon set, inline SVG. |
| `src/screens/` | One file per screen. Each builds its DOM and is rebuilt when the save changes. |
| `src/screens/minigame.js` | The tap-game engine behind the three activities. |
| `tests/interaction.test.mjs` | 77 checks driven through a real browser. |

## Artwork

Every character, pet and background is the uploaded artwork in `/assets`,
processed into `web/public/art` by `tools/prepare_art.py`. Nothing is drawn in
code. `src/art.js` is the only module that touches images.

```bash
pip install pillow numpy scipy
python3 tools/prepare_art.py     # after changing anything in /assets
```

The output is committed, so a normal build and CI need no Python. See
[../docs/ART.md](../docs/ART.md) for what the pipeline does and why.

## Testing

The interaction suite starts nothing itself — run the dev server first:

```bash
npm run dev &
npm run test                      # against the dev server
GAME_URL=http://localhost:4173/ npm run test   # against the production build
```

It plays the game: finishes onboarding, opens and closes the care sheet, feeds
and plays and checks the meters and counters moved, ticks off a daily task and
collects it, visits all six tabs and all four shortcuts, buys and wears an
accessory, completes a rescue mission, tames and re-homes the animal, collects
a gift from the inbox, and reloads to confirm the save survived.
