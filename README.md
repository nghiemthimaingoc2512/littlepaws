# Little Paws

A cozy pet game. You raise one cat, take her out to meet other pets, and watch
them become friends.

**Sprint 1** is one complete loop, polished, rather than many half-built
systems. There are no currencies, no stats, no hunger bars, no quests and no
shop — those are deliberately out of scope.

## Play it

```bash
cd web
npm install
npm run dev          # http://localhost:5173
```

Node 18, 20 or 22+. Landscape — maximise the window.

## The loop

```
Home  →  pet her  →  play one mini-game  →  a treat
      →  the park  →  meet a pet  →  introduce them  →  friends ♥
      →  a memory  →  home
```

Four pets are waiting at the park, so the loop repeats four times before the
collection is full.

## What is in it

| | |
| --- | --- |
| **Home** | Your cat, and three things to do: Pet, Play, Explore |
| **Chase the Ribbon** | One mini-game, forty seconds, no way to lose |
| **Pet Park** | One place to explore, one pet waiting each visit |
| **Friends** | Two pets play, and they are friends. One state, no levels |
| **Pets** | Five slots: yours, the ones you have met, and silhouettes |
| **Memories** | A short list of moments, newest first |

## Layout

| Path | What lives there |
| --- | --- |
| `web/src/state.js` | The whole save and every rule, in about 150 lines |
| `web/src/content.js` | The five pets |
| `web/src/art.js` | Artwork lookup — the only module that touches images |
| `web/src/screens/` | One file per screen |
| `web/tests/interaction.test.mjs` | Plays the loop in a browser and checks the Definition of Done |
| `tools/prepare_art.py` | Turns the uploads in `/assets` into web-ready sprites |

## Artwork

Every character, pet and background is the uploaded artwork in `/assets`.
Nothing is drawn in code. See [docs/ART.md](docs/ART.md).

## Tests

```bash
cd web
npx playwright install chromium   # once
npm run dev &
npm test
```

It plays the whole loop and checks all twelve Definition of Done steps, that no
button is dead, that nothing overflows the 16:9 stage, and that progress
survives a reload.
