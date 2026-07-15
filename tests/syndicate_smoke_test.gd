extends SceneTree

var failures: int = 0
var state: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[SYNDICATE RISING] Running standalone smoke tests...")
	_expect(load("res://scripts/syndicate_state.gd") is Script, "Campaign state script loads")
	_expect(load("res://scripts/syndicate_audio.gd") is Script, "Generated audio script loads")
	_expect(load("res://scripts/syndicate_city.gd") is Script, "Portrait city script loads")
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
	_expect(rooms_value is Array and (rooms_value as Array).size() == 8, "Eight criminal buildings exist")
	_expect(crew_value is Array and (crew_value as Array).size() == 4, "Four starter crew members exist")
	_expect(String(state.get("pending_cutscene")) == "prologue", "New campaign starts with the prologue")

	state.set("credits", 5000)
	var repair: Dictionary = state.call("repair_room", "chop_shop") as Dictionary
	_expect(bool(repair.get("ok", false)), "Damaged building can enter the rebuild queue")
	var chop_shop: Dictionary = state.call("get_room", "chop_shop") as Dictionary
	chop_shop["repaired"] = true
	chop_shop["repair_end"] = 0
	var upgrade: Dictionary = state.call("upgrade_room", "chop_shop") as Dictionary
	_expect(bool(upgrade.get("ok", false)), "Rebuilt building can be upgraded")
	_expect(int(chop_shop.get("level", 1)) == 2, "Upgrade raises building level")

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
		"res://assets/buildings/backroom_command.svg",
		"res://assets/buildings/chop_shop.svg",
		"res://assets/buildings/black_market.svg",
		"res://assets/buildings/safehouse_bunks.svg",
		"res://assets/buildings/street_clinic.svg",
		"res://assets/buildings/boss_office.svg",
		"res://assets/buildings/signal_den.svg",
		"res://assets/buildings/smuggler_tunnel.svg",
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
		_expect(city is Node2D, "Portrait city instantiates")
		city.queue_free()

	if failures == 0:
		print("SUCCESS: Syndicate Rising standalone smoke tests passed.")
	else:
		push_error("FAILED: %d Syndicate Rising smoke test(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
