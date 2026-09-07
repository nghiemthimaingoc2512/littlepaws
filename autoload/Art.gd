extends Node
## Palette, shared theme, and art loading.
##
## Every drawable in Little Paws asks Art for a texture first. If the artwork
## has not been dropped into res://assets yet, Art returns null and the widget
## falls back to a hand-drawn placeholder, so the game is always playable.

const CREAM := Color("fdf6ec")
const CREAM_DEEP := Color("f6e7d4")
const INK := Color("5b4636")
const INK_SOFT := Color("8b7462")
const PINK := Color("f4b9bc")
const PINK_DEEP := Color("e4919a")
const SAGE := Color("bfd8c4")
const SKY := Color("bcd0e8")
const GOLD := Color("f2c761")
const WHITE := Color("fffcf7")

const STAT_COLORS := {
	"food": Color("f0a86a"),
	"clean": Color("8fc7e8"),
	"energy": Color("f2c761"),
	"mood": Color("f4a3b4"),
	"health": Color("9ecfa5"),
}

const RARITY_COLORS := {
	"starter": Color("f4b9bc"),
	"common": Color("bfd8c4"),
	"rare": Color("bcd0e8"),
	"epic": Color("d2b8e8"),
	"legendary": Color("f2c761"),
}

var manifest: Dictionary = {}
var _cache: Dictionary = {}
var _missing: Dictionary = {}


func _ready() -> void:
	if FileAccess.file_exists("res://assets/manifest.json"):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/manifest.json"))
		if parsed is Dictionary:
			manifest = parsed


func rarity_color(rarity: String) -> Color:
	return RARITY_COLORS.get(rarity, SAGE)


## --- texture loading ---------------------------------------------------

func _load(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _cache.has(path):
		return _cache[path]
	if _missing.has(path):
		return null
	if not ResourceLoader.exists(path):
		_missing[path] = true
		return null
	var tex := ResourceLoader.load(path) as Texture2D
	if tex == null:
		_missing[path] = true
		return null
	_cache[path] = tex
	return tex


## A plain image declared in manifest.images, e.g. "bg_home".
func image(key: String) -> Texture2D:
	var images: Dictionary = manifest.get("images", {})
	return _load(String(images.get(key, "")))


## One cell of a sprite sheet declared in manifest.sheets.
## Sheets are read left-to-right, top-to-bottom.
func pose(sheet_key: String, pose_name: String) -> Texture2D:
	var sheets: Dictionary = manifest.get("sheets", {})
	if not sheets.has(sheet_key):
		return null
	var sheet: Dictionary = sheets[sheet_key]
	var base := _load(String(sheet.get("path", "")))
	if base == null:
		return null
	var cols: int = maxi(1, int(sheet.get("cols", 1)))
	var rows: int = maxi(1, int(sheet.get("rows", 1)))
	var poses: Dictionary = sheet.get("poses", {})
	var index: int = int(poses.get(pose_name, poses.get("idle", 0)))
	index = clampi(index, 0, cols * rows - 1)

	var cache_key := "%s#%d" % [sheet_key, index]
	if _cache.has(cache_key):
		return _cache[cache_key]

	var cell := Vector2(float(base.get_width()) / cols, float(base.get_height()) / rows)
	var atlas := AtlasTexture.new()
	atlas.atlas = base
	atlas.region = Rect2(Vector2(index % cols, index / cols) * cell, cell)
	atlas.filter_clip = true
	_cache[cache_key] = atlas
	return atlas


## Artwork for one animal. Tries a sheet first, then a single image.
func creature(species_id: String, pose_name: String = "idle") -> Texture2D:
	var tex := pose(species_id, pose_name)
	if tex != null:
		return tex
	tex = _load("res://assets/pets/%s_%s.png" % [species_id, pose_name])
	if tex != null:
		return tex
	return _load("res://assets/pets/%s.png" % species_id)


## Artwork for the player character.
func owner(pose_name: String = "idle") -> Texture2D:
	var tex := pose("owner", pose_name)
	if tex != null:
		return tex
	return _load("res://assets/owner/%s.png" % pose_name)


## Background art for a scene key ("home", "mall", "meadow", ...).
func background(scene_key: String) -> Texture2D:
	var tex := image("bg_" + scene_key)
	if tex != null:
		return tex
	return _load("res://assets/bg/%s.png" % scene_key)


## --- theme -------------------------------------------------------------

func panel_box(fill: Color, radius: int = 22, border: int = 0, border_color: Color = INK) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.content_margin_left = 16
	box.content_margin_right = 16
	box.content_margin_top = 12
	box.content_margin_bottom = 12
	if border > 0:
		box.set_border_width_all(border)
		box.border_color = border_color
	return box


func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18

	var normal := panel_box(WHITE, 20)
	normal.content_margin_left = 18
	normal.content_margin_right = 18
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	normal.shadow_color = Color(0.6, 0.5, 0.42, 0.18)
	normal.shadow_size = 6
	normal.shadow_offset = Vector2(0, 3)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = CREAM_DEEP

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = PINK
	pressed.shadow_size = 2

	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(0.92, 0.89, 0.85)
	disabled.shadow_size = 0

	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_disabled_color", "Button", INK_SOFT)
	theme.set_font_size("font_size", "Button", 18)

	theme.set_color("font_color", "Label", INK)
	theme.set_stylebox("panel", "PanelContainer", panel_box(WHITE, 24))

	var line := panel_box(WHITE, 14, 2, CREAM_DEEP)
	theme.set_stylebox("normal", "LineEdit", line)
	theme.set_stylebox("focus", "LineEdit", panel_box(WHITE, 14, 2, PINK))
	theme.set_color("font_color", "LineEdit", INK)
	theme.set_color("font_placeholder_color", "LineEdit", INK_SOFT)
	theme.set_color("caret_color", "LineEdit", INK)

	theme.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	return theme
