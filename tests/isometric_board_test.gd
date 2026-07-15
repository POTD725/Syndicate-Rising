extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("[SYNDICATE RISING] Verifying native isometric board and DermaPack integration...")
	_expect(load("res://scripts/syndicate_isometric_assets.gd") is Script, "Isometric vector asset generator parses")
	_expect(load("res://scripts/syndicate_skinned_city.gd") is Script, "Isometric city controller parses")
	_expect(load("res://scripts/syndicate_animated_isometric_city.gd") is Script, "Animated isometric city controller parses")

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
	_expect(city_scene != null, "Isometric city scene loads")
	if city_scene != null:
		var city: Node = city_scene.instantiate()
		root.add_child(city)
		await process_frame
		await process_frame
		var board: Texture2D = city.get("board_texture") as Texture2D
		var pack: Texture2D = city.get("dermapack_texture") as Texture2D
		_expect(board != null, "Native isometric board generates")
		_expect(pack != null, "Generated DermaPack icon loads")
		if board != null:
			_expect(board.get_size().x >= 900.0 and board.get_size().y >= 1200.0, "Isometric board retains high-detail mobile resolution")
		if pack != null:
			_expect(pack.get_size().x >= 120.0 and pack.get_size().y >= 120.0, "DermaPack wearable icon retains readable resolution")
		var hotspots: Dictionary = city.get("room_rects") as Dictionary
		_expect(hotspots.size() == 12, "All twelve room systems have isometric hotspots")
		city.call("_action", "dermapack")
		_expect(String(city.get("panel_mode")) == "dermapack", "DermaPack navigation opens wearable storage")
		city.call("_action", "heroes")
		_expect(String(city.get("panel_mode")) == "heroes", "Heroes navigation opens crew roster")
		city.call("_action", "store")
		_expect(String(city.get("selected_room")) == "black_market", "Store navigation opens the Black Market")
		city.call("_action", "rotate")
		_expect(int(city.get("rotation_quadrant")) == 1, "Isometric board retains quarter-turn rotation")
		city.call("_action", "zoom_in")
		_expect(float(city.get("target_camera_zoom")) > 0.88, "Isometric board retains camera zoom")
		city.queue_free()

	if failures == 0:
		print("SUCCESS: Native isometric board and DermaPack verification passed.")
	else:
		push_error("FAILED: %d isometric integration test(s) failed." % failures)
	quit(failures)

func _expect(condition: bool, label: String) -> void:
	if condition:
		print("  PASS: %s" % label)
	else:
		failures += 1
		push_error("  FAIL: %s" % label)
