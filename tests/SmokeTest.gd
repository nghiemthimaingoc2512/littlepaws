extends Node
## Headless end-to-end check of the game rules.
##   godot --headless --path . res://tests/SmokeTest.tscn
## Exits with code 1 if any check fails.

var _failures: int = 0
var _checks: int = 0


func _ready() -> void:
	GameState.delete_save()
	_test_new_game()
	_test_care_and_growth()
	_test_chapter_one()
	_test_rescue_flow()
	_test_economy()
	_test_daily_and_mail()
	_test_notifications()
	_test_decay_is_survivable()
	_test_save_round_trip()

	print("\n%d checks, %d failed" % [_checks, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("  FAIL  %s" % message)


func section(title: String) -> void:
	print("\n== %s" % title)


func clear_cooldowns() -> void:
	GameState.save["cooldowns"] = {}


func stock_pantry(count: int = 60) -> void:
	GameState.save["inventory"] = {"fish_snack": count, "seed_mix": count}


## ----------------------------------------------------------------------

func _test_new_game() -> void:
	section("new game")
	GameState.new_game("ragdoll", "Muffin", "Ngoc")
	check(GameState.started(), "game reports started")
	check(GameState.pet_name() == "Muffin", "pet name stored")
	check(GameState.owner_name() == "Ngoc", "owner name stored")
	check(GameState.stage() == 0 and GameState.stage_name() == "Baby", "starts at Baby stage")
	check(GameState.coins() > 0, "starts with coins")
	check(GameState.food_count() > 0, "starts with food")
	check(GameState.rescued_count() == 0, "library starts empty")


func _test_care_and_growth() -> void:
	section("care and growth")
	stock_pantry()
	clear_cooldowns()
	var before_bond := GameState.bond()
	check(GameState.do_care("feed"), "feeding works")
	check(GameState.bond() > before_bond, "feeding raises bond")
	check(not GameState.do_care("feed"), "feeding again is blocked by cooldown")
	check(GameState.care_blocked_reason("feed") != "", "cooldown is reported")

	clear_cooldowns()
	GameState.save["inventory"] = {}
	check(GameState.care_blocked_reason("feed") == "No food left", "empty pantry blocks feeding")
	stock_pantry()

	# Care enough to cross every growth stage. Six hours of decay pass between
	# rounds, because a pet cannot be fed twelve times in one afternoon.
	var rounds := 0
	for i in 400:
		clear_cooldowns()
		stock_pantry()
		for action_id: String in ["feed", "play", "bathe", "brush", "sleep"]:
			GameState.do_care(action_id)
		rounds += 1
		if GameState.stage() >= 3:
			break
		GameState._decay(6.0)
	check(rounds < 120, "Adult is reached in a sane number of sessions (%d)" % rounds)
	check(GameState.stage() == 3, "pet reaches Adult with steady care")
	check(GameState.stage_name() == "Adult", "adult stage name")
	check(GameState.bond() == 100, "bond caps at 100")
	check(GameState.stage_progress() == 1.0, "growth bar is full at Adult")

	for key: String in GameState.STAT_KEYS:
		check(GameState.stat(key) <= 100.0, "%s never exceeds 100" % key)


func _test_chapter_one() -> void:
	section("chapters")
	GameState.delete_save()
	GameState.new_game("corgi", "Bao", "Ngoc")
	stock_pantry()

	var chapter := GameState.current_chapter()
	check(String(chapter.get("id", "")) == "ch1", "first chapter is active")

	# No decay in between: this is one uninterrupted first session.
	for action_id: String in ["feed", "feed", "bathe", "play", "play", "sleep"]:
		clear_cooldowns()
		stock_pantry()
		check(GameState.do_care(action_id), "first session can %s" % action_id)
	check(GameState.chapter_cleared("ch1"), "chapter 1 clears when its goals are met")
	check(GameState.chapter_index() == 1, "the next chapter opens")
	check(GameState.has_badge("first_day"), "chapter 1 awards the First Day badge")
	check(GameState.gems() > 5, "chapter and badge rewards paid gems")


func _test_rescue_flow() -> void:
	section("rescue, taming and homing")
	check(not GameState.is_rescued("kitten_grey"), "the kitten starts undiscovered")

	GameState.rescue("kitten_grey")
	check(GameState.is_rescued("kitten_grey"), "rescue records the animal")
	check(GameState.trust("kitten_grey") == 0, "a new rescue starts at zero trust")
	check(GameState.sanctuary_ids().has("kitten_grey"), "the rescue waits in the sanctuary")
	check(GameState.has_badge("rescue_1"), "first rescue awards a badge")

	GameState.rescue("kitten_grey")
	check(GameState.rescued_count() == 1, "rescuing twice does not duplicate")

	stock_pantry()
	for i in 40:
		clear_cooldowns()
		stock_pantry()
		GameState.do_tame("kitten_grey", "tame_feed")
		GameState.do_tame("kitten_grey", "tame_soothe")
		if GameState.is_tamed("kitten_grey"):
			break
	check(GameState.is_tamed("kitten_grey"), "care raises trust to fully tamed")
	check(GameState.trust("kitten_grey") == 100, "trust caps at 100")

	var candidates := GameState.friend_candidates("kitten_grey")
	check(candidates.size() == 3, "three friends are offered")
	check(GameState.friend_candidates("kitten_grey") == candidates, "the same offer is shown twice")

	var coins_before := GameState.coins()
	var npc_id := GameState.destined_friend("kitten_grey")
	check(npc_id != "", "the artwork names the person this animal belongs with")
	var wrong_id := ""
	for candidate: Dictionary in candidates:
		if String(candidate.get("id", "")) != npc_id:
			wrong_id = String(candidate["id"])
			break
	check(not GameState.home_animal("kitten_grey", wrong_id), "the wrong person is turned down")
	check(GameState.homed_count() == 0, "and nothing is recorded")
	check(GameState.home_animal("kitten_grey", npc_id), "homing succeeds with the right person")
	check(GameState.is_homed("kitten_grey"), "the animal is recorded as homed")
	check(GameState.coins() > coins_before, "homing pays out")
	check(not GameState.sanctuary_ids().has("kitten_grey"), "a homed animal leaves the sanctuary")
	check(not GameState.home_animal("kitten_grey", npc_id), "an animal cannot be homed twice")
	check(GameState.has_badge("homed_1"), "first home awards a badge")

	# An untamed rescue cannot be homed.
	GameState.rescue("cat_ginger")
	check(not GameState.home_animal("cat_ginger", GameState.destined_friend("cat_ginger")),
		"an untamed animal cannot be homed")


func _test_economy() -> void:
	section("economy")
	var coins_before := GameState.coins()
	GameState.add_coins(500)
	check(GameState.coins() == coins_before + 500, "coins are added")

	check(GameState.buy("accessory", "acc_bow"), "an affordable item is bought")
	check(GameState.owns("acc_bow"), "the item is owned")
	check(not GameState.buy("accessory", "acc_bow"), "an owned item is not bought twice")
	GameState.equip("acc_bow")
	check(GameState.equipped("accessory") == "acc_bow", "the item is equipped")

	GameState.save["wallet"] = {"coins": 0, "gems": 0, "hearts": GameState.hearts()}
	check(not GameState.buy("outfit", "outfit_sakura"), "an unaffordable item is refused")
	check(not GameState.owns("outfit_sakura"), "a refused purchase grants nothing")

	GameState.add_coins(200)
	var pantry_before := GameState.food_count()
	check(GameState.buy_food("fish_snack", 5), "food is bought")
	check(GameState.food_count() == pantry_before + 5, "the pantry grows by the amount bought")

	check(GameState.ad_available(), "a rewarded video is offered")
	var coins_pre_ad := GameState.coins()
	GameState.grant_ad_reward()
	check(GameState.coins() == coins_pre_ad + GameState.AD_REWARD_COINS, "the ad reward is paid")
	check(not GameState.ad_available(), "the ad goes on cooldown")


func _test_daily_and_mail() -> void:
	section("daily list, hearts and mail")
	check(GameState.hearts() > 0, "hearts are a real currency")
	check(GameState.player_level() >= 1, "the player has their own level")
	check(int(GameState.player_level_info()["need"]) > 0, "the level bar has a target")

	# Start the day fresh.
	GameState.save["tasks"] = {"date": Time.get_date_string_from_system(),
		"progress": {}, "claimed": []}
	var care_task: Dictionary = GameState.DAILY_TASKS[0]
	check(not GameState.task_done(care_task), "the care task starts unfinished")

	for action_id: String in ["feed", "play", "brush"]:
		clear_cooldowns()
		stock_pantry()
		GameState._decay(4.0)
		check(GameState.do_care(action_id), "care task accepts %s" % action_id)
	check(GameState.task_done(care_task), "three care moments finish the care task")
	check(GameState.task_claimable(care_task), "a finished task can be collected")

	var coins_before := GameState.coins()
	check(GameState.claim_task("t_care"), "collecting a task works")
	check(GameState.coins() > coins_before, "collecting a task pays")
	check(not GameState.claim_task("t_care"), "a task cannot be collected twice")

	# Finish the rest of the list; the completion bonus should land.
	var hearts_before := GameState.hearts()
	var progress: Dictionary = (GameState.save["tasks"] as Dictionary)["progress"]
	progress["play"] = 9
	progress["decorate"] = 9
	progress["friends"] = 9
	var stats: Dictionary = GameState.pet()["stats"]
	for key: String in GameState.STAT_KEYS:
		stats[key] = 100.0
	for task: Dictionary in GameState.DAILY_TASKS:
		GameState.claim_task(String(task.get("id", "")))
	check(GameState.tasks_done_today() == GameState.DAILY_TASKS.size(),
		"the whole list can be finished in a day")
	check(GameState.hearts() > hearts_before, "finishing the whole list pays a heart")
	check(not GameState.any_task_claimable(), "nothing is left to collect")

	check(GameState.mail().size() > 0, "rescues and badges write letters to the inbox")
	var gift_id := ""
	for letter: Dictionary in GameState.mail():
		if not bool(letter.get("claimed", true)):
			gift_id = String(letter.get("id", ""))
			break
	check(gift_id != "", "a thank-you note arrived with a gift attached")
	if gift_id != "":
		var before_gift := GameState.coins()
		check(GameState.claim_mail(gift_id), "a gift can be collected")
		check(GameState.coins() > before_gift, "the gift pays out")
		check(not GameState.claim_mail(gift_id), "a gift cannot be collected twice")

	GameState.read_all_mail()
	check(GameState.unread_mail() == 0, "opening the inbox clears its badge")


func _test_notifications() -> void:
	section("what the red dots mean")
	for id: String in GameState.sanctuary_ids():
		(GameState.save["library"] as Dictionary)[id]["trust"] = 0
	check(not GameState.friends_have_news(), "no dot while nobody is ready to be matched")

	var waiting: Array = GameState.sanctuary_ids()
	check(not waiting.is_empty(), "someone is still waiting in the sanctuary")
	if not waiting.is_empty():
		(GameState.save["library"] as Dictionary)[String(waiting[0])]["trust"] = 100
		check(GameState.friends_have_news(), "a dot appears when someone is ready to be matched")

	GameState.mark_seen("missions")
	check(not GameState.missions_have_news(), "no dot straight after opening Missions")
	(GameState.save["badges"] as Dictionary)["_probe"] = GameState._now() + 5
	check(GameState.missions_have_news(), "a dot appears when a badge is earned afterwards")
	(GameState.save["badges"] as Dictionary).erase("_probe")

	# Little Paws Park: a rescue chapter whose animals this run has not found.
	GameState.save["chapter"] = 4
	check(not GameState.available_missions().is_empty(), "a rescue chapter offers missions")
	check(GameState.events_have_news(), "a dot appears on Events while animals need help")


func _test_decay_is_survivable() -> void:
	section("no fail state")
	GameState.save["last"] = GameState._now() - 60 * 60 * 24 * 30
	GameState._apply_offline()
	for key: String in GameState.STAT_KEYS:
		check(GameState.stat(key) >= GameState.COMFORT_FLOOR,
			"%s never falls below the comfort floor after a month away" % key)
	check(GameState.started(), "the pet is still there after a month away")


func _test_save_round_trip() -> void:
	section("saving")
	GameState.save_game()
	var pet_name := GameState.pet_name()
	var rescued := GameState.rescued_count()
	var coins := GameState.coins()
	var badges := GameState.badges_earned()

	check(GameState.has_save(), "a save file exists")
	check(GameState.load_game(), "the save loads back")
	check(GameState.pet_name() == pet_name, "the pet survives a reload")
	check(GameState.rescued_count() == rescued, "the library survives a reload")
	check(GameState.badges_earned() == badges, "badges survive a reload")
	check(absi(GameState.coins() - coins) < 200, "the wallet survives a reload")
