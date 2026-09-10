#!/usr/bin/env python3
"""Turn the uploaded artwork in /assets into web-ready sprites in web/public/art.

The uploads are large composite sheets: the owner poses arrive as a 5x3 grid
flattened onto a transparency checkerboard, and the human friends arrive as one
illustrated page. This slices them, restores alpha, and compresses the
backgrounds, so the game ships the real artwork rather than a redrawing of it.

    pip install pillow numpy scipy
    python3 tools/prepare_art.py
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "assets"
OUT = ROOT / "web" / "public" / "art"

# --- owner pose sheet ------------------------------------------------------
POSE_NAMES = ["idle", "hug", "drink", "cheer", "back",
              "read", "think", "sleep", "laptop", "wink",
              "side", "camera", "pet", "point", "flowers"]

# --- the six human friends, as laid out on npc.png -------------------------
PANEL_X = {"sophie": 16, "emma": 272, "mia": 524, "leo": 776, "noah": 1032, "alex": 1288}
PANEL_TOP, PANEL_W = 126, 236
PANEL_BOTTOM = 610

# Each friend's animal, as (x0, y0, x1, y1). These were measured against the
# panel band starting at PET_BOX_ORIGIN_Y, which is lower than PANEL_TOP (the
# cards are cropped with extra headroom), so the offset is applied explicitly
# rather than being folded into the numbers.
PET_BOX_ORIGIN_Y = 164
PET_HEADS = {
    "kitten_grey": ("sophie", 130, 275, 202, 347),
    "cat_ginger":  ("emma",    52, 352, 132, 432),
    "dog_shiba":   ("leo",     42, 298, 122, 378),
    "cat_white":   ("noah",   168, 222, 228, 282),
    "dog_poodle":  ("alex",   143, 262, 219, 338),
}
# The player's own cat, in coordinates of the finished "pet" pose sprite.
CALICO_HEAD = (180, 134, 276, 230)


def key_checkerboard(img):
    """Restore alpha on a sheet whose transparency was flattened to a checker."""
    rgb = np.asarray(img.convert("RGB")).astype(np.int16)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    neutral = (abs(r - g) < 10) & (abs(g - b) < 10) & (abs(r - b) < 10)
    checker = neutral & (r >= 196)
    lab, _ = ndimage.label(checker)
    edge = set(lab[0, :]) | set(lab[-1, :]) | set(lab[:, 0]) | set(lab[:, -1])
    edge.discard(0)
    background = np.isin(lab, list(edge))
    return Image.fromarray(
        np.dstack([np.asarray(img.convert("RGB")),
                   np.where(background, 0, 255).astype(np.uint8)]), "RGBA"), background


def sprite_boxes(background, size, cols=5, rows=3, min_area=900):
    """Group the sheet's ink into one box per grid cell, decorations included."""
    width, height = size
    solid = ndimage.binary_closing(~background, np.ones((5, 5)))
    lab, count = ndimage.label(solid)
    areas = ndimage.sum(solid, lab, range(1, count + 1))
    cell_w, cell_h = width / cols, height / rows
    boxes = {}
    for index, area in enumerate(areas, start=1):
        if area < min_area:
            continue
        ys, xs = np.where(lab == index)
        key = (min(rows - 1, int(ys.mean() // cell_h)), min(cols - 1, int(xs.mean() // cell_w)))
        box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
        if key in boxes:
            previous = boxes[key]
            box = (min(previous[0], box[0]), min(previous[1], box[1]),
                   max(previous[2], box[2]), max(previous[3], box[3]))
        boxes[key] = box
    return boxes


def save_sprite(img, path, colors=190):
    """Sprites keep their alpha but not their full 32-bit palette: the artwork
    is flat-shaded, so quantising it cuts the payload without a visible change."""
    img = img.convert("RGBA")
    alpha = img.getchannel("A")
    quantised = img.convert("RGB").quantize(colors=colors, method=Image.FASTOCTREE)
    quantised = quantised.convert("RGBA")
    quantised.putalpha(alpha)
    quantised.save(path, optimize=True)


def expand(box, factor=1.28):
    """Grow a box around its centre. Ears sit in the corners of a tight face
    crop, and a circular mask would cut them off, so the box is padded first."""
    x0, y0, x1, y1 = box
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    half_w, half_h = (x1 - x0) * factor / 2, (y1 - y0) * factor / 2
    return (round(cx - half_w), round(cy - half_h), round(cx + half_w), round(cy + half_h))


def circle(img, size=256):
    """A round avatar, so a crop taken from a busy card still reads cleanly."""
    img = img.convert("RGB").resize((size, size), Image.LANCZOS)
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, size - 1, size - 1), fill=255)
    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def build_owner_poses(manifest):
    sheet = Image.open(SRC / "owner" / "owner_pose.png")
    keyed, background = key_checkerboard(sheet)
    boxes = sprite_boxes(background, sheet.size)
    if len(boxes) != 15:
        raise SystemExit(f"expected 15 owner poses, found {len(boxes)}")
    pad = 6
    for (row, col), (x0, y0, x1, y1) in boxes.items():
        name = POSE_NAMES[row * 5 + col]
        crop = keyed.crop((max(0, x0 - pad), max(0, y0 - pad),
                           min(sheet.width, x1 + pad), min(sheet.height, y1 + pad)))
        crop.thumbnail((360, 360), Image.LANCZOS)
        save_sprite(crop, OUT / "owner" / f"{name}.png")
        manifest["owner"][name] = f"/art/owner/{name}.png"
    print(f"  owner poses: {len(boxes)}")


def build_owner_portrait(manifest):
    portrait = Image.open(SRC / "owner" / "owner.png").convert("RGBA")
    portrait = portrait.crop(portrait.getbbox())
    portrait.thumbnail((420, 420), Image.LANCZOS)
    save_sprite(portrait, OUT / "owner" / "portrait.png")
    manifest["owner"]["portrait"] = "/art/owner/portrait.png"
    print(f"  owner portrait: {portrait.size}")


def build_friends(manifest):
    page = Image.open(SRC / "owner" / "npc.png").convert("RGB")
    for name, x in PANEL_X.items():
        card = page.crop((x, PANEL_TOP, x + PANEL_W, PANEL_BOTTOM))
        card.save(OUT / "npc" / f"{name}.jpg", quality=86, optimize=True)
        manifest["npc"][name] = f"/art/npc/{name}.jpg"
    for pet_id, (owner, x0, y0, x1, y1) in PET_HEADS.items():
        x, y = PANEL_X[owner], PET_BOX_ORIGIN_Y
        head = page.crop(expand((x + x0, y + y0, x + x1, y + y1)))
        save_sprite(circle(head), OUT / "pets" / f"{pet_id}.png")
        manifest["pets"][pet_id] = f"/art/pets/{pet_id}.png"
    print(f"  friend cards: {len(PANEL_X)}, pet avatars: {len(PET_HEADS)}")


def build_calico(manifest):
    pose = Image.open(OUT / "owner" / "pet.png").convert("RGBA")
    head = pose.crop(expand(CALICO_HEAD, 1.18))
    flat = Image.new("RGB", head.size, (255, 253, 247))
    flat.paste(head, (0, 0), head)
    save_sprite(circle(flat), OUT / "pets" / "calico.png")
    manifest["pets"]["calico"] = "/art/pets/calico.png"
    print("  player's cat avatar from the 'pet' pose")


def build_backgrounds(manifest):
    scenes = {"room": "bg_room.png", "mall": "bg_mall.png", "park": "bg_amusement.png"}
    for scene, filename in scenes.items():
        img = Image.open(SRC / "bg" / filename).convert("RGB")
        img.thumbnail((1280, 1280), Image.LANCZOS)
        img.save(OUT / "bg" / f"{scene}.jpg", quality=80, optimize=True, progressive=True)
        manifest["bg"][scene] = f"/art/bg/{scene}.jpg"
        print(f"  bg {scene}: {img.size} "
              f"{(OUT / 'bg' / f'{scene}.jpg').stat().st_size // 1024} kB")


def write_godot_manifest(manifest):
    """The Godot build reads the same processed art through assets/manifest.json,
    so both targets show the uploaded artwork rather than one drifting."""
    images = {}
    for scene, url in manifest["bg"].items():
        images[f"bg_{scene}"] = "res://web/public" + url
    for pose, url in manifest["owner"].items():
        images[f"owner_{pose}"] = "res://web/public" + url
    for pet, url in manifest["pets"].items():
        images[f"pet_{pet}"] = "res://web/public" + url
    for person, url in manifest["npc"].items():
        images[f"npc_{person}"] = "res://web/public" + url
    (ROOT / "assets" / "manifest.json").write_text(json.dumps({
        "_comment": "Generated by tools/prepare_art.py from the artwork in /assets. "
                    "Both the Godot build and the web build read the same files.",
        "images": images,
        "sheets": {},
    }, indent=2) + "\n")
    print(f"  godot manifest: {len(images)} images")


def main():
    for folder in ("bg", "owner", "npc", "pets"):
        (OUT / folder).mkdir(parents=True, exist_ok=True)
    manifest = {"owner": {}, "npc": {}, "pets": {}, "bg": {}}
    print("preparing art…")
    build_owner_poses(manifest)
    build_owner_portrait(manifest)
    build_friends(manifest)
    build_calico(manifest)
    build_backgrounds(manifest)
    (OUT / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    write_godot_manifest(manifest)
    total = sum(f.stat().st_size for f in OUT.rglob("*") if f.is_file())
    print(f"done — {total // 1024} kB in {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
