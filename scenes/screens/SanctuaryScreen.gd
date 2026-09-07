extends Screen
## Where rescued animals stay until they trust you, and until you find the
## person they will spend their life with.

var _selected: String = ""
var _matching: bool = false


func _init() -> void:
	scene_key = "meadow"


func _ready() -> void:
	_selected = String(args.get("species", ""))
	super()


func build(host: Control) -> void:
	if not GameState.started():
		return
	var column := page(host)
	column.add_child(UI.spacer(74))

	var waiting: Array = GameState.sanctuary_ids()
	if _selected.is_empty() or not waiting.has(_selected):
		_selected = String(waiting[0]) if not waiting.is_empty() else ""

	var header := UI.hbox(10)
	header.add_child(UI.label("Sanctuary", 30, Art.INK))
	header.add_child(UI.spacer())
	header.add_child(UI.pill("%d waiting  ·  %d homed" % [waiting.size(), GameState.homed_count()],
		Art.SAGE.lerp(Art.WHITE, 0.4), 15))
	column.add_child(header)

	if waiting.is_empty():
		column.add_child(_empty_state())
		column.add_child(UI.spacer(94))
		return

	var body := UI.hbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	body.add_child(_waiting_list(waiting))
	body.add_child(_detail_panel())
	column.add_child(UI.spacer(94))


func _empty_state() -> Control:
	var card := UI.card(Art.WHITE, 24)
	var inner := UI.vbox(10)
	card.add_child(inner)
	inner.add_child(UI.label("The sanctuary is quiet right now.", 20, Art.INK))
	inner.add_child(UI.paragraph(
		"Every animal you rescued has found their person. Head out on the journey to find someone new.",
		15, Art.INK_SOFT))
	var go := UI.button("Open the journey", Callable(), Art.PINK)
	go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	go.custom_minimum_size = Vector2(220, 46)
	go.pressed.connect(func() -> void: goto("journey"))
	inner.add_child(go)
	return card


func _waiting_list(waiting: Array) -> Control:
	var scroll := UI.scroll()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 0.8
	var list := UI.vbox(8)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for id: String in waiting:
		var selected := id == _selected
		var card := UI.card(Art.PINK.lerp(Art.WHITE, 0.6) if selected else Art.WHITE, 20)
		var row := UI.hbox(10)
		card.add_child(row)
		row.add_child(UI.creature(id, 68.0, "idle"))

		var text := UI.vbox(2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(UI.label(Data.species_name(id), 17, Art.INK))
		var trust_bar := UI.stat_bar("Trust %d%%" % GameState.trust(id), float(GameState.trust(id)), Art.PINK, true)
		trust_bar.show_value = false
		text.add_child(trust_bar)
		row.add_child(text)

		var pick := UI.button("Visit", Callable(), Art.CREAM)
		pick.custom_minimum_size = Vector2(90, 40)
		pick.pressed.connect(func() -> void:
			_selected = id
			_matching = false
			rebuild()
		)
		row.add_child(pick)
		list.add_child(card)
	return scroll


func _detail_panel() -> Control:
	var card := UI.card(Color(1, 1, 1, 0.94), 26)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.2
	var inner := UI.vbox(10)
	card.add_child(inner)

	if _selected.is_empty():
		inner.add_child(UI.label("Choose an animal to care for.", 17, Art.INK_SOFT))
		return card

	var info := Data.get_species(_selected)
	var tamed := GameState.is_tamed(_selected)

	var head := UI.hbox(12)
	inner.add_child(head)
	head.add_child(UI.creature(_selected, 120.0, "happy" if tamed else "peek"))
	var head_text := UI.vbox(4)
	head_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(head_text)
	head_text.add_child(UI.label(String(info.get("name", _selected)), 24, Art.INK))
	head_text.add_child(UI.paragraph(String(info.get("bio", "")), 15, Art.INK_SOFT))
	var traits := UI.hbox(6)
	for trait_name: String in info.get("traits", []):
		traits.add_child(UI.pill(trait_name, Art.SKY.lerp(Art.WHITE, 0.45)))
	traits.add_child(UI.spacer())
	head_text.add_child(traits)

	var trust_bar := UI.stat_bar("Trust", float(GameState.trust(_selected)), Art.PINK)
	inner.add_child(trust_bar)

	if _matching:
		inner.add_child(_match_panel())
		return card

	if tamed:
		inner.add_child(UI.paragraph(
			"%s is ready. Somewhere out there is a person who has been waiting for them."
			% String(info.get("name", _selected)), 16, Art.INK))
		var find := UI.button("Find a forever friend", Callable(), Art.PINK)
		find.custom_minimum_size.y = 50
		find.pressed.connect(func() -> void:
			_matching = true
			rebuild()
		)
		inner.add_child(find)
		return card

	inner.add_child(UI.paragraph(String(info.get("hint", "")), 15, Art.PINK_DEEP))
	var row := UI.hbox(10)
	inner.add_child(row)
	for action_id: String in GameState.TAME_ACTIONS.keys():
		var action: Dictionary = GameState.TAME_ACTIONS[action_id]
		var button := UI.button(String(action.get("label", action_id)), Callable(), Art.CREAM)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 52
		button.disabled = GameState.tame_blocked_reason(_selected, action_id) != ""
		var target := _selected
		button.pressed.connect(func() -> void: GameState.do_tame(target, action_id))
		row.add_child(button)
	return card


func _match_panel() -> Control:
	var column := UI.vbox(10)
	column.add_child(UI.label("Who should they go home with?", 20, Art.INK))
	column.add_child(UI.paragraph(
		"Every one of these people would love them. A closer match simply makes for a sweeter story.",
		14, Art.INK_SOFT))

	var row := UI.hbox(10)
	column.add_child(row)
	for npc: Dictionary in GameState.friend_candidates(_selected):
		row.add_child(_npc_card(npc))

	var back := UI.button("Not yet", Callable(), Art.CREAM)
	back.pressed.connect(func() -> void:
		_matching = false
		rebuild()
	)
	column.add_child(back)
	return column


func _npc_card(npc: Dictionary) -> Control:
	var npc_id := String(npc.get("id", ""))
	var score := GameState.match_score(_selected, npc_id)
	var card := UI.card(Color(String(npc.get("color", "#ffffff"))).lerp(Art.WHITE, 0.62), 22)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var inner := UI.vbox(6)
	card.add_child(inner)
	inner.add_child(UI.label(String(npc.get("name", "Friend")), 20, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))
	inner.add_child(UI.paragraph(String(npc.get("blurb", "")), 14, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, 170.0))

	var likes := UI.hbox(4)
	likes.alignment = BoxContainer.ALIGNMENT_CENTER
	for like: String in npc.get("likes", []):
		likes.add_child(UI.pill(like, Art.CREAM_DEEP))
	inner.add_child(likes)

	inner.add_child(UI.label(_match_text(score), 14, Art.PINK_DEEP, HORIZONTAL_ALIGNMENT_CENTER))

	var choose := UI.button("They belong together", Callable(), Art.PINK)
	choose.custom_minimum_size.y = 46
	var target := _selected
	choose.pressed.connect(func() -> void:
		GameState.home_animal(target, npc_id)
		_matching = false
		_selected = ""
		rebuild()
	)
	inner.add_child(choose)
	return card


func _match_text(score: float) -> String:
	if score >= 0.95:
		return "A perfect fit"
	if score >= 0.65:
		return "A warm match"
	return "A gentle match"
