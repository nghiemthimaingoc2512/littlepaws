extends Screen
## Events: whoever is out there needing help right now.

func _init() -> void:
	scene_key = "meadow"


func _ready() -> void:
	var chapter := GameState.current_chapter()
	if not chapter.is_empty():
		scene_key = String(chapter.get("scene", "meadow"))
	super()


func build(host: Control) -> void:
	if not GameState.started():
		return
	var column := page(host)
	column.add_child(UI.spacer(74))

	var header := UI.hbox(10)
	header.add_child(UI.icon_row("sparkle", "Events", 34, 30, Art.INK, Art.INK, Art.GOLD))
	header.add_child(UI.spacer())
	header.add_child(UI.pill("%d homed  ·  %d rescued" % [GameState.homed_count(),
		GameState.rescued_count()], Art.SAGE.lerp(Art.WHITE, 0.4), 15))
	column.add_child(header)

	var chapter := GameState.current_chapter()
	if chapter.is_empty():
		column.add_child(_quiet_card("You have been everywhere",
			"Every region is finished. Your library is the record of it."))
		column.add_child(UI.spacer(94))
		return

	var intro := UI.card(Art.WHITE, 24)
	var intro_column := UI.vbox(6)
	intro.add_child(intro_column)
	intro_column.add_child(UI.label(String(chapter.get("title", "")), 22, Art.INK))
	intro_column.add_child(UI.paragraph(String(chapter.get("intro", "")), 15, Art.INK_SOFT))
	column.add_child(intro)

	var missions: Array = GameState.available_missions()
	if missions.is_empty():
		column.add_child(_quiet_card("Nobody is waiting out there",
			"Everyone in this region is safe. Look after them in the sanctuary and the next region opens."))
		var open := UI.button("Go to the sanctuary", Callable(), Art.GOLD)
		open.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		open.custom_minimum_size = Vector2(240, 46)
		open.pressed.connect(func() -> void: goto("sanctuary"))
		column.add_child(open)
		column.add_child(UI.spacer(94))
		return

	var row := UI.hbox(14)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	for species_id: String in missions:
		row.add_child(_mission_card(species_id))
	column.add_child(UI.spacer(94))


func _quiet_card(title: String, body: String) -> Control:
	var card := UI.card(Art.WHITE, 24)
	var column := UI.vbox(6)
	card.add_child(column)
	column.add_child(UI.label(title, 20, Art.INK))
	column.add_child(UI.paragraph(body, 15, Art.INK_SOFT))
	return card


func _mission_card(species_id: String) -> Control:
	var info := Data.get_species(species_id)
	var card := UI.card(Art.WHITE, 24)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var column := UI.vbox(8)
	card.add_child(column)

	var view := UI.creature(species_id, 140.0, "peek")
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(view)
	column.add_child(UI.label(String(info.get("name", species_id)), 20, Art.INK,
		HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UI.pill(String(info.get("rarity", "common")).capitalize(),
		Art.rarity_color(String(info.get("rarity", "common"))).lerp(Art.WHITE, 0.4), 13))
	column.add_child(UI.paragraph(String(info.get("bio", "")), 14, Art.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER, 180.0))

	var go := UI.button("Go find them", Callable(), Art.GOLD)
	go.custom_minimum_size.y = 46
	go.pressed.connect(func() -> void: goto("rescue", {"species": species_id}))
	column.add_child(go)
	return card
