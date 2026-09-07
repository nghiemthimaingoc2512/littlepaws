extends Screen
## The room. Everything the mock-up shows: shortcuts down the left, the day's
## list on the right, and your pet in the middle waiting to be looked after.
##
## Care lives in a sheet that slides up when you tap the pet or Let's Play, so
## the room stays uncluttered.

const CARE_ORDER := ["feed", "play", "bathe", "brush", "sleep", "heal"]

const RAIL := [
	{"id": "daily", "label": "Daily", "icon": "calendar"},
	{"id": "missions", "label": "Missions", "icon": "trophy"},
	{"id": "shop", "label": "Shop", "icon": "shop"},
	{"id": "events", "label": "Events", "icon": "sparkle"},
]

var _care_open: bool = false
var _bars: Dictionary = {}
var _buttons: Dictionary = {}
var _pet_view: CreatureView
var _pose_timer: float = 0.0
var _tick: float = 0.0


func _init() -> void:
	scene_key = "home"


func _ready() -> void:
	_care_open = bool(args.get("open_care", false))
	super()
	GameState.ticked.connect(_update_meters)
	GameState.pose_hint.connect(_on_pose_hint)
	set_process(true)


func _exit_tree() -> void:
	super()
	if GameState.ticked.is_connected(_update_meters):
		GameState.ticked.disconnect(_update_meters)
	if GameState.pose_hint.is_connected(_on_pose_hint):
		GameState.pose_hint.disconnect(_on_pose_hint)


func _process(delta: float) -> void:
	if _pose_timer > 0.0:
		_pose_timer -= delta
		if _pose_timer <= 0.0 and is_instance_valid(_pet_view):
			_pet_view.set_pose(GameState.mood_pose())
	_tick += delta
	if _tick >= 0.5:
		_tick = 0.0
		_update_buttons()


func build(host: Control) -> void:
	if not GameState.started():
		return
	_bars.clear()
	_buttons.clear()

	_anchor(host, _left_rail(), Control.PRESET_CENTER_LEFT, Vector2(16, -30), Vector2(96, 350))
	_anchor(host, _right_panel(), Control.PRESET_TOP_RIGHT, Vector2(-16, 86), Vector2(250, 0))
	# With the care sheet open the pet moves up so you can still watch it react.
	if _care_open:
		_anchor(host, _pet_stage(170.0), Control.PRESET_CENTER_BOTTOM,
			Vector2(0, -330), Vector2(320, 250))
		_anchor(host, _care_sheet(), Control.PRESET_BOTTOM_WIDE,
			Vector2(120, -104), Vector2(0, 214))
	else:
		_anchor(host, _pet_stage(210.0), Control.PRESET_CENTER_BOTTOM,
			Vector2(0, -108), Vector2(360, 300))


## Places a floating element without a layout container, matching the mock-up.
func _anchor(host: Control, node: Control, preset: int, pad: Vector2, box: Vector2) -> void:
	node.set_anchors_and_offsets_preset(preset)
	match preset:
		Control.PRESET_CENTER_LEFT:
			node.grow_vertical = Control.GROW_DIRECTION_BOTH
			node.offset_left = pad.x
			node.offset_right = pad.x + box.x
			node.offset_top = pad.y - box.y * 0.5
			node.offset_bottom = pad.y + box.y * 0.5
		Control.PRESET_TOP_RIGHT:
			node.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			node.offset_right = pad.x
			node.offset_left = pad.x - box.x
			node.offset_top = pad.y
			node.offset_bottom = pad.y
		Control.PRESET_CENTER_BOTTOM:
			node.grow_horizontal = Control.GROW_DIRECTION_BOTH
			node.offset_left = -box.x * 0.5
			node.offset_right = box.x * 0.5
			node.offset_bottom = pad.y
			node.offset_top = pad.y - box.y
		Control.PRESET_BOTTOM_WIDE:
			node.offset_left = pad.x
			node.offset_right = -pad.x
			node.offset_bottom = pad.y
			node.offset_top = pad.y - box.y
	host.add_child(node)


## --- left rail ---------------------------------------------------------

func _left_rail() -> Control:
	var column := UI.vbox(10)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	for entry: Dictionary in RAIL:
		column.add_child(_rail_button(entry))
	return column


func _rail_button(entry: Dictionary) -> Control:
	var id := String(entry["id"])
	var card := UI.card(Art.WHITE, 20)
	var style := card.get_theme_stylebox("panel") as StyleBoxFlat
	style.content_margin_top = 8
	style.content_margin_bottom = 6
	style.set_border_width_all(2)
	style.border_color = Art.CREAM_DEEP

	var column := UI.vbox(2)
	card.add_child(column)
	column.add_child(IconView.make(String(entry["icon"]), 30, Art.INK, Art.GOLD))
	column.add_child(UI.label(String(entry["label"]), 13, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))

	var button := UI.clickable(card, func() -> void: goto(id), Vector2(90, 74))
	if _rail_has_news(id):
		UI.dot(button)
	return button


func _rail_has_news(id: String) -> bool:
	match id:
		"daily": return GameState.any_task_claimable()
		"missions": return GameState.missions_have_news()
		"events": return GameState.events_have_news()
	return false


## --- right panel -------------------------------------------------------

func _right_panel() -> Control:
	var column := UI.vbox(12)
	column.add_child(_hanging_sign())
	column.add_child(_todo_card())
	return column


func _hanging_sign() -> Control:
	var card := UI.card(Art.CREAM, 18)
	var style := card.get_theme_stylebox("panel") as StyleBoxFlat
	style.set_border_width_all(2)
	style.border_color = Art.WOOD
	card.size_flags_horizontal = Control.SIZE_SHRINK_END

	var column := UI.vbox(0)
	card.add_child(column)
	for line: String in ["Home", "Sweet", "Home"]:
		column.add_child(UI.label(line, 19, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(IconView.make("heart", 16, Art.PINK, Art.PINK))
	return card


func _todo_card() -> Control:
	var card := UI.card(Art.WHITE, 20)
	var style := card.get_theme_stylebox("panel") as StyleBoxFlat
	style.set_border_width_all(2)
	style.border_color = Art.CREAM_DEEP

	var column := UI.vbox(5)
	card.add_child(column)
	column.add_child(UI.label("To Do Today", 18, Art.INK))
	for task: Dictionary in GameState.DAILY_TASKS:
		column.add_child(_todo_row(task))
	return card


func _todo_row(task: Dictionary) -> Control:
	var done := GameState.task_done(task)
	var claimable := GameState.task_claimable(task)

	var row := UI.hbox(7)
	var mark := UI.card(Art.SAGE if done else Art.WHITE, 5)
	mark.custom_minimum_size = Vector2(19, 19)
	var mark_style := mark.get_theme_stylebox("panel") as StyleBoxFlat
	mark_style.content_margin_left = 2
	mark_style.content_margin_right = 2
	mark_style.content_margin_top = 2
	mark_style.content_margin_bottom = 2
	mark_style.set_border_width_all(2)
	mark_style.border_color = Art.SAGE.darkened(0.12) if done else Art.CREAM_DEEP
	if done:
		mark.add_child(IconView.make("check", 13, Art.WHITE))
	row.add_child(mark)

	var text := UI.label(String(task.get("label", "")), 15,
		Art.INK_SOFT if done else Art.INK)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(text)

	if claimable:
		var claim := UI.card(Art.GOLD, 999)
		claim.custom_minimum_size = Vector2(24, 24)
		var claim_style := claim.get_theme_stylebox("panel") as StyleBoxFlat
		claim_style.content_margin_left = 4
		claim_style.content_margin_right = 4
		claim_style.content_margin_top = 4
		claim_style.content_margin_bottom = 4
		claim.add_child(IconView.make("plus", 13, Art.INK))
		var task_id := String(task.get("id", ""))
		row.add_child(UI.clickable(claim, func() -> void: GameState.claim_task(task_id),
			Vector2(24, 24)))
	return row


## --- the pet -----------------------------------------------------------

func _pet_stage(box: float) -> Control:
	var column := UI.vbox(2)
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(_mood_bubble())

	_pet_view = UI.creature(GameState.pet_species(), box, GameState.mood_pose())
	_pet_view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var accessory := Data.item("accessory", GameState.equipped("accessory"))
	if accessory.has("color"):
		_pet_view.accessory_color = Color(String(accessory["color"]))

	var tappable := UI.clickable(_pet_view, _toggle_care, Vector2(box, box))
	tappable.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(tappable)

	var name_pill := UI.pill("%s  ·  %s" % [GameState.pet_name(), GameState.stage_name()],
		Color(1, 1, 1, 0.92), 15)
	column.add_child(name_pill)
	return column


## A small speech bubble showing what your pet is thinking about.
func _mood_bubble() -> Control:
	var bubble := UI.card(Art.WHITE, 18)
	bubble.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style := bubble.get_theme_stylebox("panel") as StyleBoxFlat
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6

	var icon_kind := "heart"
	var accent := Art.RED
	if GameState.stat("food") < 40.0:
		icon_kind = "bowl"
		accent = Art.GOLD
	elif GameState.stat("clean") < 40.0:
		icon_kind = "drop"
		accent = Art.SKY
	elif GameState.stat("energy") < 35.0:
		icon_kind = "moon"
		accent = Art.SKY
	elif GameState.stat("mood") < 45.0:
		icon_kind = "paw"
		accent = Art.PINK
	bubble.add_child(IconView.make(icon_kind, 24, Art.WHITE, accent))
	return bubble


## --- care sheet --------------------------------------------------------

func _care_sheet() -> Control:
	var card := UI.card(Color(1, 1, 1, 0.96), 24)
	var body := UI.vbox(8)
	card.add_child(body)

	var header := UI.hbox(10)
	body.add_child(header)
	header.add_child(UI.label("Looking after %s" % GameState.pet_name(), 20, Art.INK))
	header.add_child(UI.spacer())
	var close := UI.card(Art.CREAM_DEEP, 999)
	close.custom_minimum_size = Vector2(30, 30)
	var close_style := close.get_theme_stylebox("panel") as StyleBoxFlat
	close_style.content_margin_left = 8
	close_style.content_margin_right = 8
	close_style.content_margin_top = 8
	close_style.content_margin_bottom = 8
	close.add_child(IconView.make("close", 14, Art.INK))
	header.add_child(UI.clickable(close, _close_care, Vector2(30, 30)))

	var row := UI.hbox(18)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)

	var meters := UI.vbox(3)
	meters.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for key: String in GameState.STAT_KEYS:
		var bar := UI.stat_bar(key.capitalize(), GameState.stat(key), Art.STAT_COLORS[key], true)
		_bars[key] = bar
		meters.add_child(bar)
	row.add_child(meters)

	var right := UI.vbox(6)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.4
	row.add_child(right)

	var actions := UI.grid(3, 8)
	right.add_child(actions)
	for action_id: String in CARE_ORDER:
		var action: Dictionary = GameState.ACTIONS[action_id]
		var button := UI.button(String(action.get("label", action_id)), Callable(), Art.CREAM)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 44
		button.pressed.connect(func() -> void: GameState.do_care(action_id))
		_buttons[action_id] = button
		actions.add_child(button)

	var growth := UI.hbox(12)
	right.add_child(growth)
	var bond_bar := UI.stat_bar("Bond", float(GameState.bond()), Art.PINK, true)
	bond_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bars["bond"] = bond_bar
	growth.add_child(bond_bar)

	var next_stage := "full grown"
	if GameState.stage() < GameState.STAGES.size() - 1:
		next_stage = GameState.STAGES[GameState.stage() + 1]
	var stage_bar := StatBar.new()
	stage_bar.label_text = "Growth to %s" % next_stage
	stage_bar.max_value = 1.0
	stage_bar.value = GameState.stage_progress()
	stage_bar.fill_color = Art.SAGE
	stage_bar.show_value = false
	stage_bar.compact = true
	stage_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bars["stage"] = stage_bar
	growth.add_child(stage_bar)
	return card


func _toggle_care() -> void:
	_care_open = not _care_open
	rebuild()


func _close_care() -> void:
	_care_open = false
	rebuild()


func _on_pose_hint(pose: String) -> void:
	if not is_instance_valid(_pet_view):
		return
	_pet_view.set_pose(pose)
	_pose_timer = 3.5


func _update_meters() -> void:
	for key: String in GameState.STAT_KEYS:
		if _bars.has(key):
			(_bars[key] as StatBar).set_value(GameState.stat(key))
	if _bars.has("bond"):
		(_bars["bond"] as StatBar).set_value(float(GameState.bond()))
	if _bars.has("stage"):
		(_bars["stage"] as StatBar).set_value(GameState.stage_progress())


func _update_buttons() -> void:
	for action_id: String in _buttons.keys():
		var button: Button = _buttons[action_id]
		if not is_instance_valid(button):
			continue
		var action: Dictionary = GameState.ACTIONS[action_id]
		var label := String(action.get("label", action_id))
		var cost := int(action.get("cost", 0))
		if cost > 0:
			label += "  %d" % cost
		var left := GameState.cooldown_left(action_id)
		if left > 0.0:
			label = "%s  %ds" % [String(action.get("label", action_id)), int(ceilf(left))]
		button.text = label
		button.disabled = GameState.care_blocked_reason(action_id) != ""


func refresh() -> void:
	rebuild()
	_update_buttons()
