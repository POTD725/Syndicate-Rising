extends SceneTree

var failures: int = 0
var state: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[SYNDICATE RISING] Running lunar hideout smoke tests...")
	_expect(load("res://scripts/syndicate_state.gd") is Script, "Base campaign state script loads")
	_expect(load("res://scripts/syndicate_lunar_state.gd") is Script, "Lunar campaign state script loads")
	_expect(load("res://scripts/syndicate_lunar_city.gd") is Script, "Living lunar hideout script loads")
	_expect(load("res://scripts/syndicate_audio.gd") is Script, "Generated audio script loads")
	_expect(load("res://scripts/syndicate_scores.gd") is Script, "Score board script loads")
	_expect(load("res://scripts/syndicate_raid.gd") is Script, "Tactical raid script loads")
	_expect(load("res://scripts/syndicate_cutscene.gd") is Script, "Cutscene script loads")

	state = root.get_node_or_null("SyndicateState")
	_expect(state != null, "SyndicateState autoload exists")
	if state == null:
		quit(1)
		return

	state.call("reset_state")
	var rooms_value: Variant = state.get("rooms")
	var crew_value: Variant = state.get("crew")
	_expect(rooms_value is Array and (rooms_value as Array).size() == 12, "Twelve connected criminal hideout rooms exist")
	_expect(crew_value is Array and (crew_value as Array).size() == 4, "Four starter crew members exist")
	_expect(String(state.get("pending_cutscene")) == "prologue", "New campaign starts with the prologue")
	_expect(not (state.call("get_room", "black_research") as Dictionary).is_empty(), "Black Research Lab exists")
	_expect(not (state.call("get_room", "weapons_workshop") as Dictionary).is_empty(), "Weapons Workshop exists")
	_expect(not (state.call("get_room", "signal_den") as Dictionary).is_empty(), "Hacker Training Den exists")
	_expect(not (state.call("get_room", "enforcer_gym") as Dictionary).is_empty(), "Enforcer Training Room exists")
	_expect(not (state.call("get_room", "sharpshooter_range") as Dictionary).is_empty(), "Sharpshooter Range exists")

	state.set("credits", 5000)
	state.set("intel", 100)
	state.set("contraband", 100)
	var repair: Dictionary = state.call("repair_room", "chop_shop") as Dictionary
	_expect(bool(repair.get("ok", false)), "Damaged Runner Garage can enter the rebuild queue")
	var runner_garage: Dictionary = state.call("get_room", "chop_shop") as Dictionary
	runner_garage["repaired"] = true
	runner_garage["repair_end"] = 0
	var upgrade: Dictionary = state.call("upgrade_room", "chop_shop") as Dictionary
	_expect(bool(upgrade.get("ok", false)), "Rebuilt room can be upgraded")
	_expect(int(runner_garage.get("level", 1)) == 2, "Upgrade raises room level")

	var signal_den: Dictionary = state.call("get_room", "signal_den") as Dictionary
	var research_lab: Dictionary = state.call("get_room", "black_research") as Dictionary
	signal_den["repaired"] = true
	research_lab["repaired"] = true
	var research_result: Dictionary = state.call("run_room_operation", "black_research") as Dictionary
	_expect(bool(research_result.get("ok", false)), "Black Research starts through the room operation system")
	_expect(int(state.get("black_tech_end")) > 0, "Research timer is active")

	var workshop: Dictionary = state.call("get_room", "weapons_workshop") as Dictionary
	workshop["repaired"] = true
	var old_power: int = int((crew_value as Array)[0].get("power", 0))
	var weapons_result: Dictionary = state.call("run_room_operation", "weapons_workshop") as Dictionary
	_expect(bool(weapons_result.get("ok", false)), "Weapons Workshop crafts crew equipment")
	_expect(int((crew_value as Array)[0].get("power", 0)) > old_power, "Crafted equipment increases crew power")

	state.set("next_job_at", 0)
	state.call("tick")
	var jobs_value: Variant = state.get("jobs")
	_expect(jobs_value is Array and not (jobs_value as Array).is_empty(), "Score generation produces a criminal job")
	if jobs_value is Array and not (jobs_value as Array).is_empty():
		var first_job: Dictionary = (jobs_value as Array)[0] as Dictionary
		_expect(bool(first_job.get("story", false)), "Opening score is the chapter story job")
		var selected_crew: Array[String] = ["crew_1"]
		var launch: Dictionary = state.call("begin_job", String(first_job.get("id", "")), selected_crew) as Dictionary
		_expect(bool(launch.get("ok", false)), "Available crew can launch a score")
		state.call("finish_job", true, {"crew_1": 80})
		_expect(int(state.get("story_chapter")) == 2, "Winning chapter one advances the story")

	var scene_paths: Array[String] = [
		"res://scenes/SyndicateCity.tscn",
		"res://scenes/SyndicateScores.tscn",
		"res://scenes/SyndicateRaid.tscn",
		"res://scenes/SyndicateCutscene.tscn"
	]
	for path: String in scene_paths:
		_expect(load(path) is PackedScene, "Scene parses: %s" % path.get_file())

	var art_paths: Array[String] = [
		"res://assets/syndicate_emblem.svg",
		"res://assets/portraits/nyx_raze.svg",
		"res://assets/portraits/vox_13.svg",
		"res://assets/portraits/cinder_quell.svg",
		"res://assets/portraits/grit_mercer.svg",
		"res://assets/enemies/peacekeeper_response.svg",
		"res://assets/cutscenes/crater_market_falls.svg",
		"res://assets/cutscenes/ghost_key_network.svg",
		"res://assets/cutscenes/take_back_dark.svg"
	]
	for path: String in art_paths:
		_expect(load(path) is Texture2D, "Artwork imports: %s" % path.get_file())

	state.set("intro_seen", true)
	state.set("pending_cutscene", "")
	var city_scene: PackedScene = load("res://scenes/SyndicateCity.tscn") as PackedScene
	if city_scene != null:
		var city: Node = city_scene.instantiate()
		root.add_child(city)
		await process_frame
		await process_frame
		_expect(city is Node2D, "Living lunar hideout instantiates")
		city.queue_free()

	if failures == 0:
		print("SUCCESS: Syndicate Rising lunar hideout smoke tests passed.")
	else:
		push_error("FAILED: %d Syndicate Rising smoke test(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
