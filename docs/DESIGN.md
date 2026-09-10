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

**Find → tame → reunite.** A mission is five rounds of reading what a
frightened animal needs. The animal then waits under Friends at zero trust;
three taming actions raise it to 100; then you work out which of three people
has been waiting for it, using their traits and interests as the clue. A wrong
guess costs nothing at all — the animal simply waits — so the puzzle has a right
answer without having a punishment. This is the emotional payoff and the reason
the collection is worth filling.

**Activities.** Three tap games with no timer and no failure: you finish when
you finish. They exist so "play with your pet" is something you do rather than
a button you press, and they pay out through the same rewards path as care.

## The screen

The home screen is the room, and the interface floats over it rather than
framing it: player card top-left, the three currencies top-centre, inbox /
camera / settings top-right, four shortcuts down the left, the day's To Do card
on the right, and the navigation plus **Let's Play!** along the bottom.

Care is deliberately not on that screen. Tapping the pet slides up a sheet with
the five meters and the six actions, and the pet moves up so you can still watch
it react. The room stays a place to look at, not a dashboard.

Every red dot answers a question the player would otherwise have to go and check:
a task ready to collect, a badge earned since you last opened Missions, an animal
still out there, a rescue ready to be matched, an unread letter. No dot is
cosmetic, and none of them nag — they disappear by being looked at.

## Economy

| Source | Coins | Gems | Hearts |
| --- | --- | --- | --- |
| Chapter complete | 200 → 1000 | 3 → 12 | — |
| Forever home found | 120 → 240 | 3 → 7 | 1 |
| Badge earned | — | 2 → 20 | — |
| Daily visit | 55 → 145, by streak | 5 every 7th day | — |
| Daily To Do task | 50 → 80 each | 2 for the full list | 1 for the full list |
| Rewarded video | 60 | — | — |

Coins buy food, outfits, accessories and decor. Gems buy the premium cosmetic in
each category. Hearts are the slowest of the three and come only from finishing
a whole day's list or finding an animal its person, which keeps them tied to the
part of the game that matters. Nothing behind a paywall gates progress — every
chapter, animal and badge is reachable without spending or watching anything.

## The daily list

Five tasks, reset at midnight: care three times, play once, change something you
are wearing or the room, sit with a rescue, and have your pet above 80 wellbeing.
They are small enough to finish in one visit and carry no penalty for being
missed — the list simply starts again. The last one is measured live rather than
counted, so it reads as a state of your pet rather than a chore.

## The inbox

Letters are written by the game as things happen: a thank-you note from the
person who adopted a rescue, a badge receipt, a note that an animal is resting in
the sanctuary. Some carry a gift to collect. It is the game's memory of what you
did, and the only place progress is narrated back to you in someone else's voice.

Rewarded video: 90-second cooldown, 12 per day. See
[MONETISATION.md](MONETISATION.md).

## Content

Six animals (your calico plus five to find), six human friends, six chapters,
20 badges, three casual activities, six foods, and four cosmetics in each of
three categories. All of it lives in `data/*.json` — text, balance and new
animals need no code.

The cast comes from the artwork rather than the other way round. `npc.png` is a
page of six people shown with their pets, so the game's collection loop is
built on that: each animal you find has one person who has been waiting for it,
and reuniting the pair is the payoff the picture already depicts.

## Architecture

`GameState` is the only mutable state and the only place rules live. The player's
own level rises from every kind of progress — care, taming, rescues, homes,
badges, chapters — so the header reflects the whole journey rather than one loop. It emits
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
