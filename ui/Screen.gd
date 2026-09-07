extends Control
class_name Screen
## Base class for every screen. Screens build their own node tree in code and
## rebuild when the save changes, which keeps state and view impossible to
## desynchronise.

var args: Dictionary = {}
var main: Node = null

## Scene key used to pick the background art, e.g. "home" or "mall".
var scene_key: String = "home"
## When false the top bar and nav bar are hidden (used by onboarding).
var show_chrome: bool = true

var _root: Control = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rebuild()
	if not GameState.changed.is_connected(_on_state_changed):
		GameState.changed.connect(_on_state_changed)


func _exit_tree() -> void:
	if GameState.changed.is_connected(_on_state_changed):
		GameState.changed.disconnect(_on_state_changed)


func _on_state_changed() -> void:
	if is_inside_tree():
		refresh()


func rebuild() -> void:
	if _root != null and is_instance_valid(_root):
		_root.queue_free()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_root)
	build(_root)


## Override: fill `host` with this screen's content.
func build(_host: Control) -> void:
	pass


## Override: cheap update in response to a save change. The default rebuilds.
func refresh() -> void:
	rebuild()


func goto(screen_name: String, screen_args: Dictionary = {}) -> void:
	if main != null:
		main.goto(screen_name, screen_args)


## Full-bleed padded column, the layout every screen uses.
func page(host: Control, padding: int = 22) -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", padding)
	margin.add_theme_constant_override("margin_right", padding)
	margin.add_theme_constant_override("margin_top", padding)
	margin.add_theme_constant_override("margin_bottom", padding)
	host.add_child(margin)
	var column := UI.vbox(12)
	margin.add_child(column)
	return column
