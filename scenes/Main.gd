extends Control
## Root node: theme, background, screen routing, and the persistent chrome
## (top wallet bar, bottom navigation, toasts and celebration popups).

const SCREENS := {
	"onboarding": "res://scenes/screens/OnboardingScreen.gd",
	"home": "res://scenes/screens/HomeScreen.gd",
	"journey": "res://scenes/screens/JourneyScreen.gd",
	"rescue": "res://scenes/screens/RescueScreen.gd",
	"sanctuary": "res://scenes/screens/SanctuaryScreen.gd",
	"library": "res://scenes/screens/LibraryScreen.gd",
	"shop": "res://scenes/screens/ShopScreen.gd",
	"badges": "res://scenes/screens/BadgeScreen.gd",
	"profile": "res://scenes/screens/ProfileScreen.gd",
}

const TABS := [
	{"id": "home", "label": "Home"},
	{"id": "journey", "label": "Journey"},
	{"id": "sanctuary", "label": "Sanctuary"},
	{"id": "library", "label": "Library"},
	{"id": "shop", "label": "Shop"},
]

var current_screen_name: String = ""

var _background: BackgroundView
var _host: Control
var _top_bar: PanelContainer
var _nav_bar: PanelContainer
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

	_build_chrome()
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
	_top_bar.visible = screen.show_chrome
	_nav_bar.visible = screen.show_chrome
	_refresh_chrome()


## --- chrome ------------------------------------------------------------

func _build_chrome() -> void:
	_top_bar = UI.card(Color(1, 1, 1, 0.86), 0)
	_top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_top_bar.custom_minimum_size.y = 62
	add_child(_top_bar)

	_nav_bar = UI.card(Color(1, 1, 1, 0.92), 0)
	_nav_bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_nav_bar.custom_minimum_size.y = 68
	_nav_bar.offset_top = -68
	add_child(_nav_bar)


func _refresh_chrome() -> void:
	if not is_instance_valid(_top_bar):
		return
	for child in _top_bar.get_children():
		child.queue_free()
	for child in _nav_bar.get_children():
		child.queue_free()
	if not GameState.started():
		return

	var row := UI.hbox(10)
	var pet_button := UI.button("  %s · %s  " % [GameState.pet_name(), GameState.stage_name()],
		func() -> void: goto("profile"), Art.CREAM)
	pet_button.custom_minimum_size = Vector2(0, 40)
	row.add_child(pet_button)
	row.add_child(UI.spacer())
	row.add_child(UI.pill("Coins  %d" % GameState.coins(), Art.GOLD.lerp(Art.WHITE, 0.45), 15))
	row.add_child(UI.pill("Gems  %d" % GameState.gems(), Art.SKY.lerp(Art.WHITE, 0.35), 15))

	var badge_button := UI.button("Badges %d" % GameState.badges_earned(),
		func() -> void: goto("badges"), Art.CREAM)
	badge_button.custom_minimum_size = Vector2(0, 40)
	row.add_child(badge_button)

	var ad_button := UI.button(_ad_label(), _on_ad_pressed, Art.SAGE.lerp(Art.WHITE, 0.25))
	ad_button.custom_minimum_size = Vector2(0, 40)
	ad_button.disabled = not GameState.ad_available()
	row.add_child(ad_button)
	_top_bar.add_child(row)

	var tabs := UI.hbox(8)
	for tab: Dictionary in TABS:
		var id := String(tab["id"])
		var active := id == current_screen_name
		var tab_button := UI.button(String(tab["label"]),
			func() -> void: goto(id),
			Art.PINK if active else Art.WHITE)
		tab_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab_button.custom_minimum_size = Vector2(0, 46)
		tabs.add_child(tab_button)
	_nav_bar.add_child(tabs)


func _ad_label() -> String:
	if GameState.ads_left_today() <= 0:
		return "Back tomorrow"
	if not GameState.ad_available():
		return "Free coins in %ds" % int(ceilf(GameState.ad_wait_seconds()))
	return "Free coins"


func _on_ad_pressed() -> void:
	show_rewarded_video(func() -> void: GameState.grant_ad_reward())


## --- rewarded video ----------------------------------------------------

## Stand-in for a real rewarded ad. Replace the body of this function with an
## SDK call and invoke `on_reward` from the SDK's reward callback.
## See docs/MONETISATION.md.
func show_rewarded_video(on_reward: Callable) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.12, 0.10, 0.09, 0.86)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(overlay)

	var column := UI.vbox(14)
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	overlay.add_child(column)

	var heading := UI.label("Sponsored break", 26, Art.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	column.add_child(heading)
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
	toast_card.offset_top = -160
	toast_card.offset_bottom = -104
	toast_card.custom_minimum_size = Vector2(360, 0)
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
	column.add_child(UI.pill(_celebration_tag(String(entry["icon"])), Art.PINK.lerp(Art.WHITE, 0.4)))
	column.add_child(UI.label(String(entry["title"]), 28, Art.INK, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UI.label(String(entry["body"]), 17, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER))
	column.add_child(UI.spacer(6))

	var close := UI.button("Lovely", Callable(), Art.PINK)
	close.pressed.connect(func() -> void:
		overlay.queue_free()
		_celebration_queue.pop_front()
		_show_next_celebration()
	)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.custom_minimum_size = Vector2(200, 48)
	column.add_child(close)

	card.scale = Vector2(0.9, 0.9)
	card.pivot_offset = card.custom_minimum_size * 0.5
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _celebration_tag(icon: String) -> String:
	match icon:
		"stage": return "Growth"
		"chapter": return "Chapter complete"
		"rescue": return "Rescue"
		"tame": return "Trust"
		"home": return "Forever home"
		"badge": return "Badge"
		"daily": return "Daily visit"
	return "Little Paws"
