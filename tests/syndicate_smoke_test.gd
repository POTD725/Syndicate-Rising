extends SceneTree

var failures := 0

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

	SyndicateState.reset_state()
	_expect(SyndicateState.rooms.size() == 8, "Eight criminal buildings exist")
	_expect(SyndicateState.crew.size() == 4, "Four starter crew members exist")
	_expect(SyndicateState.pending_cutscene == "prologue", "New campaign starts with the prologue")

	SyndicateState.credits = 5000
	var repair := SyndicateState.repair_room("chop_shop")
	_expect(bool(repair.get("ok", false)), "Damaged building can enter the rebuild queue")
	var chop_shop := SyndicateState.get_room("chop_shop")
	chop_shop["repaired"] = true
	chop_shop["repair_end"] = 0
	var upgrade := SyndicateState.upgrade_room("chop_shop")
	_expect(bool(upgrade.get("ok", false)), "Rebuilt building can be upgraded")
	_expect(int(chop_shop.get("level", 1)) == 2, "Upgrade raises building level")

	SyndicateState.next_job_at = 0
	SyndicateState.tick()
	_expect(not SyndicateState.jobs.is_empty(), "Score generation produces a criminal job")
	if not SyndicateState.jobs.is_empty():
		var first_job := SyndicateState.jobs[0]
		_expect(bool(first_job.get("story", false)), "Opening score is the chapter story job")
		var launch := SyndicateState.begin_job(String(first_job.get("id", "")), ["crew_1"])
		_expect(bool(launch.get("ok", false)), "Available crew can launch a score")
		SyndicateState.finish_job(true, {"crew_1": 80})
		_expect(SyndicateState.story_chapter == 2, "Winning chapter one advances the story")

	var scene_paths := [
		"res://scenes/SyndicateCity.tscn",
		"res://scenes/SyndicateScores.tscn",
		"res://scenes/SyndicateRaid.tscn",
		"res://scenes/SyndicateCutscene.tscn"
	]
	for path in scene_paths:
		_expect(load(path) is PackedScene, "Scene parses: %s" % String(path).get_file())

	var art_paths := [
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
	for path in art_paths:
		_expect(load(path) is Texture2D, "Artwork imports: %s" % String(path).get_file())

	SyndicateState.intro_seen = true
	SyndicateState.pending_cutscene = ""
	var city_scene := load("res://scenes/SyndicateCity.tscn") as PackedScene
	if city_scene != null:
		var city := city_scene.instantiate()
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
