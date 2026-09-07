extends Screen
## First run: name yourself, choose the one pet you will raise, and make the
## promise. The choice is deliberately framed as a long commitment.

var _step: int = 0
var _owner_name: String = ""
var _species_id: String = ""
var _pet_name: String = ""


func _init() -> void:
	show_chrome = false
	scene_key = "home"


func build(host: Control) -> void:
	var column := page(host, 40)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	match _step:
		0: _build_welcome(column)
		1: _build_choose(column)
		_: _build_promise(column)


func refresh() -> void:
	pass  # Onboarding owns its own flow; save changes must not reset it.


func _build_welcome(column: VBoxContainer) -> void:
	var card := UI.card(Art.WHITE, 30)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.custom_minimum_size = Vector2(620, 0)
	column.add_child(card)

	var inner := UI.vbox(14)
	card.add_child(inner)
	inner.add_child(UI.label("Little Paws", 44, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))
	inner.add_child(UI.paragraph(
		"A quiet place to raise one small friend, and to help every animal you meet along the way.\n\nNothing here can be lost. Come back whenever you like.",
		17, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, 540.0))

	var name_field := LineEdit.new()
	name_field.placeholder_text = "What should we call you?"
	name_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_field.custom_minimum_size.y = 48
	name_field.max_length = 16
	inner.add_child(name_field)

	var next := UI.button("Begin", Callable(), Art.PINK)
	next.custom_minimum_size = Vector2(240, 52)
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.pressed.connect(func() -> void:
		_owner_name = name_field.text.strip_edges()
		if _owner_name.is_empty():
			_owner_name = "Friend"
		_step = 1
		rebuild()
	)
	inner.add_child(next)


func _build_choose(column: VBoxContainer) -> void:
	column.add_child(UI.label("Choose your one pet", 34, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UI.paragraph(
		"You will raise this friend for the whole journey. Pick the one you want to wake up to.",
		16, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, 620.0))

	var row := UI.hbox(16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)

	for id: String in Data.starter_ids():
		row.add_child(_starter_card(id))


func _starter_card(id: String) -> Control:
	var info := Data.get_species(id)
	var selected := id == _species_id
	var card := UI.card(Art.PINK.lerp(Art.WHITE, 0.55) if selected else Art.WHITE, 26)
	card.custom_minimum_size = Vector2(280, 0)

	var inner := UI.vbox(8)
	card.add_child(inner)

	var view := UI.creature(id, 168.0)
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(view)
	inner.add_child(UI.label(String(info.get("name", id)), 22, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))

	var traits := UI.hbox(6)
	traits.alignment = BoxContainer.ALIGNMENT_CENTER
	for trait_name: String in info.get("traits", []):
		traits.add_child(UI.pill(trait_name, Art.SAGE.lerp(Art.WHITE, 0.4)))
	inner.add_child(traits)
	inner.add_child(UI.paragraph(String(info.get("bio", "")), 14, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, 230.0))

	var pick := UI.button("Choose" if not selected else "Chosen", Callable(),
		Art.PINK if selected else Art.CREAM)
	pick.custom_minimum_size.y = 46
	pick.pressed.connect(func() -> void:
		_species_id = id
		_step = 2
		rebuild()
	)
	inner.add_child(pick)
	return card


func _build_promise(column: VBoxContainer) -> void:
	var info := Data.get_species(_species_id)
	var card := UI.card(Art.WHITE, 30)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.custom_minimum_size = Vector2(640, 0)
	column.add_child(card)

	var inner := UI.vbox(12)
	card.add_child(inner)

	var view := UI.creature(_species_id, 190.0, "happy")
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(view)
	inner.add_child(UI.label("Give them a name", 30, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))

	var name_field := LineEdit.new()
	name_field.placeholder_text = "Your %s's name" % String(info.get("kind", "pet")).to_lower()
	name_field.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_field.custom_minimum_size.y = 48
	name_field.max_length = 14
	inner.add_child(name_field)

	inner.add_child(UI.paragraph(
		"I promise to feed them, keep them clean, play with them, and come back to them.",
		16, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))

	var buttons := UI.hbox(10)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_child(buttons)

	var back := UI.button("Choose again", Callable(), Art.CREAM)
	back.custom_minimum_size = Vector2(180, 50)
	back.pressed.connect(func() -> void:
		_step = 1
		rebuild()
	)
	buttons.add_child(back)

	var start := UI.button("I promise", Callable(), Art.PINK)
	start.custom_minimum_size = Vector2(220, 50)
	start.pressed.connect(func() -> void:
		_pet_name = name_field.text.strip_edges()
		if _pet_name.is_empty():
			_pet_name = String(info.get("kind", "Pet"))
		GameState.new_game(_species_id, _pet_name, _owner_name)
		GameState.daily_check()
		goto("home")
	)
	buttons.add_child(start)
