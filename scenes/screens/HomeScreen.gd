extends Screen
## The room. Your pet, its meters, and the six ways to care for it.

const CARE_ORDER := ["feed", "play", "bathe", "brush", "sleep", "heal"]

var _bars: Dictionary = {}
var _buttons: Dictionary = {}
var _pet_view: CreatureView
var _pose_timer: float = 0.0
var _refresh_accum: float = 0.0


func _init() -> void:
	scene_key = "home"


func _ready() -> void:
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
	_refresh_accum += delta
	if _refresh_accum >= 0.5:
		_refresh_accum = 0.0
		_update_buttons()


func build(host: Control) -> void:
	if not GameState.started():
		return
	_bars.clear()
	_buttons.clear()

	var column := page(host)
	column.add_child(UI.spacer(50))  # clear the top bar

	var body := UI.hbox(18)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)

	body.add_child(_stage_panel())
	body.add_child(_side_panel())

	column.add_child(_care_bar())
	column.add_child(UI.spacer(70))  # clear the nav bar


## --- left: the pet itself ---------------------------------------------

func _stage_panel() -> Control:
	var wrapper := UI.vbox(6)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.size_flags_stretch_ratio = 1.4

	var stage_row := UI.hbox(0)
	stage_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_row.alignment = BoxContainer.ALIGNMENT_CENTER
	wrapper.add_child(stage_row)

	var owner_view := CreatureView.new()
	owner_view.is_owner = true
	owner_view.pose = "idle"
	owner_view.custom_minimum_size = Vector2(170, 170)
	owner_view.size_flags_vertical = Control.SIZE_SHRINK_END
	stage_row.add_child(owner_view)

	_pet_view = UI.creature(GameState.pet_species(), 260.0, GameState.mood_pose())
	_pet_view.size_flags_vertical = Control.SIZE_SHRINK_END
	var accessory := Data.item("accessory", GameState.equipped("accessory"))
	if accessory.has("color"):
		_pet_view.accessory_color = Color(String(accessory["color"]))
	stage_row.add_child(_pet_view)

	var caption := UI.card(Color(1, 1, 1, 0.82), 22)
	caption.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var caption_column := UI.vbox(4)
	caption.add_child(caption_column)
	caption_column.add_child(UI.label("%s  ·  %s" % [GameState.pet_name(), GameState.stage_name()],
		22, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))
	caption_column.add_child(UI.label(_mood_line(), 15, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	wrapper.add_child(caption)
	return wrapper


func _mood_line() -> String:
	var who := GameState.pet_name()
	if GameState.stat("food") < 40.0:
		return "%s keeps glancing at the food bowl." % who
	if GameState.stat("clean") < 40.0:
		return "%s could use a warm bath." % who
	if GameState.stat("energy") < 35.0:
		return "%s is yawning. A nap would help." % who
	if GameState.stat("mood") < 45.0:
		return "%s wants to play with you." % who
	if GameState.wellbeing() > 82.0:
		return "%s is having a wonderful day." % who
	return "%s is comfortable and close by." % who


## --- right: meters, growth, chapter -----------------------------------

func _side_panel() -> Control:
	var scroll := UI.scroll()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := UI.vbox(12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var meters := UI.vbox(6)
	for key: String in GameState.STAT_KEYS:
		var bar := UI.stat_bar(key.capitalize(), GameState.stat(key), Art.STAT_COLORS[key])
		_bars[key] = bar
		meters.add_child(bar)
	column.add_child(UI.section("How %s feels" % GameState.pet_name(), meters))

	var growth := UI.vbox(6)
	var bond_bar := UI.stat_bar("Bond", float(GameState.bond()), Art.PINK)
	_bars["bond"] = bond_bar
	growth.add_child(bond_bar)

	var stage_bar := StatBar.new()
	stage_bar.label_text = "Growth to %s" % (GameState.STAGES[mini(GameState.stage() + 1, 3)] if GameState.stage() < 3 else "full grown")
	stage_bar.max_value = 1.0
	stage_bar.value = GameState.stage_progress()
	stage_bar.fill_color = Art.SAGE
	stage_bar.show_value = false
	_bars["stage"] = stage_bar
	growth.add_child(stage_bar)
	column.add_child(UI.section("Growing up", growth))

	column.add_child(_chapter_card())
	scroll.add_child(column)
	return scroll


func _chapter_card() -> Control:
	var chapter := GameState.current_chapter()
	var inner := UI.vbox(8)
	if chapter.is_empty():
		inner.add_child(UI.paragraph("Every chapter is finished. The world is yours to revisit.",
			15, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, 200.0))
		return UI.section("Journey", inner)

	inner.add_child(UI.label(String(chapter.get("title", "")), 17, Art.INK))
	var next_goal := ""
	for goal: Dictionary in chapter.get("goals", []):
		if not GameState.goal_done(goal):
			next_goal = "%s  (%d/%d)" % [String(goal.get("text", "")),
				GameState.goal_progress(goal), GameState.goal_target(goal)]
			break
	inner.add_child(UI.paragraph(next_goal if next_goal != "" else "All goals met.", 15, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, 200.0))

	var open := UI.button("Open the journey", func() -> void: goto("journey"), Art.CREAM)
	inner.add_child(open)
	return UI.section("Journey", inner)


## --- bottom: care actions ---------------------------------------------

func _care_bar() -> Control:
	var card := UI.card(Color(1, 1, 1, 0.9), 24)
	var row := UI.hbox(10)
	card.add_child(row)
	for action_id: String in CARE_ORDER:
		var action: Dictionary = GameState.ACTIONS[action_id]
		var button := UI.button(String(action.get("label", action_id)), Callable(), Art.CREAM)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 56
		button.pressed.connect(func() -> void: _do_care(action_id))
		_buttons[action_id] = button
		row.add_child(button)
	return card


func _do_care(action_id: String) -> void:
	GameState.do_care(action_id)


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
