extends SceneTree

var failures: int = 0
const ART: Script = preload("res://scripts/syndicate_full_art.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[SYNDICATE RISING] Verifying complete isometric graphics...")
	_expect(load("res://scripts/syndicate_full_art.gd") is Script, "Full art library parses")
	_expect(load("res://scripts/syndicate_full_city.gd") is Script, "Full city controller parses")
	_expect(load("res://scripts/syndicate_full_operations.gd") is Script, "Full Operations controller parses")
	_expect(load("res://scripts/syndicate_full_cutscene.gd") is Script, "Full cutscene controller parses")
	_expect(load("res://scripts/syndicate_full_attack_cutscene.gd") is Script, "Full attack controller parses")

	_check_texture(ART.board_texture(), Vector2(1024.0, 1536.0), "Lunar city board")
	_check_texture(ART.npc_atlas(), Vector2(1024.0, 256.0), "Animated NPC atlas")
	_check_texture(ART.systems_atlas(), Vector2(1024.0, 768.0), "Resources, defenses, and threats atlas")
	_check_texture(ART.ui_atlas(), Vector2(512.0, 256.0), "Mobile UI atlas")
	_check_texture(ART.dermapack_texture(), Vector2(256.0, 256.0), "DermaPack wearable icon")
	for key: String in ["prologue", "ghost_key", "war_room", "finale"]:
		_check_texture(ART.cutscene_texture(key), Vector2(720.0, 1280.0), "Cutscene art: %s" % key)
	for key: String in ["survey", "patrol", "riot", "cyber"]:
		_check_texture(ART.attack_texture(key), Vector2(720.0, 720.0), "Attack art: %s" % key)

	var state: Node = root.get_node_or_null("SyndicateState")
	_expect(state != null, "Campaign state autoload exists")
	if state == null:
		quit(1)
		return
	state.call("reset_state")
	state.set("intro_seen", true)
	state.set("pending_cutscene", "")
	state.set("pending_attack_cutscene", "")
	state.set("active_threat", {})

	var city_scene: PackedScene = load("res://scenes/SyndicateCity.tscn") as PackedScene
	_expect(city_scene != null, "Full-art city scene loads")
	if city_scene != null:
		var city: Node = city_scene.instantiate()
		root.add_child(city)
		await process_frame
		await process_frame
		var jobs: Array = city.get("worker_jobs") as Array
		_expect(jobs.size() >= 32, "At least 32 NPCs have assigned jobs")
		var departments: Dictionary = {}
		var job_names: Dictionary = {}
		for job_value: Variant in jobs:
			var job: Dictionary = job_value as Dictionary
			departments[String(job.get("department", ""))] = true
			job_names[String(job.get("job", ""))] = true
			_expect(job.has("a") and job.has("b") and job.has("speed"), "NPC route is complete")
		_expect(departments.size() >= 8, "NPC workforce covers eight departments")
		_expect(job_names.size() >= 28, "NPC workforce performs distinct visible jobs")
		var hotspots: Dictionary = city.get("room_rects") as Dictionary
		_expect(hotspots.size() == 12, "All twelve buildings have interactive hotspots")
		city.call("_action", "dermapack")
		_expect(String(city.get("panel_mode")) == "dermapack", "DermaPack opens from mobile navigation")
		city.call("_action", "heroes")
		_expect(String(city.get("panel_mode")) == "heroes", "Heroes opens from mobile navigation")
		city.call("_action", "rotate")
		_expect(int(city.get("rotation_quadrant")) == 1, "Quarter-turn rotation remains active")
		city.call("_action", "zoom_in")
		_expect(float(city.get("target_camera_zoom")) > 1.0, "Camera zoom remains active")
		city.queue_free()

	for scene_path: String in [
		"res://scenes/SyndicateOperations.tscn",
		"res://scenes/SyndicateCutscene.tscn",
		"res://scenes/SyndicateAttackCutscene.tscn",
		"res://scenes/SyndicateRaid.tscn",
		"res://scenes/SyndicateScores.tscn"
	]:
		_expect(load(scene_path) is PackedScene, "Scene parses with complete art: %s" % scene_path.get_file())

	if failures == 0:
		print("SUCCESS: Complete isometric graphics verification passed.")
	else:
		push_error("FAILED: %d complete-art verification check(s) failed." % failures)
	quit(failures)

func _check_texture(texture: Texture2D, expected: Vector2, label: String) -> void:
	_expect(texture != null, "%s exists" % label)
	if texture != null:
		var size: Vector2 = texture.get_size()
		_expect(size.x >= expected.x and size.y >= expected.y, "%s has game-ready resolution" % label)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
