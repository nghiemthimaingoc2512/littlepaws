extends Screen
## The collection. Every animal in the world, discovered or still a silhouette.

var _selected: String = ""


func _init() -> void:
	scene_key = "home"


func build(host: Control) -> void:
	if not GameState.started():
		return
	var column := page(host)
	column.add_child(UI.spacer(50))

	var all_ids: Array = Data.rescuable_ids()
	var header := UI.hbox(10)
	header.add_child(UI.label("Library", 30, Art.INK))
	header.add_child(UI.spacer())
	header.add_child(UI.pill("%d / %d rescued" % [GameState.rescued_count(), all_ids.size()],
		Art.SAGE.lerp(Art.WHITE, 0.4), 15))
	header.add_child(UI.pill("%d homed" % GameState.homed_count(), Art.PINK.lerp(Art.WHITE, 0.5), 15))
	column.add_child(header)

	var body := UI.hbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)

	var scroll := UI.scroll()
	scroll.size_flags_stretch_ratio = 1.6
	body.add_child(scroll)
	var grid := UI.grid(4, 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	grid.add_child(_entry_card(GameState.pet_species(), true))
	for id: String in all_ids:
		grid.add_child(_entry_card(id, false))

	body.add_child(_detail_panel())
	column.add_child(UI.spacer(62))


func _entry_card(species_id: String, is_companion: bool) -> Control:
	var known := is_companion or GameState.is_rescued(species_id)
	var info := Data.get_species(species_id)
	var rarity := String(info.get("rarity", "common"))

	var fill := Art.WHITE if known else Color(0.95, 0.93, 0.90)
	var card := UI.card(fill, 22)
	card.custom_minimum_size = Vector2(150, 176)

	var inner := UI.vbox(4)
	card.add_child(inner)

	var view := UI.creature(species_id, 84.0, "idle")
	view.silhouette = not known
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(view)

	inner.add_child(UI.label(String(info.get("name", "???")) if known else "? ? ?",
		15, Art.INK if known else Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))

	if known:
		var tag := "Companion" if is_companion else ("Homed" if GameState.is_homed(species_id) else "In sanctuary")
		inner.add_child(UI.pill(tag, Art.rarity_color(rarity).lerp(Art.WHITE, 0.4), 12))
		var open := UI.button("Read", Callable(), Art.CREAM)
		open.custom_minimum_size.y = 34
		open.pressed.connect(func() -> void:
			_selected = species_id
			rebuild()
		)
		inner.add_child(open)
	else:
		inner.add_child(UI.pill("Not found yet", Art.CREAM_DEEP, 12))
	return card


func _detail_panel() -> Control:
	var card := UI.card(Color(1, 1, 1, 0.94), 26)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := UI.vbox(10)
	card.add_child(inner)

	if _selected.is_empty():
		inner.add_child(UI.paragraph("Pick an animal to read their story.", 17, Art.INK_SOFT))
		inner.add_child(UI.paragraph(
			"Silhouettes are animals still out in the world. Follow the journey to meet them.",
			15, Art.INK_SOFT))
		return card

	var info := Data.get_species(_selected)
	inner.add_child(UI.creature(_selected, 150.0, "happy"))
	inner.add_child(UI.label(String(info.get("name", _selected)), 24, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))
	inner.add_child(UI.pill(String(info.get("rarity", "common")).capitalize(),
		Art.rarity_color(String(info.get("rarity", "common"))).lerp(Art.WHITE, 0.35)))
	inner.add_child(UI.paragraph(String(info.get("bio", "")), 15, Art.INK_SOFT))

	var traits := UI.hbox(6)
	traits.alignment = BoxContainer.ALIGNMENT_CENTER
	for trait_name: String in info.get("traits", []):
		traits.add_child(UI.pill(trait_name, Art.SKY.lerp(Art.WHITE, 0.45)))
	inner.add_child(traits)

	if _selected == GameState.pet_species():
		inner.add_child(UI.label("Your companion since day one.", 15, Art.PINK_DEEP,
			HORIZONTAL_ALIGNMENT_CENTER))
		return card

	var entry := GameState.entry(_selected)
	if entry.is_empty():
		return card

	var rescued_on := Time.get_date_string_from_unix_time(int(entry.get("rescued", 0)))
	inner.add_child(UI.label("Rescued on %s" % rescued_on, 14, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))

	if GameState.is_homed(_selected):
		var friend := Data.npc(String(entry.get("friend", "")))
		inner.add_child(UI.label("Living with %s" % String(friend.get("name", "a friend")),
			17, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))
		inner.add_child(UI.paragraph(String(friend.get("blurb", "")), 14, Art.INK_SOFT,
			HORIZONTAL_ALIGNMENT_CENTER, 220.0))
	else:
		inner.add_child(UI.label("Still in the sanctuary  ·  trust %d%%" % GameState.trust(_selected),
			15, Art.PINK_DEEP, HORIZONTAL_ALIGNMENT_CENTER))
		var visit := UI.button("Visit them", Callable(), Art.PINK)
		visit.custom_minimum_size.y = 44
		var target := _selected
		visit.pressed.connect(func() -> void: goto("sanctuary", {"species": target}))
		inner.add_child(visit)
	return card
