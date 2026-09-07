extends Screen
## Missions: what the current chapter is asking for, and every badge.

func _init() -> void:
	scene_key = "home"


func _ready() -> void:
	super()
	GameState.mark_seen("missions")


func build(host: Control) -> void:
	if not GameState.started():
		return
	var column := page(host)
	column.add_child(UI.spacer(74))

	var header := UI.hbox(10)
	header.add_child(UI.icon_row("trophy", "Missions", 34, 30, Art.INK, Art.INK, Art.GOLD))
	header.add_child(UI.spacer())
	header.add_child(UI.pill("%d / %d badges" % [GameState.badges_earned(), Data.badges.size()],
		Art.GOLD.lerp(Art.WHITE, 0.5), 15))
	column.add_child(header)

	var scroll := UI.scroll()
	column.add_child(scroll)
	var list := UI.vbox(12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	list.add_child(_chapter_card())
	list.add_child(UI.label("Badges", 22, Art.INK))
	var grid := UI.grid(3, 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_child(grid)
	for badge: Dictionary in Data.badges:
		grid.add_child(_badge_card(badge))
	list.add_child(UI.spacer(94))


func _chapter_card() -> Control:
	var chapter := GameState.current_chapter()
	var card := UI.card(Art.WHITE, 24)
	var column := UI.vbox(8)
	card.add_child(column)

	if chapter.is_empty():
		column.add_child(UI.label("Every chapter is finished", 20, Art.INK))
		column.add_child(UI.paragraph("The world is yours to revisit whenever you like.",
			15, Art.INK_SOFT))
		return card

	column.add_child(UI.label("Right now: %s" % String(chapter.get("title", "")), 20, Art.INK))
	for goal: Dictionary in chapter.get("goals", []):
		var done := GameState.goal_done(goal)
		var row := UI.hbox(10)
		row.add_child(IconView.make("check" if done else "paw", 20,
			Art.SAGE.darkened(0.2) if done else Art.INK_SOFT))
		var text := String(goal.get("text", ""))
		var target := GameState.goal_target(goal)
		if target > 1:
			text += "   %d / %d" % [mini(GameState.goal_progress(goal), target), target]
		var text_label := UI.paragraph(text, 16, Art.INK_SOFT if done else Art.INK,
			HORIZONTAL_ALIGNMENT_LEFT, 200.0)
		row.add_child(text_label)
		column.add_child(row)

	var open := UI.button("Open the map", Callable(), Art.CREAM)
	open.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	open.custom_minimum_size = Vector2(200, 44)
	open.pressed.connect(func() -> void: goto("journey"))
	column.add_child(open)
	return card


func _badge_card(badge: Dictionary) -> Control:
	var id := String(badge.get("id", ""))
	var earned := GameState.has_badge(id)
	var target := maxi(1, int(badge.get("target", 1)))
	var progress := mini(GameState.badge_progress(badge), target)

	var card := UI.card(Art.GOLD.lerp(Art.WHITE, 0.74) if earned else Art.WHITE, 22)
	var inner := UI.vbox(6)
	card.add_child(inner)

	var head := UI.hbox(8)
	inner.add_child(head)
	head.add_child(IconView.make("trophy", 24, Art.INK,
		Art.GOLD if earned else Art.CREAM_DEEP))
	head.add_child(UI.label(String(badge.get("name", id)), 18, Art.INK))
	head.add_child(UI.spacer())
	head.add_child(UI.pill("+%d" % int(badge.get("gems", 0)), Art.SKY.lerp(Art.WHITE, 0.45), 12))

	inner.add_child(UI.paragraph(String(badge.get("text", "")), 14, Art.INK_SOFT,
		HORIZONTAL_ALIGNMENT_LEFT, 190.0))

	var bar := StatBar.new()
	bar.label_text = "Earned" if earned else "Progress"
	bar.max_value = float(target)
	bar.value = float(progress)
	bar.fill_color = Art.GOLD if earned else Art.SAGE
	bar.compact = true
	bar.show_value = false
	inner.add_child(bar)
	inner.add_child(UI.label("%d / %d" % [progress, target], 13, Art.INK_SOFT,
		HORIZONTAL_ALIGNMENT_RIGHT))
	return card
