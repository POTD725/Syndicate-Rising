extends SceneTree

var failures: int = 0
var state: Node
var chat: Node
var skins: Node

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[SYNDICATE RISING] Running gameplay and exact displayed-art tests...")
	var script_paths: Array[String] = [
		"res://scripts/syndicate_state.gd",
		"res://scripts/syndicate_lunar_state.gd",
		"res://scripts/syndicate_operations_state.gd",
		"res://scripts/syndicate_story_operations_state.gd",
		"res://scripts/syndicate_skin_state.gd",
		"res://scripts/syndicate_lunar_camera_city.gd",
		"res://scripts/syndicate_feature_city.gd",
		"res://scripts/syndicate_skinned_city.gd",
		"res://scripts/syndicate_operations.gd",
		"res://scripts/syndicate_skinned_operations.gd",
		"res://scripts/syndicate_chat_state.gd",
		"res://scripts/syndicate_chat.gd",
		"res://scripts/syndicate_skinned_chat.gd",
		"res://scripts/syndicate_interactive_cutscene.gd",
		"res://scripts/syndicate_skinned_cutscene.gd",
		"res://scripts/syndicate_attack_cutscene.gd",
		"res://scripts/syndicate_skinned_attack_cutscene.gd",
		"res://scripts/syndicate_audio.gd",
		"res://scripts/syndicate_scores.gd",
		"res://scripts/syndicate_skinned_scores.gd",
		"res://scripts/syndicate_raid.gd",
		"res://scripts/syndicate_skinned_raid.gd"
	]
	for path: String in script_paths:
		_expect(load(path) is Script, "Script loads: %s" % path.get_file())

	state = root.get_node_or_null("SyndicateState")
	chat = root.get_node_or_null("SyndicateChat")
	skins = root.get_node_or_null("SyndicateSkins")
	_expect(state != null, "SyndicateState autoload exists")
	_expect(chat != null, "SyndicateChat autoload exists")
	_expect(skins != null, "SyndicateSkins autoload exists")
	if state == null or chat == null or skins == null:
		quit(1)
		return

	_expect(FileAccess.file_exists("res://assets/concept_atlases/board.part0.b64"), "First half of displayed concept board is packaged")
	_expect(FileAccess.file_exists("res://assets/concept_atlases/board.part1.b64"), "Second half of displayed concept board is packaged")
	var skin_names: Array = skins.get("SKIN_NAMES") as Array
	_expect(skin_names.size() == 5, "Five displayed-art option columns exist")
	var first_base_region: Rect2 = Rect2()
	var board_bounds: Rect2 = Rect2()
	for skin_index: int in range(5):
		skins.call("set_skin", skin_index)
		var atlas_texture: Texture2D = skins.call("atlas") as Texture2D
		_expect(atlas_texture != null, "Displayed board decodes for option %d" % (skin_index + 1))
		if atlas_texture != null:
			var atlas_size: Vector2 = atlas_texture.get_size()
			_expect(atlas_size.x >= 630.0 and atlas_size.y >= 420.0, "Displayed board keeps usable image resolution")
			board_bounds = Rect2(Vector2.ZERO, atlas_size)
		var base_region: Rect2 = skins.call("base_region") as Rect2
		_expect(_valid_region(base_region, board_bounds), "Moon-base option %d maps to the shown artwork" % (skin_index + 1))
		_expect(_valid_region(skins.call("ui_frame_region") as Rect2, board_bounds), "UI-frame option %d maps to the shown artwork" % (skin_index + 1))
		_expect(_valid_region(skins.call("button_region") as Rect2, board_bounds), "Button option %d maps to the shown artwork" % (skin_index + 1))
		_expect(_valid_region(skins.call("region", "resource_alloy") as Rect2, board_bounds), "Alloy option %d maps to the shown artwork" % (skin_index + 1))
		_expect(_valid_region(skins.call("region", "resource_helium") as Rect2, board_bounds), "Helium-3 option %d maps to the shown artwork" % (skin_index + 1))
		_expect(_valid_region(skins.call("region", "resource_cores") as Rect2, board_bounds), "Data Core option %d maps to the shown artwork" % (skin_index + 1))
		if skin_index == 0:
			first_base_region = base_region
		elif skin_index == 1:
			_expect(base_region.position != first_base_region.position, "ART button changes to a different shown moon base")
		_expect(not String(skins.call("skin_name")).is_empty(), "Displayed option %d has a name" % (skin_index + 1))

	skins.call("set_skin", 0)
	var displayed_items: Array[String] = [
		"room_black_research", "room_weapons_workshop", "room_signal_den", "room_chop_shop", "room_bunks",
		"threat_patrol", "threat_riot", "threat_survey", "threat_cyber",
		"defense_jammer", "defense_sentry", "defense_blast_doors", "defense_escape_tunnels",
		"mission_hidden", "mission_law_hack", "mission_syndicate_cipher", "mission_rescue",
		"crew_brawler", "crew_techie", "crew_hacker", "crew_gunner", "crew_smuggler"
	]
	for item_id: String in displayed_items:
		_expect(_valid_region(skins.call("region", item_id) as Rect2, board_bounds), "Actual displayed crop resolves: %s" % item_id)
	for cutscene_index: int in range(5):
		_expect(_valid_region(skins.call("cutscene_region", cutscene_index) as Rect2, board_bounds), "Displayed cutscene background %d resolves" % (cutscene_index + 1))

	state.call("reset_state")
	var rooms_value: Variant = state.get("rooms")
	var crew_value: Variant = state.get("crew")
	_expect(rooms_value is Array and (rooms_value as Array).size() == 12, "Twelve connected criminal hideout rooms exist")
	_expect(crew_value is Array and (crew_value as Array).size() == 4, "Four starter crew members exist")
	_expect(String(state.get("pending_cutscene")) == "prologue", "New campaign starts with the interactive prologue")
	_expect((state.get("harvest_sites") as Array).size() == 3, "Three harvesting resource sites exist")
	_expect(int(state.get("lunar_alloy")) > 0, "Lunar Alloy economy starts")
	_expect(int(state.get("helium3")) > 0, "Helium-3 economy starts")
	_expect(int(state.get("data_cores")) > 0, "Authority Data Core economy starts")
	_expect((state.get("defenses") as Dictionary).size() == 4, "Four hideout defense systems exist")

	var prologue_result: Dictionary = state.call("apply_prologue_choice", "salvage") as Dictionary
	_expect(bool(prologue_result.get("ok", false)), "Interactive prologue choice applies")
	_expect(String(state.get("prologue_choice")) == "salvage", "Prologue choice persists in state")
	_expect(int(state.get("lunar_alloy")) >= 50, "Salvage origin grants Lunar Alloy")

	state.set("credits", 5000)
	state.set("intel", 100)
	state.set("contraband", 100)
	state.set("lunar_alloy", 500)
	state.set("helium3", 500)
	state.set("data_cores", 500)
	var harvest_result: Dictionary = state.call("start_harvest", "alloy") as Dictionary
	_expect(bool(harvest_result.get("ok", false)), "Lunar Alloy harvest can launch")
	var alloy_site: Dictionary = state.call("get_harvest_site", "alloy") as Dictionary
	_expect(int(alloy_site.get("finish_at", 0)) > 0, "Harvesting creates a timer")

	var old_jammer: int = int((state.get("defenses") as Dictionary).get("jammer", 0))
	var defense_result: Dictionary = state.call("upgrade_defense", "jammer") as Dictionary
	_expect(bool(defense_result.get("ok", false)), "Signal Jammer can be upgraded")
	_expect(int((state.get("defenses") as Dictionary).get("jammer", 0)) == old_jammer + 1, "Defense upgrade raises its level")

	state.call("force_threat", "survey")
	_expect(not (state.get("active_threat") as Dictionary).is_empty(), "Take Back threat can be generated")
	_expect(String(state.get("pending_attack_cutscene")) == "survey", "Threat queues its attack cutscene")
	(state.get("defenses") as Dictionary)["jammer"] = 10
	(state.get("defenses") as Dictionary)["escape_tunnels"] = 10
	var threat_result: Dictionary = state.call("respond_to_threat", "hide") as Dictionary
	_expect(bool(threat_result.get("ok", false)), "Hideout defenses can defeat a Survey Drone sweep")

	state.call("force_threat", "patrol")
	state.call("_fail_threat", "Test capture.")
	_expect((state.get("captured_crew_ids") as Array).size() == 1, "Failed Patrol Deputy response captures a crew member")
	var rescue_start: Dictionary = state.call("start_side_mission", "rescue") as Dictionary
	_expect(bool(rescue_start.get("ok", false)), "Captured crew unlocks a rescue puzzle")
	var rescue_sequence: Array = (state.get("hack_sequence") as Array).duplicate()
	for node_value: Variant in rescue_sequence:
		state.call("submit_hack_node", int(node_value))
	_expect((state.get("captured_crew_ids") as Array).is_empty(), "Completing the rescue puzzle releases captured crew")

	var hidden_start: Dictionary = state.call("start_side_mission", "hidden") as Dictionary
	_expect(bool(hidden_start.get("ok", false)), "Hidden-object theft side mission starts")
	for hidden_index: int in range(5):
		state.call("submit_hidden_object", hidden_index)
	_expect(String(state.get("side_mission_mode")) == "", "Finding five valuables completes hidden-object theft")

	var law_start: Dictionary = state.call("start_side_mission", "law_hack") as Dictionary
	_expect(bool(law_start.get("ok", false)), "Law-enforcement hacking puzzle starts")
	var law_sequence: Array = (state.get("hack_sequence") as Array).duplicate()
	for node_value: Variant in law_sequence:
		state.call("submit_hack_node", int(node_value))
	_expect(String(state.get("side_mission_mode")) == "", "Correct relay order completes the law-network hack")

	var chat_result: Dictionary = chat.call("post_message", "galaxy", "Smoke test transmission") as Dictionary
	_expect(bool(chat_result.get("ok", false)), "Galaxy chat accepts a message")
	var private_result: Dictionary = chat.call("post_message", "private", "Meet at the tunnel.", "Nyx Raze") as Dictionary
	_expect(bool(private_result.get("ok", false)), "Private chat accepts a recipient and message")
	_expect((chat.call("get_messages", "alliance") as Array).size() > 0, "Alliance chat has saved channel history")
	_expect(not bool(chat.get("backend_connected")), "Chat honestly reports local prototype transport")

	var scene_paths: Array[String] = [
		"res://scenes/SyndicateCity.tscn",
		"res://scenes/SyndicateScores.tscn",
		"res://scenes/SyndicateRaid.tscn",
		"res://scenes/SyndicateCutscene.tscn",
		"res://scenes/SyndicateAttackCutscene.tscn",
		"res://scenes/SyndicateOperations.tscn",
		"res://scenes/SyndicateChat.tscn"
	]
	for path: String in scene_paths:
		_expect(load(path) is PackedScene, "Exact-art scene parses: %s" % path.get_file())

	state.set("intro_seen", true)
	state.set("pending_cutscene", "")
	state.set("pending_attack_cutscene", "")
	state.set("active_threat", {})
	var city_scene: PackedScene = load("res://scenes/SyndicateCity.tscn") as PackedScene
	if city_scene != null:
		var city: Node = city_scene.instantiate()
		root.add_child(city)
		await process_frame
		await process_frame
		_expect(city is Node2D, "Lunar hideout with displayed artwork instantiates")
		_expect(int(city.get("rotation_quadrant")) == 0, "Camera starts upright")
		var initial_skin: int = int(skins.get("selected_skin"))
		city.call("_action", "skin")
		_expect(int(skins.get("selected_skin")) != initial_skin, "ART button changes the displayed concept option")
		city.call("_action", "rotate")
		_expect(int(city.get("rotation_quadrant")) == 1, "Rotate button advances the view by 90 degrees")
		city.call("_action", "zoom_in")
		_expect(float(city.get("target_camera_zoom")) > 0.88, "Zoom controls change the camera scale")
		city.call("_action", "center")
		_expect((city.get("target_camera_offset") as Vector2).is_equal_approx(Vector2.ZERO), "Center button resets camera pan")
		city.queue_free()

	var operations_scene: PackedScene = load("res://scenes/SyndicateOperations.tscn") as PackedScene
	if operations_scene != null:
		var operations: Node = operations_scene.instantiate()
		root.add_child(operations)
		await process_frame
		_expect(operations is Node2D, "Operations with displayed resources and defenses instantiates")
		operations.queue_free()

	var chat_scene: PackedScene = load("res://scenes/SyndicateChat.tscn") as PackedScene
	if chat_scene != null:
		var chat_screen: Node = chat_scene.instantiate()
		root.add_child(chat_screen)
		await process_frame
		_expect(chat_screen is Control, "Communications with displayed UI frame instantiates")
		chat_screen.queue_free()

	if failures == 0:
		print("SUCCESS: Syndicate Rising uses the exact displayed concept-board artwork.")
	else:
		push_error("FAILED: %d Syndicate Rising exact-art test(s) failed." % failures)
	quit(failures)

func _valid_region(region_rect: Rect2, board_bounds: Rect2) -> bool:
	return region_rect.size.x > 4.0 and region_rect.size.y > 4.0 and board_bounds.encloses(region_rect)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
