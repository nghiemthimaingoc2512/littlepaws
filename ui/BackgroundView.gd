extends Control
class_name BackgroundView
## Draws the scene backdrop: real artwork when it exists, otherwise a soft
## gradient built from the player's chosen room decor.

var scene_key: String = "home":
	set(value):
		scene_key = value
		queue_redraw()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var tex := Art.background(scene_key)
	if tex != null:
		var tex_size := tex.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			# Cover the viewport, cropping the overflow.
			var scale := maxf(size.x / tex_size.x, size.y / tex_size.y)
			var drawn := tex_size * scale
			var at := (size - drawn) * 0.5
			draw_texture_rect(tex, Rect2(at, drawn), false)
			draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.12), true)
			return

	var wall := Art.CREAM_DEEP
	var floor_color := Art.WOOD
	if GameState.started():
		var decor := Data.item("decor", GameState.equipped("decor"))
		wall = Color(String(decor.get("sky", "#f5e5cd")))
		floor_color = Color(String(decor.get("floor", "#e8d2ac")))
	match scene_key:
		"mall":
			wall = Color("fbeee0"); floor_color = Color("efdcc4")
		"meadow":
			wall = Color("e9f2e4"); floor_color = Color("d3e5cc")
		"forest":
			wall = Color("e3ece5"); floor_color = Color("c8d9c9")
		"bay":
			wall = Color("e6eef7"); floor_color = Color("cfdff0")

	var horizon := size.y * 0.60
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, horizon)), wall, true)
	draw_rect(Rect2(Vector2(0.0, horizon), Vector2(size.x, size.y - horizon)), floor_color, true)

	if scene_key == "home":
		_draw_room(horizon, floor_color)
	else:
		_draw_outdoors(horizon, wall, floor_color)
	draw_line(Vector2(0.0, horizon), Vector2(size.x, horizon), floor_color.darkened(0.07), 3.0)


## A stand-in living room: sofa on the left, window and cat tree on the right,
## rug in the middle where the pet sits.
func _draw_room(horizon: float, floor_color: Color) -> void:
	var window := Rect2(size.x * 0.63, size.y * 0.12, size.x * 0.20, size.y * 0.30)
	draw_rect(window.grow(7.0), Art.WHITE, true)
	draw_rect(window, Color("d7e8f6"), true)
	draw_circle(Vector2(window.position.x + window.size.x * 0.70,
		window.position.y + window.size.y * 0.26), size.y * 0.035, Art.WHITE)
	draw_rect(Rect2(window.get_center().x - 2.5, window.position.y, 5.0, window.size.y),
		Art.WHITE, true)
	draw_rect(Rect2(window.position.x - 12.0, window.end.y, window.size.x + 24.0, 9.0),
		Art.WOOD.darkened(0.06), true)

	# Floorboards.
	var board := floor_color.darkened(0.05)
	var y := horizon + size.y * 0.09
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), board, 2.0)
		y += size.y * 0.11

	# Cat tree, right of centre.
	var post := Art.WOOD.darkened(0.10)
	_rounded(Rect2(size.x * 0.545, horizon - size.y * 0.30, size.x * 0.028, size.y * 0.30),
		post, size.y * 0.012)
	_rounded(Rect2(size.x * 0.515, horizon - size.y * 0.33, size.x * 0.088, size.y * 0.035),
		Art.WOOD.lightened(0.10), size.y * 0.016)
	_rounded(Rect2(size.x * 0.512, horizon - size.y * 0.02, size.x * 0.094, size.y * 0.030),
		Art.WOOD.lightened(0.05), size.y * 0.014)

	# Sofa: back, seat, then two arms.
	var sofa := Rect2(size.x * 0.06, horizon - size.y * 0.12, size.x * 0.21, size.y * 0.17)
	_rounded(sofa, Art.SAGE, size.y * 0.030)
	_rounded(Rect2(sofa.position.x + size.x * 0.012, sofa.position.y + sofa.size.y * 0.44,
		sofa.size.x - size.x * 0.024, sofa.size.y * 0.56), Art.SAGE.lightened(0.15), size.y * 0.026)
	for side: float in [0.0, 1.0]:
		_rounded(Rect2(sofa.position.x + (sofa.size.x - size.x * 0.026) * side,
			sofa.position.y + sofa.size.y * 0.30, size.x * 0.026, sofa.size.y * 0.70),
			Art.SAGE.darkened(0.06), size.y * 0.020)

	# Rug under the pet.
	var rug := Vector2(size.x * 0.50, size.y * 0.755)
	_ellipse(rug, Vector2(size.x * 0.145, size.y * 0.058), floor_color.lightened(0.18))
	_ellipse(rug, Vector2(size.x * 0.108, size.y * 0.042), Art.SAGE.lerp(floor_color, 0.60))


func _draw_outdoors(horizon: float, wall: Color, floor_color: Color) -> void:
	var blob := wall.darkened(0.05)
	for i in 5:
		var t := float(i) / 4.0
		var center := Vector2(size.x * (0.08 + t * 0.86),
			horizon - size.y * (0.10 + 0.05 * sin(t * 6.0)))
		draw_circle(center, size.y * (0.07 + 0.03 * cos(t * 4.0)), blob)
	for i in 7:
		var t := float(i) / 6.0
		draw_circle(Vector2(size.x * (0.06 + t * 0.9), size.y * (0.74 + 0.16 * sin(t * 9.0))),
			size.y * 0.02, floor_color.darkened(0.06))


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 36:
		var a := TAU * float(i) / 36.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(points, color)


func _rounded(rect: Rect2, color: Color, radius: float) -> void:
	var r := minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	draw_rect(Rect2(rect.position + Vector2(r, 0.0),
		rect.size - Vector2(r * 2.0, 0.0)), color, true)
	draw_rect(Rect2(rect.position + Vector2(0.0, r),
		rect.size - Vector2(0.0, r * 2.0)), color, true)
	for corner: Vector2 in [rect.position + Vector2(r, r),
			Vector2(rect.end.x - r, rect.position.y + r),
			Vector2(rect.position.x + r, rect.end.y - r),
			rect.end - Vector2(r, r)]:
		draw_circle(corner, r, color)
