extends Control
class_name StatBar
## A rounded, labelled meter used for pet stats, bond, growth and trust.

@export var label_text: String = "Food"
@export var value: float = 100.0
@export var max_value: float = 100.0
@export var fill_color: Color = Color("f4b9bc")
@export var show_value: bool = true
@export var compact: bool = false

var _display: float = -1.0


func _ready() -> void:
	custom_minimum_size.y = 30.0 if compact else 34.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_display = value
	set_process(true)


func _process(delta: float) -> void:
	if is_equal_approx(_display, value):
		return
	_display = move_toward(_display, value, maxf(8.0, absf(value - _display) * 4.0) * delta)
	queue_redraw()


func set_value(new_value: float) -> void:
	value = clampf(new_value, 0.0, max_value)
	if _display < 0.0:
		_display = value
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var font_size := 12 if compact else 15
	var bar_height := 8.0 if compact else 14.0
	var bar_top := size.y - bar_height

	if not compact or label_text != "":
		draw_string(font, Vector2(2.0, font_size + 1.0), label_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Art.INK_SOFT)
		if show_value:
			draw_string(font, Vector2(0.0, font_size + 1.0), "%d" % roundi(value),
				HORIZONTAL_ALIGNMENT_RIGHT, size.x - 2.0, font_size, Art.INK_SOFT)

	var track := Rect2(0.0, bar_top, size.x, bar_height)
	draw_rect(track, Art.CREAM_DEEP, true)
	_round_caps(track, Art.CREAM_DEEP)

	var ratio := clampf(maxf(_display, 0.0) / maxf(max_value, 1.0), 0.0, 1.0)
	if ratio > 0.001:
		var filled := Rect2(0.0, bar_top, maxf(bar_height, size.x * ratio), bar_height)
		draw_rect(filled, fill_color, true)
		_round_caps(filled, fill_color)


func _round_caps(rect: Rect2, color: Color) -> void:
	var r := rect.size.y * 0.5
	draw_circle(Vector2(rect.position.x + r, rect.position.y + r), r, color)
	draw_circle(Vector2(rect.end.x - r, rect.position.y + r), r, color)
