extends Node
## Static game content, loaded from res://data/*.json so designers can edit
## balance and copy without touching any code.

var species: Dictionary = {}
var chapters: Array = []
var items: Dictionary = {}
var badges: Array = []
var npcs: Array = []


func _ready() -> void:
	species = _read("res://data/species.json", {})
	chapters = _read("res://data/chapters.json", [])
	items = _read("res://data/items.json", {})
	badges = _read("res://data/badges.json", [])
	npcs = _read("res://data/npcs.json", [])


func _read(path: String, fallback: Variant) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("Little Paws: missing data file %s" % path)
		return fallback
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("Little Paws: could not parse %s" % path)
		return fallback
	return parsed


## --- species -----------------------------------------------------------

func get_species(id: String) -> Dictionary:
	return species.get(id, {})


func species_name(id: String) -> String:
	return String(get_species(id).get("name", id))


func starter_ids() -> Array:
	var out: Array = []
	for id: String in species.keys():
		if bool(species[id].get("starter", false)):
			out.append(id)
	return out


func rescuable_ids() -> Array:
	var out: Array = []
	for id: String in species.keys():
		if not bool(species[id].get("starter", false)):
			out.append(id)
	return out


func species_in_region(region: String) -> Array:
	var out: Array = []
	for id: String in species.keys():
		if String(species[id].get("region", "")) == region:
			out.append(id)
	return out


## --- chapters ----------------------------------------------------------

func chapter(index: int) -> Dictionary:
	if index < 0 or index >= chapters.size():
		return {}
	return chapters[index]


func chapter_count() -> int:
	return chapters.size()


## --- items -------------------------------------------------------------

func item(category: String, id: String) -> Dictionary:
	var group: Dictionary = items.get(category, {})
	return group.get(id, {})


func item_name(category: String, id: String) -> String:
	return String(item(category, id).get("name", id))


func category_of(item_id: String) -> String:
	for category: String in items.keys():
		if (items[category] as Dictionary).has(item_id):
			return category
	return ""


func default_owned() -> Array:
	var out: Array = []
	for category: String in items.keys():
		var group: Dictionary = items[category]
		for id: String in group.keys():
			if bool(group[id].get("owned", false)):
				out.append(id)
	return out


## --- badges & npcs -----------------------------------------------------

func badge(id: String) -> Dictionary:
	for b: Dictionary in badges:
		if String(b.get("id", "")) == id:
			return b
	return {}


func npc(id: String) -> Dictionary:
	for n: Dictionary in npcs:
		if String(n.get("id", "")) == id:
			return n
	return {}
