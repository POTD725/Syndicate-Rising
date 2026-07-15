extends SceneTree

var failures: int = 0
var state: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[SYNDICATE RISING] Verifying animated NPC jobs and isometric cinematics...")
	_expect(load("res://scripts/syndicate_animated_isometric_city.gd") is Script, "Animated isometric city script parses")
	_expect(load("res://scripts/syndicate_isometric_cutscene.gd") is Script, "Isometric story cinematic script parses")
	_expect(load("res://scripts/syndicate_isometric_attack_cutscene.gd") is Script, "Isometric attack cinematic script parses")

	state = root.get_node_or_null("SyndicateState")
	_expect(state != null, "Campaign state exists")
	if state == null:
		quit(1)
		return

	state.call("reset_state")
	state.set("intro_seen", true)
	state.set("pending_cutscene", "")
	state.set("pending_attack_cutscene", "")
	state.set("active_threat", {})

	var city_scene: PackedScene = load("res://scenes/SyndicateCity.tscn") as PackedScene
	var city: Node = city_scene.instantiate()
	root.add_child(city)
	await process_frame
	await process_frame
	_expect(city.has_method("npc_job_count"), "City exposes NPC job verification")
	_expect(int(city.call("npc_job_count")) >= 30, "At least thirty visible NPCs have assignments")
	_expect(bool(city.call("every_npc_has_job")), "Every NPC has a job description and movement route")
	var jobs: Array = city.get("npc_jobs") as Array
	var room_coverage: Dictionary = {}
	var task_types: Dictionary = {}
	for job_value: Variant in jobs:
		var job: Dictionary = job_value as Dictionary
		room_coverage[String(job.get("room", ""))] = true
		task_types[String(job.get("tool", ""))] = true
	_expect(room_coverage.size() >= 10, "NPC work covers at least ten hideout departments")
	_expect(task_types.size() >= 10, "NPCs perform at least ten distinct animated job types")
	city.queue_free()
	await process_frame

	state.set("pending_cutscene", "prologue")
	var story_scene: PackedScene = load("res://scenes/SyndicateCutscene.tscn") as PackedScene
	var story: Node = story_scene.instantiate()
	root.add_child(story)
	await process_frame
	await process_frame
	_expect(story.has_method("uses_isometric_board"), "Story cinematic exposes graphics-match verification")
	_expect(bool(story.call("uses_isometric_board")), "Interactive beginning uses the same isometric board artwork")
	story.queue_free()
	await process_frame

	state.set("pending_cutscene", "")
	state.call("force_threat", "survey")
	var attack_scene: PackedScene = load("res://scenes/SyndicateAttackCutscene.tscn") as PackedScene
	var attack: Node = attack_scene.instantiate()
	root.add_child(attack)
	await process_frame
	await process_frame
	_expect(attack.has_method("uses_isometric_board"), "Attack cinematic exposes graphics-match verification")
	_expect(bool(attack.call("uses_isometric_board")), "Peacekeeper attack scenes use the same isometric board artwork")
	attack.queue_free()

	if failures == 0:
		print("SUCCESS: Animated NPC jobs and matching cinematics passed.")
	else:
		push_error("FAILED: %d animation or cinematic test(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
