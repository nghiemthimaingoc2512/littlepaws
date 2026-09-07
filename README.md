# Little Paws

A cozy pet-care and animal-rescue game. You raise one pet for the whole
journey, and together you find, tame and re-home every animal you meet.

There is no way to lose. Stats decay toward a comfort floor and stop there,
missions can be retried forever, and progress is only ever added.

Built with **Godot 4.4** and GDScript. Portrait-friendly landscape layout at
1280×720, stretched to fit any screen. Exports to Android, iOS, desktop and web.

## Run it

**In a browser** — the quickest way to play:

```bash
cd web && npm install && npm run dev     # http://localhost:5173
```

**As a native build** — for Android, iOS and desktop:

1. Install [Godot 4.4](https://godotengine.org/download) (standard build, no C#).
2. Open the Godot project manager, click **Import**, pick this folder's
   `project.godot`, then **Run** (F5).

Both targets read the same content from `data/*.json` and follow the same rules;
`web/src/state.js` is a port of `autoload/GameState.gd`. See
[web/README.md](web/README.md) for the web build.

## Run the tests

```bash
cd web && npm run dev &                               # the browser suite needs it running
cd web && npm run test                                # 66 interaction checks in Chromium

godot --headless --path . --import                    # first time only
godot --headless --path . res://tests/SmokeTest.tscn   # 102 rule checks
```

The browser suite plays the game for real: it finishes onboarding, opens and
closes the care sheet, feeds and plays and checks the meters moved, collects a
daily task, visits every tab, buys and wears an accessory, completes a rescue,
tames and re-homes the animal, collects a gift from the inbox, and reloads to
confirm the save survived.

The Godot smoke test drives a full playthrough — new game, care, growth stages,
chapter completion, rescue, taming, homing, purchases, rewarded video, a month
of absence, and a save/load round trip — and exits non-zero if any rule breaks.
CI runs it on every push.

To look at the screens without a device:

```bash
xvfb-run -a godot --path . res://tests/Screenshot.tscn
# PNGs land in the user data dir the script prints
```

## What is in the game

| System | Where |
| --- | --- |
| Save file, every game rule | `autoload/GameState.gd` |
| Content loaded from JSON | `autoload/Data.gd`, `data/*.json` |
| Palette, theme, art loading | `autoload/Art.gd` |
| Floating chrome and routing | `scenes/Main.gd` |
| Screens | `scenes/screens/*.gd` |
| Shared widgets and vector icons | `ui/*.gd` |
| Tests | `tests/` |

The home screen is the room: shortcuts down the left (Daily, Missions, Shop,
Events), the day's To Do list on the right, your pet in the middle. Tapping the
pet — or **Let's Play!** — slides up the care sheet with its meters and the six
care actions. The bottom bar is **Home, Pets, Friends, Map, Bag, Shop**; the top
carries your level, the three currencies, and the inbox, camera and settings.

Red dots are never decorative. Daily lights up when a task is ready to collect,
Missions when a badge was earned since you last looked, Events while an animal
still needs help, Friends when a rescue is ready to be matched, and the inbox
when a letter is unread.

**Chapters 1–3** are pet care: the first day, growing up, and health and
grooming. **Chapters 4–7** are rescue regions — Cozy Alley, Bloom Meadow,
Misty Forest, Frost Bay — with three animals each.

A rescued animal arrives frightened. You raise its trust in the **Sanctuary**,
then choose which of three people it goes home with. Every match is a happy
ending; a closer one simply pays a little better. Homed animals are recorded in
the **Library** with their story and their person.

**21 badges**, three currencies, outfits for you, accessories for your pet, and
room decor. Coins come from chapters, the daily list and rewarded video; gems
come from badges and forever homes; hearts come from clearing the day's list and
from finding an animal its person. None of the three gates a chapter.

A **daily To Do card** asks for five small things — care, play, decorate, meet
friends, be happy — and the **inbox** collects thank-you notes, badge receipts
and gifts as you earn them.

## Adding your own art

The game draws hand-made placeholder creatures until real artwork exists, so it
never looks unfinished. Drop your files into `assets/` and describe them in
`assets/manifest.json` — see **[docs/ART.md](docs/ART.md)** for the exact file
names and sprite-sheet grids.

## More

- **[docs/DESIGN.md](docs/DESIGN.md)** — the loops, the pacing, the numbers, and what to build next.
- **[docs/ART.md](docs/ART.md)** — how art is loaded and what to name it.
- **[docs/MONETISATION.md](docs/MONETISATION.md)** — where a real ad SDK and IAP plug in.
