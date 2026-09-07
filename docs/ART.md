# Adding artwork

Nothing in `assets/` is required. Every drawable asks `Art` for a texture, and
when there is none it falls back to a hand-drawn placeholder, so the game is
always playable and always looks finished.

When you drop a file in, it appears immediately — no code changes.

## Where files go

```
assets/
  bg/       home.png  mall.png  meadow.png  forest.png  bay.png
  owner/    owner_sheet.png  portrait.png
  pets/     ragdoll_sheet.png  <species_id>.png  <species_id>_<pose>.png
  manifest.json
```

`assets/manifest.json` already lists all of the above. If your filenames match,
there is nothing else to do.

## Backgrounds

Full-bleed scene art, drawn to cover the screen and cropped at the edges. Design
around a 16:9 safe area and keep the interesting part near the middle.

| Key | Scene | Used by |
| --- | --- | --- |
| `bg_home` | apartment / room | Home, Pets, Bag, Daily, Missions, Inbox, Profile |
| `bg_mall` | shopping street | Map, Shop |
| `bg_meadow` | meadow | Friends, meadow rescues |
| `bg_forest` | misty forest | forest rescues |
| `bg_bay` | frost bay | bay rescues |

## Sprite sheets

A sheet is one image on a fixed grid, counted left-to-right then top-to-bottom
starting at 0. Declare the grid once and name the cells:

```json
"ragdoll": {
  "path": "res://assets/pets/ragdoll_sheet.png",
  "cols": 6, "rows": 4,
  "poses": { "idle": 0, "happy": 1, "sleep": 6, "eat": 7, "play": 14 }
}
```

The manifest ships with three sheets already mapped:

- **`owner`** — a 5×3 grid of the player character, saved as
  `assets/owner/owner_sheet.png`. Cell names in reading order:
  `idle, hug, drink, cheer, walk / read, think, sleep, laptop, wink / side,
  camera, pet, point, flowers`.
- **`ragdoll`** — a 6×3 grid of the cat, saved as
  `assets/pets/ragdoll_sheet.png`. Cell names in reading order:
  `idle, happy, walk, peek, wave, away / rest, belly, sleep, dressed, treat,
  curious / eat, box, play, back, love, curl`.
- **`ragdoll_classic`** — a 6×4 grid of the same cat, saved as
  `assets/pets/ragdoll_sheet_classic.png`. Cell names in reading order:
  `idle, happy, walk, peek, wave, away / sleep, eat, belly, dressed, loaf,
  curious / box, curl, play, wink, proud, love / crown, bow, roll, hood, bed,
  back`.

`Art.creature()` looks in `ragdoll` first and falls back to `ragdoll_classic`,
so you can ship either sheet, or both. To make the 6×4 sheet the primary art
instead, swap the two `path` values in the manifest — nothing else changes.

Cells must be evenly sized. Transparent PNG is expected.

When no `bg_home` image is present the game draws a stand-in room — sofa,
window, cat tree and rug, tinted by the decor the player has equipped. Real
background art replaces it entirely, and the interface is laid out to keep the
right-hand panel clear of whatever is behind it.

## Poses the game asks for

| Pose | When |
| --- | --- |
| `idle` | resting state, and the fallback for any unmapped name |
| `happy` | wellbeing above 78, and after a bath |
| `loaf` | wellbeing below 45 |
| `curl` | energy below 35 |
| `eat` | feeding |
| `play` | playing |
| `sleep` | napping |
| `crown` | brushing |
| `curious` | vet visit |
| `peek` | a frightened animal during a rescue or before taming |

An animal only needs `idle` to look right. Add poses as you draw them.

## Single images instead of a sheet

For one animal at a time, skip the manifest entirely:

- `assets/pets/<species_id>.png` — used for every pose
- `assets/pets/<species_id>_<pose>.png` — used for that one pose

Species ids are the keys in `data/species.json`: `ragdoll`, `corgi`,
`lop_bunny`, `hamster`, `pomeranian`, `cockatiel`, `hedgehog`, `duckling`,
`fawn`, `red_panda`, `fennec`, `shiba`, `penguin_chick`, `sea_otter`,
`snow_fox`.

## Adding a whole new animal

1. Add an entry to `data/species.json` (copy an existing one — `name`, `kind`,
   `rarity`, `region`, `body`, `accent`, `traits`, `favorite`, `bio`, `hint`).
2. Add it to a chapter's goals in `data/chapters.json` as
   `{"id": "r_yourid", "type": "rescue", "key": "your_species_id", "text": "…"}`.
3. Drop in art, or let the placeholder draw it. `kind` picks the placeholder
   silhouette: `Bunny` gets long ears, `Bird`/`Duck`/`Penguin` get a beak,
   `Hedgehog` gets spines, anything else gets pointed ears.

No code changes are needed for any of this.

## Customisable characters and other species

The manifest is keyed by id, not by hard-coded paths, so player-chosen owner
appearances slot in as extra sheet keys (`owner_a`, `owner_b`, …) plus a saved
id on `save.owner`. `Art.owner()` is the single place that resolves it.
