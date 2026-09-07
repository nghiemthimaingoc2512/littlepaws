extends Screen
## Every badge, earned or still in progress.

func _init() -> void:
	scene_key = "home"


func build(host: Control) -> void:
	if not GameState.started():
		return
	var column := page(host)
	column.add_child(UI.spacer(50))

	var header := UI.hbox(10)
	header.add_child(UI.label("Badges", 30, Art.INK))
	header.add_child(UI.spacer())
	header.add_child(UI.pill("%d / %d earned" % [GameState.badges_earned(), Data.badges.size()],
		Art.GOLD.lerp(Art.WHITE, 0.5), 15))
	column.add_child(header)

	var scroll := UI.scroll()
	column.add_child(scroll)
	var grid := UI.grid(3, 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(grid)

	for badge: Dictionary in Data.badges:
		grid.add_child(_badge_card(badge))
	column.add_child(UI.spacer(62))


func _badge_card(badge: Dictionary) -> Control:
	var id := String(badge.get("id", ""))
	var earned := GameState.has_badge(id)
	var target := maxi(1, int(badge.get("target", 1)))
	var progress := mini(GameState.badge_progress(badge), target)

	var card := UI.card(Art.GOLD.lerp(Art.WHITE, 0.72) if earned else Art.WHITE, 22)
	var inner := UI.vbox(6)
	card.add_child(inner)

	var head := UI.hbox(8)
	inner.add_child(head)
	head.add_child(UI.label(String(badge.get("name", id)), 19, Art.INK))
	head.add_child(UI.spacer())
	head.add_child(UI.pill("+%d gems" % int(badge.get("gems", 0)), Art.SKY.lerp(Art.WHITE, 0.4), 12))

	inner.add_child(UI.paragraph(String(badge.get("text", "")), 14, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, 200.0))

	var bar := StatBar.new()
	bar.label_text = "Earned" if earned else "Progress"
	bar.max_value = float(target)
	bar.value = float(progress)
	bar.fill_color = Art.GOLD if earned else Art.SAGE
	bar.compact = true
	inner.add_child(bar)
	inner.add_child(UI.label("%d / %d" % [progress, target], 13, Art.INK_SOFT,
		HORIZONTAL_ALIGNMENT_RIGHT))
	return card
