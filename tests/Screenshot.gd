extends Node
## Boots the real game and writes screenshots of a few screens, so layout can
## be checked without a device. Run with:
##   xvfb-run -a godot --path . res://tests/Screenshot.tscn

const SHOTS := ["onboarding", "home", "daily", "missions", "events", "bag", "mail",
	"journey", "sanctuary", "library", "shop"]
const OUT_DIR := "user://shots"


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	var main: Node = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await get_tree().process_frame

	# A save with some progress makes the screenshots representative.
	GameState.delete_save()
	GameState.new_game("ragdoll", "Muffin", "Ngoc")
	GameState.add_coins(2000)
	GameState.add_gems(40)
	for id: String in ["hamster", "duckling", "pomeranian"]:
		GameState.rescue(id)
	(GameState.save["library"] as Dictionary)["hamster"]["trust"] = 100
	GameState.home_animal("hamster", "mai")
	GameState.save["tasks"] = {"date": Time.get_date_string_from_system(),
		"progress": {"care": 3, "play": 1}, "claimed": ["t_play"]}

	# The care sheet is a state of the home screen, so it gets its own pass.
	main.call("goto", "home", {"open_care": true})
	for i in 6:
		await get_tree().process_frame
	main.set("_celebration_queue", [])
	for modal in (main.get("_modal_layer") as Node).get_children():
		modal.queue_free()
	await get_tree().create_timer(0.15).timeout
	get_viewport().get_texture().get_image().save_png("%s/home_care.png" % OUT_DIR)
	print("wrote home_care.png")

	for screen_name: String in SHOTS:
		main.call("goto", screen_name)
		main.set("_celebration_queue", [])
		for modal in (main.get("_modal_layer") as Node).get_children():
			modal.queue_free()
		for i in 6:
			await get_tree().process_frame
		await get_tree().create_timer(0.15).timeout
		var image := get_viewport().get_texture().get_image()
		image.save_png("%s/%s.png" % [OUT_DIR, screen_name])
		print("wrote %s.png" % screen_name)

	print("user dir: %s" % OS.get_user_data_dir())
	get_tree().quit()
