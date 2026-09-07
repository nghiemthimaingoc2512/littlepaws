extends Screen
## The inbox: thank-you notes, badge receipts and gifts.

func _init() -> void:
	scene_key = "home"


func _ready() -> void:
	super()
	if GameState.unread_mail() > 0:
		GameState.read_all_mail()


func build(host: Control) -> void:
	if not GameState.started():
		return
	var column := page(host)
	column.add_child(UI.spacer(74))

	var header := UI.hbox(10)
	header.add_child(UI.icon_row("mail", "Inbox", 34, 30, Art.INK, Art.INK, Art.GOLD))
	header.add_child(UI.spacer())
	if GameState.claimable_mail() > 0:
		header.add_child(UI.pill("%d gift to collect" % GameState.claimable_mail(),
			Art.RED.lerp(Art.WHITE, 0.6), 15))
	column.add_child(header)

	var letters := GameState.mail()
	if letters.is_empty():
		var card := UI.card(Art.WHITE, 24)
		var empty := UI.vbox(6)
		card.add_child(empty)
		empty.add_child(UI.label("Nothing yet", 20, Art.INK))
		empty.add_child(UI.paragraph(
			"Letters arrive when you earn a badge, finish a chapter, or find an animal its forever home.",
			15, Art.INK_SOFT))
		column.add_child(card)
		column.add_child(UI.spacer(94))
		return

	var scroll := UI.scroll()
	column.add_child(scroll)
	var list := UI.vbox(10)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for letter: Dictionary in letters:
		list.add_child(_letter_card(letter))
	list.add_child(UI.spacer(94))


func _letter_card(letter: Dictionary) -> Control:
	var claimed := bool(letter.get("claimed", true))
	var card := UI.card(Art.WHITE if claimed else Art.GOLD.lerp(Art.WHITE, 0.78), 22)

	var row := UI.hbox(12)
	card.add_child(row)
	row.add_child(IconView.make("mail", 30, Art.INK, Art.GOLD))

	var text := UI.vbox(3)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(UI.label(String(letter.get("title", "")), 18, Art.INK))
	text.add_child(UI.paragraph(String(letter.get("body", "")), 14, Art.INK_SOFT))
	text.add_child(UI.label(Time.get_date_string_from_unix_time(int(letter.get("at", 0))),
		12, Art.INK_SOFT))

	var reward: Dictionary = letter.get("reward", {})
	if not reward.is_empty():
		var rewards := UI.hbox(6)
		rewards.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for key: String in ["coins", "gems", "hearts"]:
			if int(reward.get(key, 0)) > 0:
				rewards.add_child(UI.pill("+%d %s" % [int(reward[key]), key],
					Art.CREAM_DEEP, 13))
		row.add_child(rewards)

	if not claimed:
		var claim := UI.button("Collect", Callable(), Art.GOLD)
		claim.custom_minimum_size = Vector2(130, 44)
		var mail_id := String(letter.get("id", ""))
		claim.pressed.connect(func() -> void: GameState.claim_mail(mail_id))
		row.add_child(claim)
	return card
