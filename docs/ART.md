# Artwork

All character, pet and scene art in Little Paws is the uploaded artwork in
`/assets`. Nothing is drawn in code. If a piece is missing the game shows a
neutral placeholder rather than a redrawing of the subject.

## What was uploaded

| File | What it is |
| --- | --- |
| `assets/owner/owner.png` | The player character, single portrait, real alpha |
| `assets/owner/owner_pose.png` | The player character, 5×3 grid of 15 poses |
| `assets/owner/npc.png` | "Our Human Friends" — one page with six characters and their pets |
| `assets/bg/bg_room.png` | The apartment, used for the home screen |
| `assets/bg/bg_mall.png` | The Paw & Co. shopping arcade |
| `assets/bg/bg_amusement.png` | Little Paws Park |

Two things about these files shape the pipeline:

- `owner_pose.png` and `npc.png` are **flattened RGB**. The pose sheet's
  transparency was baked in as a grey checkerboard, so alpha has to be
  restored before the sprites are usable.
- The sprites on the pose sheet are **not aligned to an exact 5×3 grid**.
  Slicing by arithmetic clips them, so each sprite's real bounding box is
  detected instead.

## The pipeline

```bash
pip install pillow numpy scipy
python3 tools/prepare_art.py
```

It reads `/assets` and writes `web/public/art`, plus `assets/manifest.json` for
the Godot build, so both targets read the same processed files. Roughly 13 MB of
source becomes about 2.3 MB of sprites.

What it does:

1. **Restores alpha** on the pose sheet by flood-filling the grey checkerboard
   inward from the edges, which keeps genuinely white pixels inside the artwork.
2. **Finds each sprite** by connected components, then groups the components
   into grid cells so a pose keeps its own hearts, "zzz" and "?" marks.
3. **Crops the six friend cards** out of the character page.
4. **Cuts a round avatar** for each animal. The boxes are padded before the
   circular mask, because ears sit in the corners of a tight face crop.
5. **Compresses the backgrounds** to 1280px JPEG and quantises the sprites,
   which keeps their alpha but drops the payload.

Re-run it after changing anything in `/assets`. The output is committed, so a
normal build and CI need no Python.

## How the game asks for art

`web/src/art.js` is the only module that touches images:

| Call | Returns |
| --- | --- |
| `ownerNode(pose)` | The player character in one of 15 poses |
| `petNode(speciesId)` | An animal's round avatar |
| `friendNode(npcId)` | One of the six friend cards |
| `sceneUrl(scene)` | A background: `room`, `mall` or `park` |

The pose the game shows is chosen by what is happening, not fixed: `carePose()`
maps each care action to a pose, and `moodPose()` maps how your cat is feeling.

## Adding more art

Drop the file into the matching folder under `/assets`, add its crop to
`tools/prepare_art.py`, and re-run it. Adding a species is a `data/species.json`
entry plus one avatar under `web/public/art/pets/` named after the species id.

## The player's cat

No standalone pet artwork was uploaded. The player's calico appears in two of
the owner poses (`hug` and `pet`), so the home screen shows the real pose art of
the pair, and her avatar is a round crop of her face from the `pet` pose. The
five rescuable animals are cropped from the friends page the same way.
