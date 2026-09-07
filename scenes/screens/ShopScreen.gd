extends Screen
## Pantry, wardrobe and room decor. Coins come from the journey; gems come
## from badges and from finding forever homes.

const TABS := [
	{"id": "food", "label": "Pantry"},
	{"id": "outfit", "label": "Your outfits"},
	{"id": "accessory", "label": "Pet accessories"},
	{"id": "decor", "label": "Room decor"},
]

var _tab: String = "food"


func _init() -> void:
	scene_key = "mall"


func build(host: Control) -> void:
	if not GameState.started():
		return
	var column := page(host)
	column.add_child(UI.spacer(74))

	var header := UI.hbox(10)
	header.add_child(UI.label("Paw & Co.", 30, Art.INK))
	header.add_child(UI.spacer())
	header.add_child(_free_coins_card())
	column.add_child(header)

	var tabs := UI.hbox(8)
	for tab: Dictionary in TABS:
		var id := String(tab["id"])
		var button := UI.button(String(tab["label"]), Callable(),
			Art.PINK if id == _tab else Art.WHITE)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void:
			_tab = id
			rebuild()
		)
		tabs.add_child(button)
	column.add_child(tabs)

	var scroll := UI.scroll()
	column.add_child(scroll)
	var grid := UI.grid(4, 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	var group: Dictionary = Data.items.get(_tab, {})
	for item_id: String in group.keys():
		grid.add_child(_item_card(item_id, group[item_id]))
	column.add_child(UI.spacer(94))


func _free_coins_card() -> Control:
	var card := UI.card(Art.SAGE.lerp(Art.WHITE, 0.5), 20)
	var row := UI.hbox(10)
	card.add_child(row)
	row.add_child(UI.label("Short on coins? Watch a short video.", 15, Art.INK))
	var button := UI.button(
		"Watch  +%d" % GameState.AD_REWARD_COINS if GameState.ad_available() else "Come back soon",
		Callable(), Art.WHITE)
	button.disabled = not GameState.ad_available()
	button.custom_minimum_size = Vector2(150, 40)
	button.pressed.connect(func() -> void:
		if main != null:
			main.show_rewarded_video(func() -> void: GameState.grant_ad_reward())
	)
	row.add_child(button)
	return card


func _item_card(item_id: String, item: Dictionary) -> Control:
	var is_food := _tab == "food"
	var owned := GameState.owns(item_id)
	var equipped := GameState.equipped(_tab) == item_id
	var price := int(item.get("price", 0))
	var currency := String(item.get("currency", "coins"))

	var card := UI.card(Art.PINK.lerp(Art.WHITE, 0.62) if equipped else Art.WHITE, 22)
	card.custom_minimum_size = Vector2(170, 200)
	var inner := UI.vbox(6)
	card.add_child(inner)

	var swatch := UI.card(Color(String(item.get("color", item.get("sky", "#f6ead9")))), 16)
	swatch.custom_minimum_size = Vector2(0, 62)
	inner.add_child(swatch)

	inner.add_child(UI.label(String(item.get("name", item_id)), 16, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))

	if is_food:
		var held := int((GameState.save.get("inventory", {}) as Dictionary).get(item_id, 0))
		inner.add_child(UI.label("In the pantry: %d" % held, 13, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
		if item_id == String(Data.get_species(GameState.pet_species()).get("favorite", "")):
			inner.add_child(UI.pill("%s's favourite" % GameState.pet_name(), Art.PINK.lerp(Art.WHITE, 0.4), 12))
		var buy := UI.button("Buy  %d" % price, Callable(), Art.CREAM)
		buy.custom_minimum_size.y = 40
		buy.disabled = not GameState.can_afford(price, "coins")
		buy.pressed.connect(func() -> void: GameState.buy_food(item_id, 1))
		inner.add_child(buy)

		var buy_five := UI.button("Buy 5  %d" % (price * 5), Callable(), Art.CREAM)
		buy_five.custom_minimum_size.y = 36
		buy_five.disabled = not GameState.can_afford(price * 5, "coins")
		buy_five.pressed.connect(func() -> void: GameState.buy_food(item_id, 5))
		inner.add_child(buy_five)
		return card

	inner.add_child(UI.spacer(2))
	if equipped:
		inner.add_child(UI.pill("Wearing", Art.PINK.lerp(Art.WHITE, 0.35), 13))
	elif owned:
		var wear := UI.button("Wear", Callable(), Art.CREAM)
		wear.custom_minimum_size.y = 42
		wear.pressed.connect(func() -> void: GameState.equip(item_id))
		inner.add_child(wear)
	else:
		var label := "%d %s" % [price, "gems" if currency == "gems" else "coins"]
		var buy := UI.button(label, Callable(), Art.CREAM)
		buy.custom_minimum_size.y = 42
		buy.disabled = not GameState.can_afford(price, currency)
		buy.pressed.connect(func() -> void: GameState.buy(_tab, item_id))
		inner.add_child(buy)
	return card
