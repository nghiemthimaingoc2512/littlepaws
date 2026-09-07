extends Screen
## The chapter map. Care chapters first, then the rescue regions.

func _init() -> void:
	scene_key = "mall"


func build(host: Control) -> void:
	if not GameState.started():
		return
	var column := page(host)
	column.add_child(UI.spacer(50))
	column.add_child(UI.label("Your journey", 30, Art.INK))

	var scroll := UI.scroll()
	column.add_child(scroll)
	var list := UI.vbox(12)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for index in Data.chapter_count():
		list.add_child(_chapter_card(index))
	list.add_child(UI.spacer(72))


func _chapter_card(index: int) -> Control:
	var chapter := Data.chapter(index)
	var chapter_id := String(chapter.get("id", ""))
	var cleared := GameState.chapter_cleared(chapter_id)
	var active := index == GameState.chapter_index()
	var locked := index > GameState.chapter_index()

	var fill := Art.WHITE
	if cleared:
		fill = Art.SAGE.lerp(Art.WHITE, 0.62)
	elif locked:
		fill = Color(0.96, 0.94, 0.91)

	var card := UI.card(fill, 24)
	var inner := UI.vbox(8)
	card.add_child(inner)

	var header := UI.hbox(10)
	inner.add_child(header)
	header.add_child(UI.label("%d. %s" % [index + 1, String(chapter.get("title", ""))], 22, Art.INK))
	header.add_child(UI.spacer())
	var tag := "Complete" if cleared else ("Locked" if locked else "In progress")
	var tag_color := Art.SAGE if cleared else (Art.CREAM_DEEP if locked else Art.PINK)
	header.add_child(UI.pill(tag, tag_color.lerp(Art.WHITE, 0.35)))

	if locked:
		inner.add_child(UI.paragraph("Finish chapter %d to open this." % (GameState.chapter_index() + 1),
			15, Art.INK_SOFT))
		return card

	inner.add_child(UI.paragraph(String(chapter.get("intro", "")), 15, Art.INK_SOFT))

	for goal: Dictionary in chapter.get("goals", []):
		inner.add_child(_goal_row(goal, active))

	if not cleared and active:
		var reward: Dictionary = chapter.get("reward", {})
		inner.add_child(UI.label("Chapter reward: %d coins, %d gems" % [
			int(reward.get("coins", 0)), int(reward.get("gems", 0))], 14, Art.INK_SOFT))
	return card


func _goal_row(goal: Dictionary, active: bool) -> Control:
	var done := GameState.goal_done(goal)
	var row := UI.hbox(10)

	var mark := UI.pill("done" if done else "todo",
		(Art.SAGE if done else Art.CREAM_DEEP).lerp(Art.WHITE, 0.3))
	row.add_child(mark)

	var text := String(goal.get("text", ""))
	var target := GameState.goal_target(goal)
	if target > 1:
		text += "   %d / %d" % [mini(GameState.goal_progress(goal), target), target]
	var text_label := UI.paragraph(text, 16, Art.INK if not done else Art.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, 200.0)
	row.add_child(text_label)

	if String(goal.get("type", "")) == "rescue" and not done and active:
		var species_id := String(goal.get("key", ""))
		var start := UI.button("Go find them", Callable(), Art.PINK)
		start.custom_minimum_size = Vector2(170, 42)
		start.pressed.connect(func() -> void: goto("rescue", {"species": species_id}))
		row.add_child(start)
	elif String(goal.get("type", "")) == "homed" and not done and active:
		var open := UI.button("Sanctuary", Callable(), Art.CREAM)
		open.custom_minimum_size = Vector2(170, 42)
		open.pressed.connect(func() -> void: goto("sanctuary"))
		row.add_child(open)
	return row
