extends Screen
## The daily visit: your streak, today's five small jobs, and their rewards.

func _init() -> void:
	scene_key = "home"


func build(host: Control) -> void:
	if not GameState.started():
		return
	var column := page(host)
	column.add_child(UI.spacer(74))

	var header := UI.hbox(10)
	header.add_child(UI.icon_row("calendar", "Daily", 34, 30, Art.INK, Art.INK, Art.GOLD))
	header.add_child(UI.spacer())
	header.add_child(UI.pill("Day %d in a row" % GameState.streak(), Art.PINK.lerp(Art.WHITE, 0.4), 15))
	column.add_child(header)

	var scroll := UI.scroll()
	column.add_child(scroll)
	var page_column := UI.vbox(0)
	page_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(page_column)

	var body := UI.hbox(16)
	page_column.add_child(body)
	body.add_child(_tasks_card())
	body.add_child(_side_card())
	page_column.add_child(UI.spacer(94))


func _tasks_card() -> Control:
	var card := UI.card(Art.WHITE, 24)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.6

	var column := UI.vbox(8)
	card.add_child(column)
	column.add_child(UI.label("To Do Today", 22, Art.INK))
	column.add_child(UI.paragraph(
		"Five small things. None of them expire in a way that costs you anything — the list simply starts fresh tomorrow.",
		14, Art.INK_SOFT))

	for task: Dictionary in GameState.DAILY_TASKS:
		column.add_child(_task_row(task))

	var done := GameState.tasks_done_today()
	column.add_child(UI.spacer(4))
	column.add_child(UI.label(
		"%d of %d done — finish them all for +%d heart and +%d gems."
		% [done, GameState.DAILY_TASKS.size(), GameState.DAILY_CLEAR_HEARTS, GameState.DAILY_CLEAR_GEMS],
		14, Art.INK_SOFT))
	return card


func _task_row(task: Dictionary) -> Control:
	var done := GameState.task_done(task)
	var claimed := GameState.task_claimed(task)
	var target := GameState.task_target(task)

	var row_card := UI.card(Art.SAGE.lerp(Art.WHITE, 0.72) if done else Art.CREAM, 18)
	var row := UI.hbox(10)
	row_card.add_child(row)

	row.add_child(IconView.make("check" if done else "paw", 22,
		Art.SAGE.darkened(0.2) if done else Art.INK_SOFT))

	var text := UI.vbox(1)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(UI.label(String(task.get("label", "")), 17, Art.INK))
	if target > 1:
		text.add_child(UI.label("%d / %d" % [GameState.task_progress(task), target], 13, Art.INK_SOFT))
	row.add_child(text)

	row.add_child(UI.pill("+%d coins" % int(task.get("coins", 0)), Art.GOLD.lerp(Art.WHITE, 0.5), 13))

	if claimed:
		row.add_child(UI.pill("collected", Art.SAGE.lerp(Art.WHITE, 0.4), 13))
	else:
		var claim := UI.button("Collect" if done else "Not yet", Callable(),
			Art.GOLD if done else Art.CREAM_DEEP)
		claim.custom_minimum_size = Vector2(120, 40)
		claim.disabled = not done
		var task_id := String(task.get("id", ""))
		claim.pressed.connect(func() -> void: GameState.claim_task(task_id))
		row.add_child(claim)
	return row_card


func _side_card() -> Control:
	var column := UI.vbox(12)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var streak_card := UI.card(Art.WHITE, 24)
	var streak := UI.vbox(6)
	streak_card.add_child(streak)
	streak.add_child(UI.label("Coming back", 20, Art.INK))
	streak.add_child(UI.paragraph(
		"Visiting on consecutive days pays a little more each time, and every seventh day adds gems. Missing a day only resets the counter — nothing is taken away.",
		14, Art.INK_SOFT))
	streak.add_child(UI.pill("Current streak: %d %s" % [GameState.streak(),
		"day" if GameState.streak() == 1 else "days"],
		Art.PINK.lerp(Art.WHITE, 0.45), 14))
	column.add_child(streak_card)

	var hearts_card := UI.card(Art.WHITE, 24)
	var hearts := UI.vbox(6)
	hearts_card.add_child(hearts)
	hearts.add_child(UI.icon_row("heart", "Hearts", 26, 20, Art.INK, Art.RED, Art.RED))
	hearts.add_child(UI.paragraph(
		"Hearts come from finishing the day's list and from finding an animal its forever home. They buy keepsakes in the shop and never gate a chapter.",
		14, Art.INK_SOFT))
	hearts.add_child(UI.pill("You have %d" % GameState.hearts(), Art.RED.lerp(Art.WHITE, 0.6), 14))
	column.add_child(hearts_card)

	var ad := UI.button("Watch a short video  +%d coins" % GameState.AD_REWARD_COINS,
		Callable(), Art.SAGE.lerp(Art.WHITE, 0.35))
	ad.custom_minimum_size.y = 48
	ad.disabled = not GameState.ad_available()
	ad.pressed.connect(func() -> void:
		if main != null:
			main.show_rewarded_video(func() -> void: GameState.grant_ad_reward())
	)
	column.add_child(ad)
	column.add_child(UI.spacer())
	return column
