extends Screen
## The bag: what you are carrying and what you own.

const SECTIONS := [
	{"category": "food", "title": "Pantry"},
	{"category": "outfit", "title": "Your outfits"},
	{"category": "accessory", "title": "Pet accessories"},
	{"category": "decor", "title": "Room decor"},
]


func _init() -> void:
	scene_key = "home"


func build(host: Control) -> void:
	if not GameState.started():
		return
	var column := page(host)
	column.add_child(UI.spacer(74))

	var header := UI.hbox(10)
	header.add_child(UI.icon_row("bag", "Bag", 34, 30, Art.INK, Art.INK, Art.SAGE))
	header.add_child(UI.spacer())
	header.add_child(UI.pill("%d meals in the pantry" % GameState.food_count(),
		Art.GOLD.lerp(Art.WHITE, 0.5), 15))
	var shop := UI.button("Go to the shop", Callable(), Art.CREAM)
	shop.custom_minimum_size = Vector2(180, 40)
	shop.pressed.connect(func() -> void: goto("shop"))
	header.add_child(shop)
	column.add_child(header)

	var scroll := UI.scroll()
	column.add_child(scroll)
	var list := UI.vbox(14)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for section: Dictionary in SECTIONS:
		list.add_child(_section(String(section["category"]), String(section["title"])))
	list.add_child(UI.spacer(94))


func _section(category: String, title: String) -> Control:
	var card := UI.card(Art.WHITE, 24)
	var column := UI.vbox(8)
	card.add_child(column)
	column.add_child(UI.label(title, 20, Art.INK))

	var owned_ids: Array = []
	var group: Dictionary = Data.items.get(category, {})
	for item_id: String in group.keys():
		if category == "food":
			if int((GameState.save.get("inventory", {}) as Dictionary).get(item_id, 0)) > 0:
				owned_ids.append(item_id)
		elif GameState.owns(item_id):
			owned_ids.append(item_id)

	if owned_ids.is_empty():
		column.add_child(UI.paragraph("Nothing here yet. The shop has some.", 14, Art.INK_SOFT))
		return card

	var grid := UI.grid(5, 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(grid)
	for item_id: String in owned_ids:
		grid.add_child(_item_card(category, item_id, group[item_id]))
	return card


func _item_card(category: String, item_id: String, item: Dictionary) -> Control:
	var equipped := category != "food" and GameState.equipped(category) == item_id
	var card := UI.card(Art.GOLD_SOFT if equipped else Art.CREAM, 18)
	card.custom_minimum_size = Vector2(150, 0)

	var column := UI.vbox(5)
	card.add_child(column)

	var swatch := UI.card(Color(String(item.get("color", item.get("sky", "#f6ead9")))), 14)
	swatch.custom_minimum_size = Vector2(0, 46)
	column.add_child(swatch)
	column.add_child(UI.label(String(item.get("name", item_id)), 15, Art.INK,
		HORIZONTAL_ALIGNMENT_CENTER))

	if category == "food":
		var held := int((GameState.save.get("inventory", {}) as Dictionary).get(item_id, 0))
		column.add_child(UI.pill("x%d" % held, Art.WHITE, 13))
		return card

	if equipped:
		column.add_child(UI.pill("in use", Art.GOLD.lerp(Art.WHITE, 0.3), 13))
	else:
		var wear := UI.button("Use", Callable(), Art.WHITE)
		wear.custom_minimum_size.y = 38
		wear.pressed.connect(func() -> void: GameState.equip(item_id))
		column.add_child(wear)
	return card
