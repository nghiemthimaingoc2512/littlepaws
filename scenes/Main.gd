extends Control
## Root node: theme, background, screen routing, and the floating chrome —
## player card, currency bars, corner buttons, navigation and the play button.

const SCREENS := {
	"onboarding": "res://scenes/screens/OnboardingScreen.gd",
	"home": "res://scenes/screens/HomeScreen.gd",
	"journey": "res://scenes/screens/JourneyScreen.gd",
	"rescue": "res://scenes/screens/RescueScreen.gd",
	"sanctuary": "res://scenes/screens/SanctuaryScreen.gd",
	"library": "res://scenes/screens/LibraryScreen.gd",
	"shop": "res://scenes/screens/ShopScreen.gd",
	"bag": "res://scenes/screens/BagScreen.gd",
	"missions": "res://scenes/screens/MissionsScreen.gd",
	"daily": "res://scenes/screens/DailyScreen.gd",
	"events": "res://scenes/screens/EventsScreen.gd",
	"mail": "res://scenes/screens/MailScreen.gd",
	"profile": "res://scenes/screens/ProfileScreen.gd",
}

const TABS := [
	{"id": "home", "label": "Home", "icon": "home"},
	{"id": "library", "label": "Pets", "icon": "cat"},
	{"id": "sanctuary", "label": "Friends", "icon": "friends"},
	{"id": "journey", "label": "Map", "icon": "map"},
	{"id": "bag", "label": "Bag", "icon": "bag"},
	{"id": "shop", "label": "Shop", "icon": "shop"},
]

const PHOTO_DIR := "user://photos"

var current_screen_name: String = ""

var _background: BackgroundView
var _host: Control
var _chrome: Control
var _toast_label: Label
var _modal_layer: Control
var _toast_tween: Tween
var _celebration_queue: Array = []


func _ready() -> void:
	theme = Art.build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_background = BackgroundView.new()
	add_child(_background)

	_host = Control.new()
	_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_host.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_host)

	_chrome = Control.new()
	_chrome.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_chrome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_chrome)

	_build_overlays()

	GameState.changed.connect(_refresh_chrome)
	GameState.toast.connect(show_toast)
	GameState.celebrate.connect(_queue_celebration)

	goto("home" if GameState.started() else "onboarding")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.save_game()


## --- routing -----------------------------------------------------------

func goto(screen_name: String, screen_args: Dictionary = {}) -> void:
	if not SCREENS.has(screen_name):
		push_error("Little Paws: unknown screen '%s'" % screen_name)
		return
	for child in _host.get_children():
		child.queue_free()

	var script: GDScript = load(SCREENS[screen_name])
	var screen: Screen = script.new()
	screen.args = screen_args
	screen.main = self
	current_screen_name = screen_name
	_host.add_child(screen)

	_background.scene_key = screen.scene_key
	_chrome.visible = screen.show_chrome
	_refresh_chrome()


## --- chrome ------------------------------------------------------------

func _refresh_chrome() -> void:
	if not is_instance_valid(_chrome):
		return
	for child in _chrome.get_children():
		child.queue_free()
	if not GameState.started():
		return

	_place(_player_card(), Control.PRESET_TOP_LEFT, Vector2(16, 14), Vector2(300, 58))
	_place(_currency_row(), Control.PRESET_CENTER_TOP, Vector2(0, 14), Vector2(560, 44))
	_place(_corner_buttons(), Control.PRESET_TOP_RIGHT, Vector2(-16, 14), Vector2(178, 50))
	_place(_bottom_row(), Control.PRESET_BOTTOM_WIDE, Vector2(16, -16), Vector2(0, 76))


## Anchors a floating chrome element. `pad` is the offset from that corner.
func _place(node: Control, preset: int, pad: Vector2, box: Vector2) -> void:
	node.set_anchors_and_offsets_preset(preset)
	match preset:
		Control.PRESET_TOP_LEFT:
			node.offset_left = pad.x
			node.offset_top = pad.y
			node.offset_right = pad.x + box.x
			node.offset_bottom = pad.y + box.y
		Control.PRESET_CENTER_TOP:
			node.grow_horizontal = Control.GROW_DIRECTION_BOTH
			node.offset_left = -box.x * 0.5
			node.offset_right = box.x * 0.5
			node.offset_top = pad.y
			node.offset_bottom = pad.y + box.y
		Control.PRESET_TOP_RIGHT:
			node.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			node.offset_right = pad.x
			node.offset_left = pad.x - box.x
			node.offset_top = pad.y
			node.offset_bottom = pad.y + box.y
		Control.PRESET_BOTTOM_WIDE:
			node.offset_left = pad.x
			node.offset_right = -pad.x
			node.offset_bottom = pad.y
			node.offset_top = pad.y - box.y
	_chrome.add_child(node)


func _player_card() -> Control:
	var card := UI.card(Art.WHITE, 999)
	var style := card.get_theme_stylebox("panel") as StyleBoxFlat
	style.content_margin_left = 6
	style.content_margin_top = 5
	style.content_margin_bottom = 5

	var row := UI.hbox(10)
	card.add_child(row)

	var frame := UI.card(Art.CREAM_DEEP, 999)
	frame.custom_minimum_size = Vector2(46, 46)
	frame.clip_contents = true
	var avatar := CreatureView.new()
	avatar.is_owner = true
	avatar.animate = false
	avatar.head_only = true
	frame.add_child(avatar)
	row.add_child(frame)

	var info := UI.vbox(1)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	info.add_child(UI.label(GameState.owner_name(), 18, Art.INK))

	var level := GameState.player_level_info()
	var level_row := UI.hbox(6)
	info.add_child(level_row)
	level_row.add_child(UI.label("Lv. %d" % int(level["level"]), 14, Art.INK_SOFT))

	var bar := StatBar.new()
	bar.label_text = ""
	bar.compact = true
	bar.show_value = false
	bar.max_value = float(level["need"])
	bar.value = float(level["into"])
	bar.fill_color = Art.GOLD
	bar.custom_minimum_size = Vector2(96, 14)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	level_row.add_child(bar)

	row.add_child(IconView.make("paw", 22, Art.PINK))
	return UI.clickable(card, func() -> void: goto("profile"))


func _currency_row() -> Control:
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(_currency_pill("coin", _short(GameState.coins()), Art.GOLD,
		func() -> void: show_rewarded_video(func() -> void: GameState.grant_ad_reward())))
	row.add_child(_currency_pill("gem", str(GameState.gems()), Art.SKY,
		func() -> void: goto("shop")))
	row.add_child(_currency_pill("heart", str(GameState.hearts()), Art.RED,
		func() -> void: goto("daily")))
	return row


func _currency_pill(icon_kind: String, text: String, accent: Color, on_plus: Callable) -> Control:
	var pill := UI.card(Art.BROWN, 999)
	var style := pill.get_theme_stylebox("panel") as StyleBoxFlat
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 3
	style.content_margin_bottom = 3

	var row := UI.hbox(8)
	pill.add_child(row)
	row.add_child(IconView.make(icon_kind, 30, Art.WHITE, accent))

	var amount := UI.label(text, 18, Art.WHITE)
	amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	amount.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(amount)

	var plus := UI.card(Art.GREEN, 999)
	plus.custom_minimum_size = Vector2(30, 30)
	var plus_style := plus.get_theme_stylebox("panel") as StyleBoxFlat
	plus_style.content_margin_left = 5
	plus_style.content_margin_right = 5
	plus_style.content_margin_top = 5
	plus_style.content_margin_bottom = 5
	plus_style.set_border_width_all(2)
	plus_style.border_color = Art.GREEN.darkened(0.18)
	plus.add_child(IconView.make("plus", 16, Art.WHITE))
	row.add_child(UI.clickable(plus, on_plus, Vector2(30, 30)))
	return pill


func _corner_buttons() -> Control:
	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(_round_button("mail", func() -> void: goto("mail"), GameState.unread_mail()))
	row.add_child(_round_button("camera", _take_photo, 0))
	row.add_child(_round_button("gear", func() -> void: goto("profile"), 0))
	return row


func _round_button(icon_kind: String, on_press: Callable, badge_count: int) -> Control:
	var circle := UI.card(Art.WHITE, 999)
	circle.custom_minimum_size = Vector2(50, 50)
	var style := circle.get_theme_stylebox("panel") as StyleBoxFlat
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.set_border_width_all(2)
	style.border_color = Art.CREAM_DEEP
	circle.add_child(IconView.make(icon_kind, 26, Art.INK))

	var wrap := UI.clickable(circle, on_press, Vector2(50, 50))
	if badge_count > 0:
		UI.dot(wrap, badge_count)
	return wrap


func _bottom_row() -> Control:
	var row := UI.hbox(14)
	row.add_child(_logo())
	row.add_child(_nav_bar())
	row.add_child(_play_button())
	return row


func _logo() -> Control:
	var column := UI.vbox(0)
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.custom_minimum_size.x = 168
	column.add_child(UI.label("Little Paws", 24, Art.INK))
	column.add_child(UI.label("Small Paws · Big Happiness", 11, Art.INK_SOFT))
	return column


func _nav_bar() -> Control:
	var bar := UI.card(Art.WHITE, 26)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := bar.get_theme_stylebox("panel") as StyleBoxFlat
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5

	var row := UI.hbox(4)
	bar.add_child(row)
	for tab: Dictionary in TABS:
		row.add_child(_nav_item(tab))
	return bar


func _nav_item(tab: Dictionary) -> Control:
	var id := String(tab["id"])
	var active := id == current_screen_name

	var fill := UI.card(Art.GOLD_SOFT if active else Color(1, 1, 1, 0), 20)
	var column := UI.vbox(1)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	fill.add_child(column)
	column.add_child(IconView.make(String(tab["icon"]), 28, Art.INK,
		Art.GOLD if active else Art.SAGE))
	column.add_child(UI.label(String(tab["label"]), 13, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))

	var item := UI.clickable(fill, func() -> void: goto(id), Vector2(0, 58))
	item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if id == "sanctuary" and GameState.friends_have_news():
		UI.dot(item)
	return item


func _play_button() -> Control:
	var button := UI.card(Art.GOLD, 26)
	button.custom_minimum_size = Vector2(276, 0)
	var style := button.get_theme_stylebox("panel") as StyleBoxFlat
	style.set_border_width_all(3)
	style.border_color = Art.GOLD.darkened(0.16)

	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(row)
	row.add_child(IconView.make("paw", 30, Art.INK))
	row.add_child(UI.label("Let's Play!", 24, Art.INK))
	row.add_child(IconView.make("heart", 22, Art.RED, Art.RED))
	return UI.clickable(button, func() -> void: goto("home", {"open_care": true}),
		Vector2(276, 0))


func _short(amount: int) -> String:
	if amount < 1000:
		return str(amount)
	if amount < 1000000:
		return "%d,%03d" % [amount / 1000, amount % 1000]
	return "%.1fM" % (float(amount) / 1000000.0)


## --- camera ------------------------------------------------------------

## Saves what is on screen right now. Chrome is hidden for one frame so the
## photo is of the room, not of the interface.
func _take_photo() -> void:
	DirAccess.make_dir_recursive_absolute(PHOTO_DIR)
	_chrome.visible = false
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	_chrome.visible = true
	var path := "%s/littlepaws_%d.png" % [PHOTO_DIR, int(Time.get_unix_time_from_system())]
	if image.save_png(path) == OK:
		show_toast("Photo saved to %s" % ProjectSettings.globalize_path(PHOTO_DIR))
	else:
		show_toast("Could not save the photo.")


## --- rewarded video ----------------------------------------------------

## Stand-in for a real rewarded ad. Replace the body of this function with an
## SDK call and invoke `on_reward` from the SDK's reward callback.
## See docs/MONETISATION.md.
func show_rewarded_video(on_reward: Callable) -> void:
	if not GameState.ad_available():
		show_toast("More free coins in a little while.")
		return

	var overlay := ColorRect.new()
	overlay.color = Color(0.12, 0.10, 0.09, 0.86)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(overlay)

	var column := UI.vbox(14)
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay.add_child(column)

	column.add_child(UI.label("Sponsored break", 26, Art.WHITE, HORIZONTAL_ALIGNMENT_CENTER))
	var counter := UI.label("", 18, Art.CREAM, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(counter)

	var seconds := 5
	counter.text = "Your reward arrives in %d…" % seconds
	while seconds > 0:
		await get_tree().create_timer(1.0).timeout
		seconds -= 1
		if not is_instance_valid(counter):
			return
		counter.text = "Your reward arrives in %d…" % seconds
	overlay.queue_free()
	if on_reward.is_valid():
		on_reward.call()


## --- toasts & celebrations --------------------------------------------

func _build_overlays() -> void:
	_toast_label = UI.label("", 17, Art.INK, HORIZONTAL_ALIGNMENT_CENTER)
	var toast_card := UI.card(Art.WHITE, 999)
	toast_card.add_child(_toast_label)
	toast_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	toast_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_card.offset_top = -168
	toast_card.offset_bottom = -112
	toast_card.custom_minimum_size = Vector2(380, 0)
	toast_card.modulate.a = 0.0
	toast_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_card)
	_toast_label.set_meta("card", toast_card)

	_modal_layer = Control.new()
	_modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_modal_layer)


func show_toast(text: String) -> void:
	if not is_instance_valid(_toast_label):
		return
	_toast_label.text = text
	var card: Control = _toast_label.get_meta("card")
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	card.modulate.a = 0.0
	_toast_tween = create_tween()
	_toast_tween.tween_property(card, "modulate:a", 1.0, 0.18)
	_toast_tween.tween_interval(2.0)
	_toast_tween.tween_property(card, "modulate:a", 0.0, 0.5)


func _queue_celebration(title: String, body: String, icon: String) -> void:
	_celebration_queue.append({"title": title, "body": body, "icon": icon})
	if _celebration_queue.size() == 1:
		_show_next_celebration()


func _show_next_celebration() -> void:
	if _celebration_queue.is_empty():
		return
	var entry: Dictionary = _celebration_queue[0]

	var overlay := ColorRect.new()
	overlay.color = Color(0.18, 0.14, 0.12, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(overlay)

	var card := UI.card(Art.WHITE, 28)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card.grow_vertical = Control.GROW_DIRECTION_BOTH
	card.custom_minimum_size = Vector2(520, 0)
	overlay.add_child(card)

	var column := UI.vbox(12)
	card.add_child(column)
	column.add_child(IconView.make(_celebration_icon(String(entry["icon"])), 56, Art.INK, Art.GOLD))
	column.add_child(UI.label(String(entry["title"]), 28, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UI.paragraph(String(entry["body"]), 17, Art.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER, 440.0))
	column.add_child(UI.spacer(6))

	var close := UI.button("Lovely", Callable(), Art.GOLD)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.custom_minimum_size = Vector2(200, 48)
	close.pressed.connect(func() -> void:
		overlay.queue_free()
		_celebration_queue.pop_front()
		_show_next_celebration()
	)
	column.add_child(close)

	card.scale = Vector2(0.9, 0.9)
	card.pivot_offset = card.custom_minimum_size * 0.5
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _celebration_icon(icon: String) -> String:
	match icon:
		"stage": return "sparkle"
		"chapter": return "map"
		"rescue": return "paw"
		"tame": return "heart"
		"home": return "home"
		"badge": return "trophy"
		"daily": return "calendar"
	return "paw"
