extends Control
class_name CreatureView
## Draws one animal (or the player character).
##
## If artwork exists for the species it is drawn aspect-fitted. Otherwise a
## soft chibi placeholder is drawn from the species palette, so the game looks
## finished long before the art does.

@export var species_id: String = "ragdoll"
@export var pose: String = "idle"
@export var is_owner: bool = false
@export var silhouette: bool = false
@export var animate: bool = true
@export var accessory_color: Color = Color(0, 0, 0, 0)

const HAIR := Color("6b5140")

var _phase: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_phase = randf() * TAU
	set_process(animate)


func _process(delta: float) -> void:
	_phase += delta * 1.6
	queue_redraw()


func show_creature(id: String, new_pose: String = "idle") -> void:
	species_id = id
	pose = new_pose
	queue_redraw()


func set_pose(new_pose: String) -> void:
	pose = new_pose
	queue_redraw()


func _texture() -> Texture2D:
	return Art.owner(pose) if is_owner else Art.creature(species_id, pose)


func _draw() -> void:
	var bob := sin(_phase) * (size.y * 0.012) if animate else 0.0
	var box := Rect2(Vector2.ZERO, size)
	var tex := _texture()

	if tex != null:
		var tex_size := tex.get_size()
		if tex_size.x > 0.0 and tex_size.y > 0.0:
			var scale := minf(size.x / tex_size.x, size.y / tex_size.y)
			var drawn := tex_size * scale
			var at := Vector2((size.x - drawn.x) * 0.5, (size.y - drawn.y) * 0.5 + bob)
			var tint := Color(0.42, 0.36, 0.32, 0.85) if silhouette else Color.WHITE
			draw_texture_rect(tex, Rect2(at, drawn), false, tint)
			return

	_draw_placeholder(box, bob)


func _draw_placeholder(box: Rect2, bob: float) -> void:
	var info := Data.get_species(species_id)
	var body_color := Color(String(info.get("body", "#f2e4d6"))) if not is_owner else Art.CREAM_DEEP
	var accent := Color(String(info.get("accent", "#9c8574"))) if not is_owner else Art.PINK
	if silhouette:
		body_color = Color(0.80, 0.76, 0.72)
		accent = Color(0.72, 0.68, 0.64)

	var unit := minf(box.size.x, box.size.y)
	var center := box.size * 0.5 + Vector2(0.0, bob)
	var body_radius := Vector2(unit * 0.30, unit * 0.26)
	var head_center := center - Vector2(0.0, unit * 0.20)
	var head_radius := Vector2(unit * 0.24, unit * 0.22)

	# Soft shadow on the ground.
	_ellipse(center + Vector2(0.0, unit * 0.30), Vector2(unit * 0.28, unit * 0.06), Color(0.55, 0.46, 0.40, 0.16))

	# A soft outline keeps the pale placeholder readable on a pale background.
	var outline := body_color.darkened(0.24)

	# Tail (a gentle sweep behind the body).
	if not is_owner:
		var tail_from := center + Vector2(body_radius.x * 0.8, 0.0)
		var tail_points := PackedVector2Array()
		for i in 12:
			var t := float(i) / 11.0
			tail_points.append(tail_from + Vector2(
				unit * 0.16 * t,
				-unit * 0.20 * sin(t * PI * 0.8 + sin(_phase) * 0.25)
			))
		draw_polyline(tail_points, accent, unit * 0.055, true)

	_ellipse(center, body_radius * 1.05, outline)
	_ellipse(center, body_radius, body_color)

	# Ears change with the animal kind, so species read differently.
	var kind := String(info.get("kind", "Cat"))
	var ear_span := head_radius.x * 0.72
	if is_owner:
		# The back of the hair sits behind the head; the fringe comes after it.
		_ellipse(head_center - Vector2(0.0, head_radius.y * 0.18), head_radius * Vector2(1.22, 1.16), HAIR)
	else:
		match kind:
			"Bunny":
				_ellipse(head_center + Vector2(-ear_span * 0.6, -head_radius.y * 1.15), Vector2(unit * 0.05, unit * 0.15), body_color)
				_ellipse(head_center + Vector2(ear_span * 0.6, -head_radius.y * 1.15), Vector2(unit * 0.05, unit * 0.15), body_color)
			"Bird", "Duck", "Penguin":
				draw_colored_polygon(PackedVector2Array([
					head_center + Vector2(head_radius.x * 0.78, 0.0),
					head_center + Vector2(head_radius.x * 1.35, unit * 0.03),
					head_center + Vector2(head_radius.x * 0.78, unit * 0.06),
				]), Art.GOLD)
			"Hedgehog":
				for i in 9:
					var a := lerpf(-PI * 0.95, -PI * 0.05, float(i) / 8.0)
					var from := head_center + Vector2(cos(a), sin(a)) * head_radius
					draw_line(from, from + Vector2(cos(a), sin(a)) * unit * 0.06, accent, unit * 0.018, true)
			_:
				_triangle(head_center + Vector2(-ear_span, -head_radius.y * 0.86), unit * 0.11, outline)
				_triangle(head_center + Vector2(ear_span, -head_radius.y * 0.86), unit * 0.11, outline)
				_triangle(head_center + Vector2(-ear_span, -head_radius.y * 0.84), unit * 0.095, body_color)
				_triangle(head_center + Vector2(ear_span, -head_radius.y * 0.84), unit * 0.095, body_color)

	_ellipse(head_center, head_radius * 1.05, outline)
	_ellipse(head_center, head_radius, body_color)
	if is_owner:
		_ellipse(head_center - Vector2(0.0, head_radius.y * 0.74), head_radius * Vector2(1.04, 0.52), HAIR)
		var bow_at := head_center + Vector2(-head_radius.x * 0.92, -head_radius.y * 0.70)
		_ellipse(bow_at + Vector2(-unit * 0.026, 0.0), Vector2(unit * 0.028, unit * 0.020), Art.PINK)
		_ellipse(bow_at + Vector2(unit * 0.026, 0.0), Vector2(unit * 0.028, unit * 0.020), Art.PINK)
		_ellipse(bow_at, Vector2(unit * 0.014, unit * 0.014), Art.PINK_DEEP)
	else:
		_ellipse(head_center + Vector2(0.0, head_radius.y * 0.36), Vector2(head_radius.x * 0.52, head_radius.y * 0.34), accent.lerp(Art.WHITE, 0.55))

	if silhouette:
		return

	var eye_offset := head_radius.x * 0.42
	var eye_y := head_center.y - head_radius.y * 0.05
	var closed := pose in ["sleep", "curl", "happy", "wink"]
	if closed:
		for dir in [-1.0, 1.0]:
			draw_arc(Vector2(head_center.x + eye_offset * dir, eye_y), unit * 0.035, PI, TAU, 12, Art.INK, unit * 0.012, true)
	else:
		for dir in [-1.0, 1.0]:
			_ellipse(Vector2(head_center.x + eye_offset * dir, eye_y), Vector2(unit * 0.028, unit * 0.036), Art.INK)
			_ellipse(Vector2(head_center.x + eye_offset * dir + unit * 0.010, eye_y - unit * 0.012), Vector2(unit * 0.010, unit * 0.012), Art.WHITE)

	for dir in [-1.0, 1.0]:
		_ellipse(Vector2(head_center.x + head_radius.x * 0.72 * dir, eye_y + unit * 0.045), Vector2(unit * 0.030, unit * 0.018), Art.PINK.lerp(Art.WHITE, 0.15))

	if not is_owner:
		_ellipse(head_center + Vector2(0.0, head_radius.y * 0.28), Vector2(unit * 0.020, unit * 0.014), Art.PINK_DEEP)

	if accessory_color.a > 0.05:
		var bow := head_center + Vector2(head_radius.x * 0.80, -head_radius.y * 0.72)
		_ellipse(bow + Vector2(-unit * 0.030, 0.0), Vector2(unit * 0.030, unit * 0.022), accessory_color)
		_ellipse(bow + Vector2(unit * 0.030, 0.0), Vector2(unit * 0.030, unit * 0.022), accessory_color)
		_ellipse(bow, Vector2(unit * 0.016, unit * 0.016), accessory_color.darkened(0.15))

	if pose == "sleep":
		var font := ThemeDB.fallback_font
		for i in 3:
			var t := fmod(_phase * 0.35 + float(i) * 0.33, 1.0)
			draw_string(font, head_center + Vector2(head_radius.x * 1.1 + t * unit * 0.14, -head_radius.y - t * unit * 0.28),
				"z", HORIZONTAL_ALIGNMENT_LEFT, -1, int(unit * 0.09), Color(Art.INK_SOFT, 1.0 - t))


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in 28:
		var a := TAU * float(i) / 28.0
		points.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	draw_colored_polygon(points, color)


func _triangle(tip_center: Vector2, size_px: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		tip_center + Vector2(0.0, -size_px),
		tip_center + Vector2(-size_px * 0.72, size_px * 0.55),
		tip_center + Vector2(size_px * 0.72, size_px * 0.55),
	]), color)
