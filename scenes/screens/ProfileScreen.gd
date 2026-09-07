extends Screen
## Player and pet profile, streaks, and the few settings the game needs.

var _confirm_reset: bool = false


func _init() -> void:
	scene_key = "home"


func build(host: Control) -> void:
	if not GameState.started():
		return
	var column := page(host)
	column.add_child(UI.spacer(74))
	column.add_child(UI.label("Profile", 30, Art.INK))

	var body := UI.hbox(16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	body.add_child(_owner_card())
	body.add_child(_pet_card())
	body.add_child(_stats_card())
	column.add_child(UI.spacer(94))


func _owner_card() -> Control:
	var card := UI.card(Art.WHITE, 24)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := UI.vbox(8)
	card.add_child(inner)

	var view := CreatureView.new()
	view.is_owner = true
	view.custom_minimum_size = Vector2(150, 150)
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(view)

	inner.add_child(UI.label(GameState.owner_name(), 24, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))
	inner.add_child(UI.label("Wearing %s" % Data.item_name("outfit", GameState.equipped("outfit")),
		15, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	inner.add_child(UI.pill("Day %d in a row" % GameState.streak(), Art.PINK.lerp(Art.WHITE, 0.45), 14))

	var wardrobe := UI.button("Open the wardrobe", Callable(), Art.CREAM)
	wardrobe.pressed.connect(func() -> void: goto("shop"))
	inner.add_child(wardrobe)
	return card


func _pet_card() -> Control:
	var card := UI.card(Art.WHITE, 24)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := UI.vbox(8)
	card.add_child(inner)

	var info := Data.get_species(GameState.pet_species())
	var view := UI.creature(GameState.pet_species(), 150.0, "happy")
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(view)

	inner.add_child(UI.label(GameState.pet_name(), 24, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))
	inner.add_child(UI.label("%s  ·  %s" % [String(info.get("name", "")), GameState.stage_name()],
		15, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))

	var days := int((GameState._now() - int(GameState.pet().get("born", GameState._now()))) / 86400)
	inner.add_child(UI.label("Together for %d day%s" % [days, "" if days == 1 else "s"],
		15, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))

	var bond := UI.stat_bar("Bond", float(GameState.bond()), Art.PINK)
	inner.add_child(bond)
	inner.add_child(UI.label("Wearing %s" % Data.item_name("accessory", GameState.equipped("accessory")),
		14, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	return card


func _stats_card() -> Control:
	var card := UI.card(Art.WHITE, 24)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var inner := UI.vbox(8)
	card.add_child(inner)

	inner.add_child(UI.label("Your record", 20, Art.INK))
	var rows := [
		["Care moments", str(GameState.counter("care_total"))],
		["Animals rescued", "%d / %d" % [GameState.rescued_count(), Data.rescuable_ids().size()]],
		["Forever homes found", str(GameState.homed_count())],
		["Chapters complete", "%d / %d" % [GameState.chapters_done(), Data.chapter_count()]],
		["Badges earned", "%d / %d" % [GameState.badges_earned(), Data.badges.size()]],
		["Coins earned all-time", str(GameState.counter("coins_earned"))],
		["Room", Data.item_name("decor", GameState.equipped("decor"))],
	]
	for row_data: Array in rows:
		var row := UI.hbox(8)
		row.add_child(UI.label(String(row_data[0]), 15, Art.INK_SOFT))
		row.add_child(UI.spacer())
		row.add_child(UI.label(String(row_data[1]), 15, Art.INK, HORIZONTAL_ALIGNMENT_RIGHT))
		inner.add_child(row)

	inner.add_child(UI.spacer(8))
	inner.add_child(UI.paragraph("Little Paws saves automatically. Come and go as you like.",
		13, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, 200.0))

	if not _confirm_reset:
		var reset := UI.button("Start over", Callable(), Art.CREAM)
		reset.pressed.connect(func() -> void:
			_confirm_reset = true
			rebuild()
		)
		inner.add_child(reset)
		return card

	inner.add_child(UI.paragraph(
		"Starting over erases %s, your library, your badges and everything you have collected."
		% GameState.pet_name(), 14, Art.PINK_DEEP, HORIZONTAL_ALIGNMENT_LEFT, 200.0))
	var row := UI.hbox(8)
	inner.add_child(row)

	var cancel := UI.button("Keep everything", Callable(), Art.SAGE.lerp(Art.WHITE, 0.3))
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(func() -> void:
		_confirm_reset = false
		rebuild()
	)
	row.add_child(cancel)

	var confirm := UI.button("Erase and start over", Callable(), Art.PINK)
	confirm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm.pressed.connect(func() -> void:
		GameState.delete_save()
		goto("onboarding")
	)
	row.add_child(confirm)
	return card
