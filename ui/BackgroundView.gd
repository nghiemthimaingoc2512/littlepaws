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

	var sky := Art.CREAM
	var floor_color := Art.CREAM_DEEP
	if GameState.started():
		var decor := Data.item("decor", GameState.equipped("decor"))
		sky = Color(String(decor.get("sky", "#fbf1e4")))
		floor_color = Color(String(decor.get("floor", "#efe0cc")))
	match scene_key:
		"mall":
			sky = Color("fdf1e6"); floor_color = Color("f3e2d2")
		"meadow":
			sky = Color("eef6ec"); floor_color = Color("d9ead5")
		"forest":
			sky = Color("e7efe9"); floor_color = Color("cddccf")
		"bay":
			sky = Color("eaf1f8"); floor_color = Color("d3e0ee")

	var horizon := size.y * 0.62
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, horizon)), sky, true)
	draw_rect(Rect2(Vector2(0.0, horizon), Vector2(size.x, size.y - horizon)), floor_color, true)

	# A few soft blobs so the empty backdrop still feels like a place.
	var blob := sky.darkened(0.05)
	for i in 5:
		var t := float(i) / 4.0
		var center := Vector2(size.x * (0.08 + t * 0.86), horizon - size.y * (0.10 + 0.05 * sin(t * 6.0)))
		var radius := size.y * (0.07 + 0.03 * cos(t * 4.0))
		draw_circle(center, radius, blob)
	draw_line(Vector2(0.0, horizon), Vector2(size.x, horizon), floor_color.darkened(0.06), 3.0)
