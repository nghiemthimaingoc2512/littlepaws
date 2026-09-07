# Little Paws

A cozy pet-care and animal-rescue game. You raise one pet for the whole
journey, and together you find, tame and re-home every animal you meet.

There is no way to lose. Stats decay toward a comfort floor and stop there,
missions can be retried forever, and progress is only ever added.

Built with **Godot 4.4** and GDScript. Portrait-friendly landscape layout at
1280×720, stretched to fit any screen. Exports to Android, iOS, desktop and web.

## Run it

1. Install [Godot 4.4](https://godotengine.org/download) (standard build, no C#).
2. Open the Godot project manager, click **Import**, pick this folder's
   `project.godot`, then **Run** (F5).

No dependencies, no build step, no asset pipeline. It runs the moment it opens.

## Run the tests

```bash
godot --headless --path . --import                  # first time only
godot --headless --path . res://tests/SmokeTest.tscn # 74 rule checks
```

The smoke test drives a full playthrough — new game, care, growth stages,
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
| Screens | `scenes/screens/*.gd` |
| Shared widgets | `ui/*.gd` |
| Tests | `tests/` |

**Chapters 1–3** are pet care: the first day, growing up, and health and
grooming. **Chapters 4–7** are rescue regions — Cozy Alley, Bloom Meadow,
Misty Forest, Frost Bay — with three animals each.

A rescued animal arrives frightened. You raise its trust in the **Sanctuary**,
then choose which of three people it goes home with. Every match is a happy
ending; a closer one simply pays a little better. Homed animals are recorded in
the **Library** with their story and their person.

**21 badges**, coins and gems, outfits for you, accessories for your pet, and
room decor. Coins come from chapters, rescues and rewarded video; gems come from
badges and forever homes.

## Adding your own art

The game draws hand-made placeholder creatures until real artwork exists, so it
never looks unfinished. Drop your files into `assets/` and describe them in
`assets/manifest.json` — see **[docs/ART.md](docs/ART.md)** for the exact file
names and sprite-sheet grids.

## More

- **[docs/DESIGN.md](docs/DESIGN.md)** — the loops, the pacing, the numbers, and what to build next.
- **[docs/ART.md](docs/ART.md)** — how art is loaded and what to name it.
- **[docs/MONETISATION.md](docs/MONETISATION.md)** — where a real ad SDK and IAP plug in.
