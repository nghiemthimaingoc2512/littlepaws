extends Node
## The whole player save, plus every rule that changes it.
##
## Design rule for Little Paws: nothing here can produce a loss. Stats decay
## toward a comfort floor, never to zero; missions can be retried forever;
## progress is only ever added.

signal changed
## Emitted on the slow decay tick. Screens use it to refresh meters without
## rebuilding their whole layout.
signal ticked
signal toast(text: String)
signal celebrate(title: String, body: String, icon: String)
signal badge_unlocked(badge_id: String)
signal pose_hint(pose: String)

const SAVE_PATH := "user://littlepaws_save.json"
const SAVE_VERSION := 1

const STAGES: Array[String] = ["Baby", "Kid", "Teen", "Adult"]
const STAGE_XP: Array[int] = [0, 150, 500, 1200]
const STAT_KEYS: Array[String] = ["food", "clean", "energy", "mood", "health"]

## Points lost per real-world hour. Gentle on purpose.
const DECAY := {"food": 10.0, "clean": 6.0, "energy": 8.0, "mood": 5.0, "health": 1.5}
## Stats never fall below this, so a pet is never in danger.
const COMFORT_FLOOR := 20.0
## However long you are away, at most this much decay is applied.
const MAX_OFFLINE_HOURS := 12.0

const ACTIONS := {
	"feed": {
		"label": "Feed", "icon": "food", "pose": "eat", "cooldown": 8.0, "cost": 0,
		"xp": 8, "bond": 2, "needs_food": true,
		"stats": {"food": 30.0, "mood": 5.0},
		"line": "%s eats every last bite and looks up for more.",
	},
	"bathe": {
		"label": "Bath", "icon": "clean", "pose": "happy", "cooldown": 25.0, "cost": 15,
		"xp": 9, "bond": 2,
		"stats": {"clean": 44.0, "mood": 4.0, "energy": -6.0},
		"line": "%s is warm, fluffy and smells like soap.",
	},
	"play": {
		"label": "Play", "icon": "mood", "pose": "play", "cooldown": 10.0, "cost": 0,
		"xp": 11, "bond": 3,
		"stats": {"mood": 26.0, "energy": -14.0, "food": -8.0},
		"line": "%s chases the toy in circles until you both give up laughing.",
	},
	"brush": {
		"label": "Brush", "icon": "brush", "pose": "crown", "cooldown": 18.0, "cost": 0,
		"xp": 7, "bond": 2,
		"stats": {"clean": 16.0, "mood": 14.0},
		"line": "%s leans into the brush and closes both eyes.",
	},
	"sleep": {
		"label": "Nap", "icon": "energy", "pose": "sleep", "cooldown": 45.0, "cost": 0,
		"xp": 6, "bond": 1,
		"stats": {"energy": 46.0, "health": 6.0, "mood": 4.0},
		"line": "%s curls into a small warm circle and drifts off.",
	},
	"heal": {
		"label": "Vet", "icon": "health", "pose": "curious", "cooldown": 60.0, "cost": 60,
		"xp": 10, "bond": 2,
		"stats": {"health": 40.0, "mood": -4.0},
		"line": "The vet says %s is in wonderful shape.",
	},
}

## Caring for a rescue in the sanctuary raises trust instead of stats.
const TAME_ACTIONS := {
	"tame_feed": {"label": "Offer food", "trust": 18, "cooldown": 6.0, "line": "%s edges closer and takes the food."},
	"tame_soothe": {"label": "Soothe", "trust": 14, "cooldown": 6.0, "line": "You sit very still. %s stops trembling."},
	"tame_play": {"label": "Play", "trust": 16, "cooldown": 6.0, "line": "%s bats at the ribbon and forgets to be afraid."},
}

## The five things the To Do card asks for each day.
const DAILY_TASKS := [
	{"id": "t_care", "label": "Pet care", "track": "care", "target": 3, "coins": 60},
	{"id": "t_play", "label": "Play time", "track": "play", "target": 1, "coins": 50},
	{"id": "t_decorate", "label": "Decorate", "track": "decorate", "target": 1, "coins": 50},
	{"id": "t_friends", "label": "Meet friends", "track": "friends", "target": 1, "coins": 60},
	{"id": "t_happy", "label": "Be happy!", "track": "happy", "target": 1, "coins": 80},
]
## Clearing the whole list pays this on top of the individual rewards.
const DAILY_CLEAR_HEARTS := 1
const DAILY_CLEAR_GEMS := 2

const AD_REWARD_COINS := 60
const AD_COOLDOWN_SEC := 90.0
const AD_DAILY_LIMIT := 12

var save: Dictionary = {}

var _tick := 0.0
var _loaded := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if has_save():
		load_game()


func _process(delta: float) -> void:
	if not _loaded:
		return
	_tick += delta
	if _tick < 5.0:
		return
	var hours := _tick / 3600.0
	_tick = 0.0
	_decay(hours)
	save["last"] = _now()
	ticked.emit()


## --- save / load -------------------------------------------------------

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	if not has_save():
		return false
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("Little Paws: save file unreadable, starting fresh.")
		return false
	save = parsed
	_migrate()
	_loaded = true
	_apply_offline()
	daily_check()
	changed.emit()
	return true


func save_game() -> void:
	if not _loaded:
		return
	save["last"] = _now()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Little Paws: could not write save file.")
		return
	file.store_string(JSON.stringify(save))
	file.close()


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	save = {}
	_loaded = false


func new_game(species_id: String, pet_name: String, owner_name: String) -> void:
	var now := _now()
	save = {
		"v": SAVE_VERSION,
		"created": now,
		"last": now,
		"owner": {"name": owner_name, "outfit": "outfit_default"},
		"pet": {
			"species": species_id,
			"name": pet_name,
			"born": now,
			"xp": 0,
			"bond": 0,
			"accessory": "acc_none",
			"stats": {"food": 45.0, "clean": 40.0, "energy": 55.0, "mood": 50.0, "health": 92.0},
		},
		"wallet": {"coins": 350, "gems": 5, "hearts": 3},
		"inventory": {"fish_snack": 4, "milk_bone": 4, "seed_mix": 4},
		"owned": Data.default_owned(),
		"decor": "decor_default",
		"chapter": 0,
		"goals": {},
		"chapters_done": [],
		"counters": {"care_total": 0, "coins_earned": 0, "ads": 0},
		"library": {},
		"badges": {},
		"daily": {"date": _today(), "streak": 1},
		"ads": {"date": _today(), "count": 0, "last": 0},
		"cooldowns": {},
		"tasks": {"date": _today(), "progress": {}, "claimed": []},
		"mail": [],
		"seen": {},
	}
	_loaded = true
	save_game()
	changed.emit()


func _migrate() -> void:
	var defaults := {
		"v": SAVE_VERSION, "goals": {}, "chapters_done": [], "counters": {},
		"library": {}, "badges": {}, "cooldowns": {}, "inventory": {},
		"owned": Data.default_owned(), "decor": "decor_default", "chapter": 0,
		"daily": {"date": _today(), "streak": 1},
		"ads": {"date": _today(), "count": 0, "last": 0},
		"tasks": {"date": _today(), "progress": {}, "claimed": []},
		"mail": [], "seen": {},
	}
	for key: String in defaults.keys():
		if not save.has(key):
			save[key] = defaults[key]
	var wallet: Dictionary = save.get("wallet", {})
	if not wallet.has("hearts"):
		wallet["hearts"] = 3
	var stats: Dictionary = pet().get("stats", {})
	for key: String in STAT_KEYS:
		if not stats.has(key):
			stats[key] = 70.0


## --- convenience accessors --------------------------------------------

func started() -> bool:
	return _loaded and save.has("pet")


func pet() -> Dictionary:
	return save.get("pet", {})


func pet_name() -> String:
	return String(pet().get("name", "your pet"))


func pet_species() -> String:
	return String(pet().get("species", "ragdoll"))


func owner_name() -> String:
	return String(save.get("owner", {}).get("name", "Friend"))


func coins() -> int:
	return int(save.get("wallet", {}).get("coins", 0))


func gems() -> int:
	return int(save.get("wallet", {}).get("gems", 0))


func hearts() -> int:
	return int(save.get("wallet", {}).get("hearts", 0))


## The player's own level, separate from the pet's growth. It rises from every
## kind of progress, so the header always reflects the whole journey.
func player_xp() -> int:
	return counter("player_xp")


func player_level_info() -> Dictionary:
	var remaining := player_xp()
	var level := 1
	var need := 100
	while remaining >= need and level < 99:
		remaining -= need
		level += 1
		need = 100 + (level - 1) * 60
	return {"level": level, "into": remaining, "need": need}


func player_level() -> int:
	return int(player_level_info()["level"])


func stat(key: String) -> float:
	return float(pet().get("stats", {}).get(key, 0.0))


func bond() -> int:
	return int(pet().get("bond", 0))


func xp() -> int:
	return int(pet().get("xp", 0))


func stage() -> int:
	var current := 0
	for i in STAGE_XP.size():
		if xp() >= STAGE_XP[i]:
			current = i
	return current


func stage_name() -> String:
	return STAGES[stage()]


## Progress toward the next growth stage, 0..1.
func stage_progress() -> float:
	var s := stage()
	if s >= STAGE_XP.size() - 1:
		return 1.0
	var floor_xp := STAGE_XP[s]
	var next_xp := STAGE_XP[s + 1]
	return clampf(float(xp() - floor_xp) / float(next_xp - floor_xp), 0.0, 1.0)


## The pet's overall wellbeing, used for its expression.
func wellbeing() -> float:
	var total := 0.0
	for key: String in STAT_KEYS:
		total += stat(key)
	return total / float(STAT_KEYS.size())


func mood_pose() -> String:
	if stat("energy") < 35.0:
		return "curl"
	if wellbeing() >= 78.0:
		return "happy"
	if wellbeing() <= 45.0:
		return "loaf"
	return "idle"


## --- stats & time ------------------------------------------------------

func _now() -> int:
	return int(Time.get_unix_time_from_system())


func _today() -> String:
	return Time.get_date_string_from_system()


func _decay(hours: float) -> void:
	if hours <= 0.0:
		return
	var stats: Dictionary = pet().get("stats", {})
	for key: String in DECAY.keys():
		var value: float = float(stats.get(key, 70.0)) - float(DECAY[key]) * hours
		stats[key] = maxf(COMFORT_FLOOR, value)


func _apply_offline() -> void:
	var away := float(_now() - int(save.get("last", _now()))) / 3600.0
	_decay(minf(away, MAX_OFFLINE_HOURS))
	save["last"] = _now()


func hours_away() -> float:
	return float(_now() - int(save.get("last", _now()))) / 3600.0


## --- cooldowns ---------------------------------------------------------

func cooldown_left(key: String) -> float:
	var ends := float(save.get("cooldowns", {}).get(key, 0))
	return maxf(0.0, ends - float(_now()))


func on_cooldown(key: String) -> bool:
	return cooldown_left(key) > 0.0


func _start_cooldown(key: String, seconds: float) -> void:
	(save["cooldowns"] as Dictionary)[key] = float(_now()) + seconds


## --- care --------------------------------------------------------------

## Why a care action cannot run right now, or "" if it can.
func care_blocked_reason(action_id: String) -> String:
	var action: Dictionary = ACTIONS.get(action_id, {})
	if action.is_empty():
		return "Unknown action"
	if on_cooldown(action_id):
		return "In a moment…"
	if int(action.get("cost", 0)) > coins():
		return "Not enough coins"
	if bool(action.get("needs_food", false)) and food_count() <= 0:
		return "No food left"
	var stats: Dictionary = action.get("stats", {})
	var raises_something := false
	var all_full := true
	for key: String in stats.keys():
		if float(stats[key]) <= 0.0:
			continue
		raises_something = true
		if stat(key) < 98.0:
			all_full = false
	if raises_something and all_full:
		return "%s does not need that right now" % pet_name()
	return ""


func food_count() -> int:
	var total := 0
	var inventory: Dictionary = save.get("inventory", {})
	for id: String in inventory.keys():
		if Data.category_of(id) == "food":
			total += int(inventory[id])
	return total


func first_food() -> String:
	var favorite := String(Data.get_species(pet_species()).get("favorite", ""))
	var inventory: Dictionary = save.get("inventory", {})
	if int(inventory.get(favorite, 0)) > 0:
		return favorite
	for id: String in inventory.keys():
		if Data.category_of(id) == "food" and int(inventory[id]) > 0:
			return id
	return ""


func do_care(action_id: String) -> bool:
	var reason := care_blocked_reason(action_id)
	if reason != "":
		toast.emit(reason)
		return false

	var action: Dictionary = ACTIONS[action_id]
	var bonus := 1.0
	if bool(action.get("needs_food", false)):
		var food_id := first_food()
		var inventory: Dictionary = save["inventory"]
		inventory[food_id] = int(inventory[food_id]) - 1
		if int(inventory[food_id]) <= 0:
			inventory.erase(food_id)
		if food_id == String(Data.get_species(pet_species()).get("favorite", "")):
			bonus = 1.25

	var cost := int(action.get("cost", 0))
	if cost > 0:
		_spend_coins(cost)

	var stats: Dictionary = pet()["stats"]
	for key: String in (action.get("stats", {}) as Dictionary).keys():
		var delta := float(action["stats"][key])
		if delta > 0.0:
			delta *= bonus
		stats[key] = clampf(float(stats.get(key, 70.0)) + delta, COMFORT_FLOOR, 100.0)

	var before_stage := stage()
	pet()["xp"] = xp() + int(round(float(action.get("xp", 0)) * bonus))
	pet()["bond"] = clampi(bond() + int(action.get("bond", 0)), 0, 100)

	_bump("care_total")
	_bump(action_id)
	_bump("player_xp", 5)
	_task_bump("care")
	if action_id == "play":
		_task_bump("play")
	_advance_goals("action", action_id)
	_advance_goals("care_total", "")

	pose_hint.emit(String(action.get("pose", "happy")))
	toast.emit(String(action.get("line", "%s is happy.")) % pet_name())

	if stage() > before_stage:
		celebrate.emit(
			"%s grew up!" % pet_name(),
			"%s is now a %s. Look how far you have come together." % [pet_name(), stage_name()],
			"stage"
		)

	_start_cooldown(action_id, float(action.get("cooldown", 8.0)))
	_after_change()
	return true


## --- economy -----------------------------------------------------------

func add_coins(amount: int) -> void:
	var wallet: Dictionary = save["wallet"]
	wallet["coins"] = int(wallet.get("coins", 0)) + amount
	if amount > 0:
		_bump("coins_earned", amount)


func add_gems(amount: int) -> void:
	var wallet: Dictionary = save["wallet"]
	wallet["gems"] = int(wallet.get("gems", 0)) + amount


func add_hearts(amount: int) -> void:
	var wallet: Dictionary = save["wallet"]
	wallet["hearts"] = int(wallet.get("hearts", 0)) + amount


func _spend_hearts(amount: int) -> void:
	var wallet: Dictionary = save["wallet"]
	wallet["hearts"] = maxi(0, int(wallet.get("hearts", 0)) - amount)


func _spend_coins(amount: int) -> void:
	var wallet: Dictionary = save["wallet"]
	wallet["coins"] = maxi(0, int(wallet.get("coins", 0)) - amount)


func _spend_gems(amount: int) -> void:
	var wallet: Dictionary = save["wallet"]
	wallet["gems"] = maxi(0, int(wallet.get("gems", 0)) - amount)


func can_afford(price: int, currency: String) -> bool:
	match currency:
		"gems": return gems() >= price
		"hearts": return hearts() >= price
	return coins() >= price


func buy(category: String, item_id: String) -> bool:
	var item := Data.item(category, item_id)
	if item.is_empty() or owns(item_id):
		return false
	var price := int(item.get("price", 0))
	var currency := String(item.get("currency", "coins"))
	if not can_afford(price, currency):
		toast.emit("Not enough %s yet." % currency)
		return false
	match currency:
		"gems": _spend_gems(price)
		"hearts": _spend_hearts(price)
		_: _spend_coins(price)
	(save["owned"] as Array).append(item_id)
	toast.emit("%s is yours." % String(item.get("name", item_id)))
	_after_change()
	return true


func buy_food(item_id: String, count: int = 1) -> bool:
	var item := Data.item("food", item_id)
	if item.is_empty():
		return false
	var price := int(item.get("price", 0)) * count
	if not can_afford(price, "coins"):
		toast.emit("Not enough coins yet.")
		return false
	_spend_coins(price)
	var inventory: Dictionary = save["inventory"]
	inventory[item_id] = int(inventory.get(item_id, 0)) + count
	toast.emit("%s x%d added to the pantry." % [String(item["name"]), count])
	_after_change()
	return true


func owns(item_id: String) -> bool:
	return (save.get("owned", []) as Array).has(item_id)


func equip(item_id: String) -> void:
	if not owns(item_id):
		return
	match Data.category_of(item_id):
		"outfit":
			(save["owner"] as Dictionary)["outfit"] = item_id
		"accessory":
			pet()["accessory"] = item_id
		"decor":
			save["decor"] = item_id
		_:
			return
	if item_id not in ["outfit_default", "acc_none", "decor_default"]:
		_advance_goals("equip", "")
		_task_bump("decorate")
	_after_change()


func equipped(category: String) -> String:
	match category:
		"outfit":
			return String(save.get("owner", {}).get("outfit", "outfit_default"))
		"accessory":
			return String(pet().get("accessory", "acc_none"))
		"decor":
			return String(save.get("decor", "decor_default"))
	return ""


## --- rewarded video (IAA) ---------------------------------------------

func ad_available() -> bool:
	var ads: Dictionary = save.get("ads", {})
	if String(ads.get("date", "")) != _today():
		return true
	if int(ads.get("count", 0)) >= AD_DAILY_LIMIT:
		return false
	return float(_now()) - float(ads.get("last", 0)) >= AD_COOLDOWN_SEC


func ad_wait_seconds() -> float:
	var ads: Dictionary = save.get("ads", {})
	return maxf(0.0, AD_COOLDOWN_SEC - (float(_now()) - float(ads.get("last", 0))))


func ads_left_today() -> int:
	var ads: Dictionary = save.get("ads", {})
	if String(ads.get("date", "")) != _today():
		return AD_DAILY_LIMIT
	return maxi(0, AD_DAILY_LIMIT - int(ads.get("count", 0)))


## Called once a rewarded video finishes. See docs/MONETISATION.md for where
## a real ad SDK plugs in; this only grants the reward.
func grant_ad_reward(coin_amount: int = AD_REWARD_COINS, gem_amount: int = 0) -> void:
	var ads: Dictionary = save["ads"]
	if String(ads.get("date", "")) != _today():
		ads["date"] = _today()
		ads["count"] = 0
	ads["count"] = int(ads["count"]) + 1
	ads["last"] = _now()
	add_coins(coin_amount)
	if gem_amount > 0:
		add_gems(gem_amount)
	_bump("ads")
	toast.emit("Thanks for watching! +%d coins" % coin_amount)
	_after_change()


## --- daily streak ------------------------------------------------------

func daily_check() -> void:
	var daily: Dictionary = save.get("daily", {})
	var today := _today()
	if String(daily.get("date", "")) == today:
		return
	var yesterday := Time.get_date_string_from_unix_time(_now() - 86400)
	daily["streak"] = int(daily.get("streak", 0)) + 1 if String(daily.get("date", "")) == yesterday else 1
	daily["date"] = today
	var streak := int(daily["streak"])
	var coin_reward := 40 + mini(streak, 7) * 15
	add_coins(coin_reward)
	var gem_reward := 0
	if streak % 7 == 0:
		gem_reward = 5
		add_gems(gem_reward)
	celebrate.emit(
		"Day %d together" % streak,
		"Welcome back. +%d coins%s" % [coin_reward, (" and +%d gems" % gem_reward) if gem_reward > 0 else ""],
		"daily"
	)
	_after_change()


func streak() -> int:
	return int(save.get("daily", {}).get("streak", 1))


## --- chapters & goals --------------------------------------------------

func chapter_index() -> int:
	return int(save.get("chapter", 0))


func current_chapter() -> Dictionary:
	return Data.chapter(chapter_index())


func chapters_done() -> int:
	return (save.get("chapters_done", []) as Array).size()


func chapter_cleared(chapter_id: String) -> bool:
	return (save.get("chapters_done", []) as Array).has(chapter_id)


func goal_target(goal: Dictionary) -> int:
	return maxi(1, int(goal.get("target", 1)))


func goal_progress(goal: Dictionary) -> int:
	var type := String(goal.get("type", ""))
	match type:
		"bond":
			return bond()
		"stage":
			return stage()
		"homed":
			return homed_count()
		"rescue":
			return 1 if is_rescued(String(goal.get("key", ""))) else 0
		_:
			return int((save.get("goals", {}) as Dictionary).get(String(goal.get("id", "")), 0))


func goal_done(goal: Dictionary) -> bool:
	return goal_progress(goal) >= goal_target(goal)


## Bumps stored progress for goals of a given type in the active chapter.
func _advance_goals(type: String, key: String) -> void:
	var chapter := current_chapter()
	if chapter.is_empty():
		return
	var goals: Dictionary = save["goals"]
	for goal: Dictionary in chapter.get("goals", []):
		if String(goal.get("type", "")) != type:
			continue
		if type == "action" and String(goal.get("key", "")) != key:
			continue
		var id := String(goal.get("id", ""))
		var target := goal_target(goal)
		goals[id] = mini(int(goals.get(id, 0)) + 1, target)


func _check_chapter() -> void:
	var chapter := current_chapter()
	if chapter.is_empty():
		return
	for goal: Dictionary in chapter.get("goals", []):
		if not goal_done(goal):
			return

	var chapter_id := String(chapter.get("id", ""))
	if chapter_cleared(chapter_id):
		return
	(save["chapters_done"] as Array).append(chapter_id)

	var reward: Dictionary = chapter.get("reward", {})
	var coin_reward := int(reward.get("coins", 0))
	var gem_reward := int(reward.get("gems", 0))
	add_coins(coin_reward)
	add_gems(gem_reward)
	_bump("player_xp", 120)
	save["chapter"] = chapter_index() + 1

	celebrate.emit(
		"%s complete" % String(chapter.get("title", "Chapter")),
		"+%d coins, +%d gems. A new part of the world just opened up." % [coin_reward, gem_reward],
		"chapter"
	)


## --- rescue, taming, homing -------------------------------------------

func library() -> Dictionary:
	return save.get("library", {})


func is_rescued(species_id: String) -> bool:
	return library().has(species_id)


func entry(species_id: String) -> Dictionary:
	return library().get(species_id, {})


func trust(species_id: String) -> int:
	return int(entry(species_id).get("trust", 0))


func is_tamed(species_id: String) -> bool:
	return trust(species_id) >= 100


func is_homed(species_id: String) -> bool:
	return String(entry(species_id).get("friend", "")) != ""


func rescued_count() -> int:
	return library().size()


func tamed_count() -> int:
	var total := 0
	for id: String in library().keys():
		if is_tamed(id):
			total += 1
	return total


func homed_count() -> int:
	var total := 0
	for id: String in library().keys():
		if is_homed(id):
			total += 1
	return total


## Animals rescued but not yet placed with a friend.
func sanctuary_ids() -> Array:
	var out: Array = []
	for id: String in library().keys():
		if not is_homed(id):
			out.append(id)
	return out


func rescue(species_id: String) -> void:
	if is_rescued(species_id):
		return
	(save["library"] as Dictionary)[species_id] = {
		"rescued": _now(), "trust": 0, "friend": "", "homed_at": 0
	}
	_advance_goals("rescue", species_id)
	_bump("player_xp", 40)
	push_mail("%s is safe" % Data.species_name(species_id),
		"They are resting in the sanctuary. Sit with them when you can.", {}, true)
	celebrate.emit(
		"%s is safe!" % Data.species_name(species_id),
		"They are shy for now. Care for them in the Sanctuary until they trust you.",
		"rescue"
	)
	_after_change()


func tame_blocked_reason(species_id: String, action_id: String) -> String:
	if not is_rescued(species_id):
		return "Not rescued yet"
	if is_tamed(species_id):
		return "Already fully tamed"
	var key := "%s:%s" % [species_id, action_id]
	if on_cooldown(key):
		return "In a moment…"
	if action_id == "tame_feed" and food_count() <= 0:
		return "No food left"
	return ""


func do_tame(species_id: String, action_id: String) -> bool:
	var reason := tame_blocked_reason(species_id, action_id)
	if reason != "":
		toast.emit(reason)
		return false

	var action: Dictionary = TAME_ACTIONS[action_id]
	if action_id == "tame_feed":
		var food_id := first_food()
		var inventory: Dictionary = save["inventory"]
		inventory[food_id] = int(inventory[food_id]) - 1
		if int(inventory[food_id]) <= 0:
			inventory.erase(food_id)

	var record: Dictionary = (save["library"] as Dictionary)[species_id]
	var before := int(record.get("trust", 0))
	record["trust"] = mini(100, before + int(action.get("trust", 10)))
	_bump("care_total")
	_bump("player_xp", 8)
	_task_bump("friends")
	_advance_goals("care_total", "")
	_start_cooldown("%s:%s" % [species_id, action_id], float(action.get("cooldown", 6.0)))
	toast.emit(String(action.get("line", "%s relaxes.")) % Data.species_name(species_id))

	if before < 100 and int(record["trust"]) >= 100:
		celebrate.emit(
			"%s trusts you" % Data.species_name(species_id),
			"They are ready to meet the person they will spend their life with.",
			"tame"
		)
	_after_change()
	return true


## The person this animal has been waiting for, named by the artwork.
func destined_friend(species_id: String) -> String:
	return String(Data.get_species(species_id).get("friend", ""))


## Three candidate friends for a rescue, chosen deterministically so the
## offer does not change every time the screen is opened. The right one is
## always among them.
func friend_candidates(species_id: String) -> Array:
	var destined := destined_friend(species_id)
	var pool: Array = []
	for person: Dictionary in Data.npcs:
		if String(person.get("id", "")) != destined:
			pool.append(person)
	var seed_value := 0
	for c in species_id:
		seed_value += c.unicode_at(0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var picked: Array = []
	while picked.size() < mini(2, pool.size()):
		var candidate: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
		if candidate not in picked:
			picked.append(candidate)
	var right := Data.npc(destined)
	if not right.is_empty():
		picked.append(right)
	picked.sort_custom(func(a, b): return String(a.get("id", "")) < String(b.get("id", "")))
	return picked


## How well an NPC and an animal fit, 0..1. Higher pays a small gem bonus,
## but every match is a happy ending.
func match_score(species_id: String, npc_id: String) -> float:
	var traits: Array = Data.get_species(species_id).get("traits", [])
	var likes: Array = Data.npc(npc_id).get("likes", [])
	if traits.is_empty() or likes.is_empty():
		return 0.5
	var shared := 0
	for t: String in traits:
		if likes.has(t):
			shared += 1
	return clampf(0.4 + 0.3 * shared, 0.0, 1.0)


## Reuniting is a guess, but never a punished one: the wrong person costs
## nothing and the animal simply waits for you to try again.
func home_animal(species_id: String, npc_id: String) -> bool:
	if not is_tamed(species_id) or is_homed(species_id):
		return false
	var destined := destined_friend(species_id)
	if destined != "" and npc_id != destined:
		toast.emit("%s adores them, but they did not settle. Try someone else."
			% String(Data.npc(npc_id).get("name", "They")))
		return false
	var record: Dictionary = (save["library"] as Dictionary)[species_id]
	record["friend"] = npc_id
	record["homed_at"] = _now()

	var score := match_score(species_id, npc_id)
	var gem_reward := 3 + int(round(score * 4.0))
	var coin_reward := 120 + int(round(score * 120.0))
	add_gems(gem_reward)
	add_coins(coin_reward)
	add_hearts(1)
	_bump("player_xp", 60)
	_advance_goals("homed", "")
	push_mail("A thank-you note from %s" % String(Data.npc(npc_id).get("name", "a friend")),
		"%s settled in on the first night. I do not know how to thank you." % Data.species_name(species_id),
		{"coins": 80}, false)

	celebrate.emit(
		"A forever home",
		"%s is going home with %s. +%d coins, +%d gems" % [
			Data.species_name(species_id), String(Data.npc(npc_id).get("name", "a friend")),
			coin_reward, gem_reward
		],
		"home"
	)
	_after_change()
	return true


## --- daily to-do list --------------------------------------------------

## Rolls the To Do card over at midnight. Cheap enough to call on every change.
func _ensure_today() -> void:
	var tasks: Dictionary = save.get("tasks", {})
	if String(tasks.get("date", "")) == _today():
		return
	tasks["date"] = _today()
	tasks["progress"] = {}
	tasks["claimed"] = []


func _task_bump(track: String, amount: int = 1) -> void:
	_ensure_today()
	var progress: Dictionary = (save["tasks"] as Dictionary)["progress"]
	progress[track] = int(progress.get(track, 0)) + amount


func task_target(task: Dictionary) -> int:
	return maxi(1, int(task.get("target", 1)))


func task_progress(task: Dictionary) -> int:
	_ensure_today()
	var track := String(task.get("track", ""))
	if track == "happy":
		# Measured live: this one is about how your pet is doing right now.
		return 1 if wellbeing() >= 80.0 else 0
	var progress: Dictionary = (save["tasks"] as Dictionary).get("progress", {})
	return mini(int(progress.get(track, 0)), task_target(task))


func task_done(task: Dictionary) -> bool:
	return task_progress(task) >= task_target(task)


func task_claimed(task: Dictionary) -> bool:
	_ensure_today()
	return ((save["tasks"] as Dictionary).get("claimed", []) as Array).has(String(task.get("id", "")))


func task_claimable(task: Dictionary) -> bool:
	return task_done(task) and not task_claimed(task)


func any_task_claimable() -> bool:
	for task: Dictionary in DAILY_TASKS:
		if task_claimable(task):
			return true
	return false


func tasks_done_today() -> int:
	var total := 0
	for task: Dictionary in DAILY_TASKS:
		if task_done(task):
			total += 1
	return total


func claim_task(task_id: String) -> bool:
	for task: Dictionary in DAILY_TASKS:
		if String(task.get("id", "")) != task_id:
			continue
		if not task_claimable(task):
			return false
		var claimed: Array = (save["tasks"] as Dictionary)["claimed"]
		claimed.append(task_id)
		var coin_reward := int(task.get("coins", 0))
		add_coins(coin_reward)
		toast.emit("%s done. +%d coins" % [String(task.get("label", "Task")), coin_reward])

		if claimed.size() >= DAILY_TASKS.size():
			add_hearts(DAILY_CLEAR_HEARTS)
			add_gems(DAILY_CLEAR_GEMS)
			push_mail("A perfect day",
				"You finished everything on today's list. %s noticed." % pet_name(),
				{"hearts": DAILY_CLEAR_HEARTS, "gems": DAILY_CLEAR_GEMS}, true)
			celebrate.emit("Everything done", "The whole list is ticked off. +%d heart, +%d gems"
				% [DAILY_CLEAR_HEARTS, DAILY_CLEAR_GEMS], "daily")
		_after_change()
		return true
	return false


## --- mail --------------------------------------------------------------

## Adds a message to the inbox. `already_paid` marks a reward that was granted
## at the source, so the letter is a receipt rather than something to claim.
func push_mail(title: String, body: String, reward: Dictionary = {}, already_paid: bool = false) -> void:
	var inbox: Array = save.get("mail", [])
	inbox.push_front({
		"id": "m%d_%d" % [_now(), inbox.size()],
		"title": title, "body": body, "at": _now(),
		"read": false, "reward": reward, "claimed": already_paid or reward.is_empty(),
	})
	while inbox.size() > 40:
		inbox.pop_back()
	save["mail"] = inbox


func mail() -> Array:
	return save.get("mail", [])


func unread_mail() -> int:
	var total := 0
	for letter: Dictionary in mail():
		if not bool(letter.get("read", false)):
			total += 1
	return total


func claimable_mail() -> int:
	var total := 0
	for letter: Dictionary in mail():
		if not bool(letter.get("claimed", true)):
			total += 1
	return total


func read_all_mail() -> void:
	for letter: Dictionary in mail():
		letter["read"] = true
	_after_change()


func claim_mail(mail_id: String) -> bool:
	for letter: Dictionary in mail():
		if String(letter.get("id", "")) != mail_id or bool(letter.get("claimed", true)):
			continue
		var reward: Dictionary = letter.get("reward", {})
		add_coins(int(reward.get("coins", 0)))
		add_gems(int(reward.get("gems", 0)))
		add_hearts(int(reward.get("hearts", 0)))
		letter["claimed"] = true
		letter["read"] = true
		toast.emit("Gift collected.")
		_after_change()
		return true
	return false


## --- "new since you last looked" dots ----------------------------------

func mark_seen(key: String) -> void:
	(save["seen"] as Dictionary)[key] = _now()
	save_game()
	changed.emit()


func _seen_at(key: String) -> int:
	return int((save.get("seen", {}) as Dictionary).get(key, 0))


## A badge was earned since the player last opened Missions.
func missions_have_news() -> bool:
	var last := _seen_at("missions")
	for badge_id: String in (save.get("badges", {}) as Dictionary).keys():
		if int((save["badges"] as Dictionary)[badge_id]) > last:
			return true
	return false


## Someone in the sanctuary is fully tamed and waiting to be matched.
func friends_have_news() -> bool:
	for species_id: String in sanctuary_ids():
		if is_tamed(species_id):
			return true
	return false


## A rescue mission in the current chapter has not been attempted yet.
func events_have_news() -> bool:
	return not available_missions().is_empty()


## Rescue missions the player can start right now.
func available_missions() -> Array:
	var out: Array = []
	var chapter := current_chapter()
	for goal: Dictionary in chapter.get("goals", []):
		if String(goal.get("type", "")) == "rescue" and not goal_done(goal):
			out.append(String(goal.get("key", "")))
	return out


## --- badges ------------------------------------------------------------

func has_badge(badge_id: String) -> bool:
	return (save.get("badges", {}) as Dictionary).has(badge_id)


func badge_progress(badge: Dictionary) -> int:
	match String(badge.get("type", "")):
		"chapter": return chapters_done()
		"stage": return stage()
		"bond": return bond()
		"care_total": return counter("care_total")
		"rescued": return rescued_count()
		"homed": return homed_count()
		"cosmetics": return maxi(0, (save.get("owned", []) as Array).size() - Data.default_owned().size())
		"streak": return streak()
	return 0


func _check_badges() -> void:
	for badge: Dictionary in Data.badges:
		var id := String(badge.get("id", ""))
		if has_badge(id):
			continue
		if badge_progress(badge) < int(badge.get("target", 1)):
			continue
		(save["badges"] as Dictionary)[id] = _now()
		var gem_reward := int(badge.get("gems", 0))
		add_gems(gem_reward)
		_bump("player_xp", 25)
		push_mail("Badge earned: %s" % String(badge.get("name", id)),
			String(badge.get("text", "")), {"gems": gem_reward}, true)
		badge_unlocked.emit(id)
		celebrate.emit(
			"Badge earned: %s" % String(badge.get("name", id)),
			"%s  +%d gems" % [String(badge.get("text", "")), gem_reward],
			"badge"
		)


func badges_earned() -> int:
	return (save.get("badges", {}) as Dictionary).size()


## --- counters & plumbing ----------------------------------------------

func counter(key: String) -> int:
	return int((save.get("counters", {}) as Dictionary).get(key, 0))


func _bump(key: String, amount: int = 1) -> void:
	var counters: Dictionary = save["counters"]
	counters[key] = int(counters.get(key, 0)) + amount


func _after_change() -> void:
	_ensure_today()
	_check_chapter()
	_check_badges()
	save_game()
	changed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()
