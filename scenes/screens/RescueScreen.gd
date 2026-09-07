extends Screen
## A rescue mission. The animal shows what it needs; you answer.
##
## There is no timer and no failure. A wrong guess costs nothing but a gentle
## nudge, and the round simply waits for you.

const ROUNDS := 5

const NEEDS := [
	{"id": "feed", "prompt": "%s's stomach growls softly.", "hint": "They are hungry."},
	{"id": "play", "prompt": "%s watches you, then looks away.", "hint": "They are lonely."},
	{"id": "bathe", "prompt": "%s is dusty from the road.", "hint": "They need cleaning up."},
	{"id": "brush", "prompt": "%s's fur is tangled and matted.", "hint": "A brush would help."},
	{"id": "sleep", "prompt": "%s's eyes keep drifting closed.", "hint": "They are exhausted."},
	{"id": "heal", "prompt": "%s is favouring one paw.", "hint": "They are hurt."},
]

const CHOICES := [
	{"id": "feed", "label": "Offer food"},
	{"id": "play", "label": "Play gently"},
	{"id": "bathe", "label": "Clean them up"},
	{"id": "brush", "label": "Brush them"},
	{"id": "sleep", "label": "Make a warm bed"},
	{"id": "heal", "label": "Treat the wound"},
]

var species_id: String = ""
var _round: int = 0
var _need: Dictionary = {}
var _message: String = ""
var _show_hint: bool = false
var _finished: bool = false
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	scene_key = "meadow"


func _ready() -> void:
	species_id = String(args.get("species", ""))
	if species_id.is_empty():
		species_id = Data.rescuable_ids()[0]
	scene_key = String(Data.get_species(species_id).get("region", "meadow"))
	_rng.randomize()
	_next_round()
	super()


func refresh() -> void:
	pass  # The mission owns its own view; save changes must not interrupt it.


func _next_round() -> void:
	_need = NEEDS[_rng.randi_range(0, NEEDS.size() - 1)]
	_show_hint = false


func build(host: Control) -> void:
	var column := page(host)
	column.add_child(UI.spacer(74))
	if _finished:
		_build_finish(column)
		return

	var info := Data.get_species(species_id)
	column.add_child(UI.label("Rescue: %s" % String(info.get("name", species_id)), 28, Art.INK))

	var body := UI.hbox(20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)

	var left := UI.vbox(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	var view := UI.creature(species_id, 260.0, "peek")
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left.add_child(view)

	var calm := StatBar.new()
	calm.label_text = "Calm"
	calm.max_value = float(ROUNDS)
	calm.value = float(_round)
	calm.fill_color = Art.SAGE
	calm.show_value = false
	left.add_child(calm)
	left.add_child(UI.label("Step %d of %d" % [mini(_round + 1, ROUNDS), ROUNDS], 14, Art.INK_SOFT,
		HORIZONTAL_ALIGNMENT_CENTER))

	var right := UI.vbox(12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)

	var prompt := UI.card(Color(1, 1, 1, 0.92), 24)
	var prompt_column := UI.vbox(6)
	prompt.add_child(prompt_column)
	prompt_column.add_child(UI.paragraph(String(_need.get("prompt", "")) % String(info.get("name", species_id)),
		20, Art.INK, HORIZONTAL_ALIGNMENT_LEFT, 320.0))
	if _show_hint:
		prompt_column.add_child(UI.paragraph(String(_need.get("hint", "")), 15, Art.PINK_DEEP, HORIZONTAL_ALIGNMENT_LEFT, 320.0))
	if _message != "":
		prompt_column.add_child(UI.paragraph(_message, 15, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_LEFT, 320.0))
	right.add_child(prompt)

	var grid := UI.grid(2, 10)
	right.add_child(grid)
	for choice: Dictionary in CHOICES:
		var choice_id := String(choice["id"])
		var button := UI.button(String(choice["label"]), Callable(), Art.WHITE)
		button.custom_minimum_size = Vector2(0, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: _answer(choice_id))
		grid.add_child(button)

	var hint_button := UI.button("What do they need?", Callable(), Art.CREAM)
	hint_button.pressed.connect(func() -> void:
		_show_hint = true
		rebuild()
	)
	right.add_child(hint_button)

	var leave := UI.button("Come back later", Callable(), Art.CREAM)
	leave.pressed.connect(func() -> void: goto("journey"))
	right.add_child(leave)
	column.add_child(UI.spacer(94))


func _answer(choice_id: String) -> void:
	var info := Data.get_species(species_id)
	if choice_id != String(_need.get("id", "")):
		_message = "Not quite — %s stays still. Try another way." % String(info.get("name", species_id))
		_show_hint = true
		rebuild()
		return

	_round += 1
	if _round >= ROUNDS:
		_finished = true
		GameState.rescue(species_id)
		rebuild()
		return
	_message = "That was exactly right. %s edges a little closer." % String(info.get("name", species_id))
	_next_round()
	rebuild()


func _build_finish(column: VBoxContainer) -> void:
	var info := Data.get_species(species_id)
	var card := UI.card(Art.WHITE, 28)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.custom_minimum_size = Vector2(620, 0)
	column.add_child(card)

	var inner := UI.vbox(12)
	card.add_child(inner)
	var view := UI.creature(species_id, 220.0, "happy")
	view.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(view)
	inner.add_child(UI.label("%s is safe" % String(info.get("name", species_id)), 30, Art.INK,
		HORIZONTAL_ALIGNMENT_CENTER))
	inner.add_child(UI.paragraph(String(info.get("bio", "")), 16, Art.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER, 520.0))
	inner.add_child(UI.paragraph(String(info.get("hint", "")), 15, Art.PINK_DEEP, HORIZONTAL_ALIGNMENT_CENTER, 520.0))

	var row := UI.hbox(10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_child(row)

	var sanctuary := UI.button("Take them to the Sanctuary", Callable(), Art.PINK)
	sanctuary.custom_minimum_size = Vector2(280, 50)
	sanctuary.pressed.connect(func() -> void: goto("sanctuary", {"species": species_id}))
	row.add_child(sanctuary)

	var journey := UI.button("Back to the journey", Callable(), Art.CREAM)
	journey.custom_minimum_size = Vector2(220, 50)
	journey.pressed.connect(func() -> void: goto("journey"))
	row.add_child(journey)
	column.add_child(UI.spacer(94))
