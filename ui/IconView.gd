extends Control
class_name IconView
## Small vector icons drawn in code, so the interface needs no icon assets.
##
## Every icon is drawn inside a normalised 0..1 box and scaled to the node, so
## the same icon reads correctly at 20px in a pill and at 44px in the nav bar.

@export var kind: String = "home":
	set(value):
		kind = value
		queue_redraw()
@export var tint: Color = Color("6b4a32"):
	set(value):
		tint = value
		queue_redraw()
@export var accent: Color = Color("f2c14e"):
	set(value):
		accent = value
		queue_redraw()

var _unit: float = 1.0
var _origin: Vector2 = Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func make(icon_kind: String, box: float, icon_tint: Color = Color("6b4a32"),
		icon_accent: Color = Color("f2c14e")) -> IconView:
	var node := IconView.new()
	node.kind = icon_kind
	node.tint = icon_tint
	node.accent = icon_accent
	node.custom_minimum_size = Vector2(box, box)
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return node


func _draw() -> void:
	_unit = minf(size.x, size.y)
	_origin = (size - Vector2(_unit, _unit)) * 0.5
	match kind:
		"home": _home()
		"paw": _paw()
		"cat": _cat()
		"friends": _friends()
		"map": _map()
		"bag": _bag()
		"shop": _shop()
		"mail": _mail()
		"camera": _camera()
		"gear": _gear()
		"calendar": _calendar()
		"trophy": _trophy()
		"sparkle": _sparkle()
		"coin": _coin()
		"gem": _gem()
		"heart": _heart()
		"plus": _plus()
		"check": _check()
		"close": _close()
		"bowl": _bowl()
		"drop": _drop()
		"moon": _moon()
		_: _paw()


## --- drawing helpers ---------------------------------------------------

func _at(x: float, y: float) -> Vector2:
	return _origin + Vector2(x, y) * _unit


func _poly(points: Array, color: Color) -> void:
	var out := PackedVector2Array()
	for p: Vector2 in points:
		out.append(_at(p.x, p.y))
	draw_colored_polygon(out, color)


func _oval(cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		points.append(_at(cx + cos(a) * rx, cy + sin(a) * ry))
	draw_colored_polygon(points, color)


func _box(x: float, y: float, w: float, h: float, color: Color, radius: float = 0.0) -> void:
	draw_rect(Rect2(_at(x, y), Vector2(w, h) * _unit), color, true)
	if radius > 0.0:
		for corner: Vector2 in [Vector2(x + radius, y + radius), Vector2(x + w - radius, y + radius),
				Vector2(x + radius, y + h - radius), Vector2(x + w - radius, y + h - radius)]:
			_oval(corner.x, corner.y, radius, radius, color)


func _stroke(points: Array, color: Color, width: float) -> void:
	var out := PackedVector2Array()
	for p: Vector2 in points:
		out.append(_at(p.x, p.y))
	draw_polyline(out, color, width * _unit, true)


## --- icons -------------------------------------------------------------

func _home() -> void:
	_poly([Vector2(0.5, 0.14), Vector2(0.92, 0.48), Vector2(0.08, 0.48)], accent)
	_box(0.18, 0.46, 0.64, 0.40, accent)
	_box(0.40, 0.62, 0.20, 0.24, tint)


func _paw() -> void:
	_oval(0.50, 0.66, 0.24, 0.20, tint)
	_oval(0.26, 0.40, 0.10, 0.13, tint)
	_oval(0.44, 0.29, 0.10, 0.13, tint)
	_oval(0.64, 0.31, 0.10, 0.13, tint)
	_oval(0.80, 0.47, 0.09, 0.12, tint)


func _cat() -> void:
	# Drawn in tint with light eyes, so it reads on both light and dark chips.
	_poly([Vector2(0.20, 0.34), Vector2(0.26, 0.10), Vector2(0.42, 0.24)], tint)
	_poly([Vector2(0.80, 0.34), Vector2(0.74, 0.10), Vector2(0.58, 0.24)], tint)
	_oval(0.50, 0.56, 0.34, 0.30, tint)
	_oval(0.38, 0.52, 0.045, 0.06, Art.WHITE)
	_oval(0.62, 0.52, 0.045, 0.06, Art.WHITE)


func _friends() -> void:
	_oval(0.34, 0.58, 0.26, 0.24, tint)
	_oval(0.68, 0.50, 0.24, 0.22, accent)
	_oval(0.26, 0.54, 0.04, 0.05, Art.WHITE)
	_oval(0.42, 0.54, 0.04, 0.05, Art.WHITE)


func _map() -> void:
	_oval(0.50, 0.40, 0.28, 0.28, accent)
	_poly([Vector2(0.30, 0.52), Vector2(0.70, 0.52), Vector2(0.50, 0.92)], accent)
	_oval(0.50, 0.40, 0.11, 0.11, Art.WHITE)


func _bag() -> void:
	_stroke([Vector2(0.30, 0.42), Vector2(0.30, 0.20), Vector2(0.70, 0.20), Vector2(0.70, 0.42)],
		tint, 0.08)
	_box(0.14, 0.34, 0.72, 0.52, accent, 0.11)
	_box(0.14, 0.52, 0.72, 0.10, tint)
	_box(0.42, 0.48, 0.16, 0.18, tint, 0.03)


func _shop() -> void:
	_box(0.14, 0.42, 0.72, 0.44, Art.CREAM_DEEP, 0.06)
	for i in 4:
		var x := 0.14 + float(i) * 0.18
		draw_rect(Rect2(_at(x, 0.20), Vector2(0.18, 0.20) * _unit),
			accent if i % 2 == 0 else tint, true)
	_box(0.38, 0.56, 0.24, 0.30, tint, 0.04)


func _mail() -> void:
	_box(0.10, 0.26, 0.80, 0.48, accent, 0.06)
	_poly([Vector2(0.10, 0.26), Vector2(0.90, 0.26), Vector2(0.50, 0.58)], accent.darkened(0.16))
	_stroke([Vector2(0.10, 0.26), Vector2(0.10, 0.74), Vector2(0.90, 0.74), Vector2(0.90, 0.26),
		Vector2(0.10, 0.26)], tint, 0.05)


func _camera() -> void:
	_box(0.10, 0.32, 0.80, 0.46, tint, 0.09)
	_box(0.34, 0.22, 0.24, 0.14, tint, 0.04)
	_oval(0.50, 0.55, 0.17, 0.17, Art.WHITE)
	_oval(0.50, 0.55, 0.10, 0.10, accent)


func _gear() -> void:
	for i in 8:
		var a := TAU * float(i) / 8.0
		_oval(0.50 + cos(a) * 0.32, 0.50 + sin(a) * 0.32, 0.11, 0.11, tint)
	_oval(0.50, 0.50, 0.30, 0.30, tint)
	_oval(0.50, 0.50, 0.13, 0.13, Art.WHITE)


func _calendar() -> void:
	_box(0.12, 0.22, 0.76, 0.64, Art.CREAM_DEEP, 0.07)
	_box(0.12, 0.22, 0.76, 0.20, accent, 0.07)
	_box(0.26, 0.12, 0.08, 0.16, tint, 0.03)
	_box(0.66, 0.12, 0.08, 0.16, tint, 0.03)
	for row in 2:
		for col in 3:
			_box(0.24 + float(col) * 0.20, 0.50 + float(row) * 0.16, 0.11, 0.09, tint, 0.02)


func _trophy() -> void:
	_poly([Vector2(0.26, 0.16), Vector2(0.74, 0.16), Vector2(0.66, 0.56), Vector2(0.34, 0.56)], accent)
	_stroke([Vector2(0.26, 0.24), Vector2(0.12, 0.30), Vector2(0.22, 0.44)], accent, 0.07)
	_stroke([Vector2(0.74, 0.24), Vector2(0.88, 0.30), Vector2(0.78, 0.44)], accent, 0.07)
	_box(0.44, 0.56, 0.12, 0.16, accent)
	_box(0.30, 0.72, 0.40, 0.14, tint, 0.05)


func _sparkle() -> void:
	_poly([Vector2(0.50, 0.06), Vector2(0.60, 0.40), Vector2(0.94, 0.50),
		Vector2(0.60, 0.60), Vector2(0.50, 0.94), Vector2(0.40, 0.60),
		Vector2(0.06, 0.50), Vector2(0.40, 0.40)], accent)
	_oval(0.50, 0.50, 0.09, 0.09, Art.WHITE)


func _coin() -> void:
	_oval(0.50, 0.50, 0.44, 0.44, accent.darkened(0.18))
	_oval(0.50, 0.50, 0.36, 0.36, accent)
	_oval(0.50, 0.58, 0.15, 0.13, accent.darkened(0.24))
	_oval(0.34, 0.40, 0.06, 0.08, accent.darkened(0.24))
	_oval(0.50, 0.33, 0.06, 0.08, accent.darkened(0.24))
	_oval(0.66, 0.40, 0.06, 0.08, accent.darkened(0.24))


func _gem() -> void:
	_poly([Vector2(0.50, 0.10), Vector2(0.90, 0.40), Vector2(0.50, 0.90), Vector2(0.10, 0.40)],
		accent.darkened(0.15))
	_poly([Vector2(0.50, 0.10), Vector2(0.90, 0.40), Vector2(0.50, 0.48), Vector2(0.10, 0.40)], accent)
	_poly([Vector2(0.50, 0.10), Vector2(0.50, 0.48), Vector2(0.10, 0.40)], accent.lightened(0.22))


func _heart() -> void:
	_oval(0.33, 0.36, 0.24, 0.24, accent)
	_oval(0.67, 0.36, 0.24, 0.24, accent)
	_poly([Vector2(0.09, 0.42), Vector2(0.91, 0.42), Vector2(0.50, 0.92)], accent)


func _plus() -> void:
	_box(0.42, 0.16, 0.16, 0.68, tint, 0.05)
	_box(0.16, 0.42, 0.68, 0.16, tint, 0.05)


func _check() -> void:
	_stroke([Vector2(0.18, 0.52), Vector2(0.42, 0.76), Vector2(0.84, 0.24)], tint, 0.14)


func _bowl() -> void:
	_oval(0.50, 0.42, 0.30, 0.16, accent)
	_poly([Vector2(0.18, 0.42), Vector2(0.82, 0.42), Vector2(0.70, 0.80), Vector2(0.30, 0.80)], tint)
	_oval(0.50, 0.80, 0.20, 0.06, tint)


func _drop() -> void:
	_poly([Vector2(0.50, 0.08), Vector2(0.82, 0.56), Vector2(0.18, 0.56)], accent)
	_oval(0.50, 0.60, 0.32, 0.30, accent)
	_oval(0.38, 0.62, 0.08, 0.10, Art.WHITE)


## The crescent is cut with a solid disc, so this icon expects a light card
## behind it. `tint` is that background colour.
func _moon() -> void:
	_oval(0.48, 0.50, 0.40, 0.40, accent)
	_oval(0.70, 0.42, 0.34, 0.34, tint)


func _close() -> void:
	_stroke([Vector2(0.24, 0.24), Vector2(0.76, 0.76)], tint, 0.11)
	_stroke([Vector2(0.76, 0.24), Vector2(0.24, 0.76)], tint, 0.11)
