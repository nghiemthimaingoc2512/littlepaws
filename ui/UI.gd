extends RefCounted
class_name UI
## Small factory helpers so screens stay readable. Every screen builds its
## own node tree in code; these are the shared building blocks.


## A single-line label. Wrapping is opt-in through `paragraph()`, because a
## wrapping label inside a shrink-to-fit container collapses to one character
## per line.
static func label(text: String, font_size: int = 18, color: Color = Color("5b4636"),
		align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = align
	node.autowrap_mode = TextServer.AUTOWRAP_OFF
	node.size_flags_horizontal = Control.SIZE_FILL
	return node


## Body copy that wraps. The minimum width stops it collapsing into a column.
static func paragraph(text: String, font_size: int = 15, color: Color = Color("8b7462"),
		align: int = HORIZONTAL_ALIGNMENT_LEFT, min_width: float = 260.0) -> Label:
	var node := label(text, font_size, color, align)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.custom_minimum_size.x = min_width
	return node


static func title(text: String, font_size: int = 30) -> Label:
	return label(text, font_size, Art.INK)


static func muted(text: String, font_size: int = 15) -> Label:
	return label(text, font_size, Art.INK_SOFT)


static func button(text: String, on_press: Callable, tint: Color = Color("fffcf7"),
		min_width: float = 0.0) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(min_width, 46.0)
	if tint != Art.WHITE:
		node.add_theme_stylebox_override("normal", Art.panel_box(tint, 20))
		node.add_theme_stylebox_override("hover", Art.panel_box(tint.lightened(0.08), 20))
		node.add_theme_stylebox_override("pressed", Art.panel_box(tint.darkened(0.10), 20))
	if on_press.is_valid():
		node.pressed.connect(on_press)
	return node


static func card(fill: Color = Color("fffcf7"), radius: int = 24) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", Art.panel_box(fill, radius))
	return node


static func vbox(separation: int = 10) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func hbox(separation: int = 10) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", separation)
	return node


static func grid(columns: int, separation: int = 12) -> GridContainer:
	var node := GridContainer.new()
	node.columns = maxi(1, columns)
	node.add_theme_constant_override("h_separation", separation)
	node.add_theme_constant_override("v_separation", separation)
	return node


static func spacer(height: float = 0.0) -> Control:
	var node := Control.new()
	node.custom_minimum_size.y = height
	if height <= 0.0:
		node.size_flags_vertical = Control.SIZE_EXPAND_FILL
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func scroll() -> ScrollContainer:
	var node := ScrollContainer.new()
	node.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node


static func stat_bar(name: String, value: float, color: Color, compact: bool = false) -> StatBar:
	var bar := StatBar.new()
	bar.label_text = name
	bar.value = value
	bar.fill_color = color
	bar.compact = compact
	return bar


static func pill(text: String, color: Color, font_size: int = 13) -> PanelContainer:
	var box := card(color, 999)
	var style := box.get_theme_stylebox("panel") as StyleBoxFlat
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	var text_node := label(text, font_size, Art.INK, HORIZONTAL_ALIGNMENT_CENTER)
	text_node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	text_node.custom_minimum_size.x = 0.0
	box.add_child(text_node)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return box


static func creature(species_id: String, box_size: float, pose: String = "idle") -> CreatureView:
	var view := CreatureView.new()
	view.species_id = species_id
	view.pose = pose
	view.custom_minimum_size = Vector2(box_size, box_size)
	return view


## Wraps content in a padded card with a heading.
static func section(heading: String, content: Control, fill: Color = Color("fffcf7")) -> PanelContainer:
	var box := card(fill)
	var column := vbox(8)
	column.add_child(label(heading, 20, Art.INK))
	column.add_child(content)
	box.add_child(column)
	return box
