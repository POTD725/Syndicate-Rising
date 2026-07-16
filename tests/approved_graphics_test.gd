extends SceneTree

const ART: Script = preload("res://scripts/syndicate_approved_art.gd")
const EXPECTED_SHA: String = "53ecc228635c151d0511be9f81b7eb84099541d21984ccadcc5f796af19b7da2"
var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[SYNDICATE RISING] Double-checking approved graphics and dashboard integration...")
	_expect(ART.approved_graphics_active(), "Checksum-locked approved graphics are installed")
	var receipt: Dictionary = ART.graphics_receipt()
	_expect(String(receipt.get("status", "")) == "approved", "Graphics receipt marks the pack approved")
	_expect(String(receipt.get("source_sha256", "")) == EXPECTED_SHA, "Approved dashboard source checksum matches")
	_expect((receipt.get("source_size", []) as Array) == [1536, 1024], "Approved source dimensions match")

	_check_texture(ART.board_texture(), Vector2(1024.0, 1536.0), "Portrait lunar city board")
	_check_texture(ART.npc_atlas(), Vector2(1024.0, 256.0), "Animated NPC atlas")
	_check_texture(ART.systems_atlas(), Vector2(1024.0, 768.0), "Resources, defenses, threats, and missions atlas")
	_check_texture(ART.ui_atlas(), Vector2(512.0, 256.0), "Approved mobile dashboard atlas")
	_check_texture(ART.dermapack_texture(), Vector2(256.0, 256.0), "Wearable DermaPack graphic")
	for key: String in ["prologue", "ghost_key", "war_room", "finale"]:
		_check_texture(ART.cutscene_texture(key), Vector2(720.0, 1280.0), "Approved cutscene: %s" % key)
	for key: String in ["survey", "patrol", "riot", "cyber"]:
		_check_texture(ART.attack_texture(key), Vector2(720.0, 720.0), "Approved attack: %s" % key)

	var state: Node = root.get_node_or_null("SyndicateState")
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
	_expect(city.has_method("approved_graphics_active") and bool(city.call("approved_graphics_active")), "City uses approved graphics")
	_expect(int(city.call("npc_job_count")) >= 32, "All 32 animated workers remain assigned")
	_expect(bool(city.call("every_npc_has_job")), "Every animated NPC has a job and route")
	_expect((city.get("room_rects") as Dictionary).size() == 12, "All twelve approved buildings are interactive")
	city.call("_action", "dermapack")
	_expect(String(city.get("panel_mode")) == "dermapack", "DermaPack dashboard button works")
	city.call("_action", "rotate")
	_expect(int(city.get("rotation_quadrant")) == 1, "Approved city still rotates in quarter turns")
	city.call("_action", "zoom_in")
	_expect(float(city.get("target_camera_zoom")) > 1.0, "Approved city camera still zooms")
	city.queue_free()
	await process_frame

	var operations: Node = (load("res://scenes/SyndicateOperations.tscn") as PackedScene).instantiate()
	root.add_child(operations)
	await process_frame
	_expect(operations.has_method("approved_graphics_active") and bool(operations.call("approved_graphics_active")), "Operations uses approved resources and defense graphics")
	operations.queue_free()
	await process_frame

	state.set("pending_cutscene", "prologue")
	var cutscene: Node = (load("res://scenes/SyndicateCutscene.tscn") as PackedScene).instantiate()
	root.add_child(cutscene)
	await process_frame
	_expect(cutscene.has_method("approved_graphics_active") and bool(cutscene.call("approved_graphics_active")), "Interactive beginning uses approved artwork")
	cutscene.queue_free()
	await process_frame

	state.set("pending_cutscene", "")
	state.call("force_threat", "patrol")
	var attack: Node = (load("res://scenes/SyndicateAttackCutscene.tscn") as PackedScene).instantiate()
	root.add_child(attack)
	await process_frame
	_expect(attack.has_method("approved_graphics_active") and bool(attack.call("approved_graphics_active")), "Peacekeeper attacks use approved artwork")
	attack.queue_free()

	if failures == 0:
		print("SUCCESS: Approved graphics and dashboard passed both integration checks.")
	else:
		push_error("FAILED: %d approved-graphics check(s) failed." % failures)
	quit(failures)

func _check_texture(texture: Texture2D, expected: Vector2, label: String) -> void:
	_expect(texture != null, "%s exists" % label)
	if texture != null:
		_expect(texture.get_size() == expected, "%s has exact resolution" % label)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
