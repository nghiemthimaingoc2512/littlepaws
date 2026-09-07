# Little Paws — design notes

## The one rule

Nothing can be lost.

- Stats decay toward a **comfort floor of 20** and stop there. A pet left alone
  for a month is hungry and sad, never harmed. The smoke test asserts this.
- Offline decay is capped at **12 hours** no matter how long you were away.
- Rescue missions have no timer and no failure. A wrong answer prints a gentle
  line and the round waits.
- Bond only ever goes up.
- Every homing choice is a happy ending. A closer trait match pays slightly more.

This is the reason the game exists. Anything added later has to keep it true.

## The loops

**Minute to minute — care.** Six actions (`feed, play, bathe, brush, sleep,
heal`) each raise some meters and lower others, grant XP and bond, and go on a
short cooldown. An action is blocked only when *every* meter it would raise is
already full — so you can brush a dirty coat even when your pet is delighted.

**Session to session — growth.** XP thresholds are `Baby 0 / Kid 150 /
Teen 500 / Adult 1200`. A full round of care is roughly 40 XP, and meters have
to fall again before the next round, which paces Adult at a few weeks of real
visits rather than an afternoon of tapping. The pet starts at low meters
(food 45, clean 40, energy 55, mood 50) so the first session has real work in
it and chapter 1 completes in one sitting.

**Chapter to chapter — the journey.** Seven chapters. Chapters 1–3 teach care:
the first day, growing up, health and grooming. Chapters 4–7 are rescue regions
with three animals each, gated behind homing the ones you already saved, so
collecting never outruns caring.

**Rescue → tame → home.** A mission is five rounds of reading what a frightened
animal needs. The animal then enters the Sanctuary at zero trust; three taming
actions raise it to 100; then you pick which of three people it goes home with.
The pair is recorded in the Library with a story. This is the emotional payoff
and the reason the collection is worth filling.

## Economy

| Source | Coins | Gems |
| --- | --- | --- |
| Chapter complete | 200 → 1000 | 3 → 12 |
| Forever home found | 120 → 240 | 3 → 7 |
| Badge earned | — | 2 → 20 |
| Daily visit | 55 → 145, by streak | 5 every 7th day |
| Rewarded video | 60 | — |

Coins buy food, outfits, accessories and decor. Gems buy the premium cosmetic in
each category. Nothing behind a paywall gates progress — every chapter, animal
and badge is reachable without spending or watching anything.

Rewarded video: 90-second cooldown, 12 per day. See
[MONETISATION.md](MONETISATION.md).

## Content

15 species (3 starters, 12 rescues), 7 chapters, 21 badges, 8 adoptable NPCs,
6 foods, and 4 cosmetics in each of three categories. All of it lives in
`data/*.json` — text, balance and new animals need no code.

## Architecture

`GameState` is the only mutable state and the only place rules live. It emits
`changed` when something meaningful happens, and a cheap `ticked` on the decay
timer so meters animate without rebuilding layouts. Screens are plain GDScript
that build their node tree in `build()` and rebuild on `changed`, which makes
state and view impossible to desynchronise. `Art` is the only thing that touches
textures, so real art and placeholders share one code path.

Save is JSON at `user://littlepaws_save.json`, written after every change, with
a `_migrate()` step that back-fills missing keys so old saves survive updates.

## What to build next

1. **Customisable owners and pet skins** — the art manifest is keyed by id
   already; this needs a saved `owner.avatar` and a picker screen.
2. **More species per region**, including the other animals you want players to
   personalise around. Pure JSON work.
3. **Mini-games with texture** — the rescue round is deliberately simple; a
   grooming or feeding mini-game per region would carry chapters 5–7.
4. **Notifications** — "your pet misses you" push, opt-in, capped.
5. **Localisation** — every player-facing string is in `data/*.json` and the
   screen scripts; extracting them into a translation table is mechanical.
6. **Cloud save** — the save is a flat JSON dictionary, so it uploads as-is.
